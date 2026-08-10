import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/enums.dart';
import '../../../shared_widgets/bolo_chip.dart';
import '../../../shared_widgets/numeric_keypad.dart';
import '../../voice/slot_parser/parsed_line_item.dart';
import '../application/billing_controller.dart';
import '../application/draft_line_item.dart';

enum _ActiveField { quantity, price }

/// Screen B4 — manual entry with a fraction-aware numeric keypad
/// (FR-3.2.4/3.2.5/3.2.6). Reached two ways: from B1 (first item, no bill
/// screen underneath yet), or pushed on top of the bill-in-progress screen
/// (RunningBillScreen — either the retailer tapped "Manual" there directly,
/// or a voice capture tripped the confidence gate (SRS §12.5) and needs a
/// one-tap confirmation, in which case [prefill] pre-populates the same
/// fields). Whichever field(s) triggered a low-confidence flag get a
/// visible warning border, so voice and manual stay genuinely equal-status:
/// correcting a misheard entry is just editing a normal form, not a
/// separate "fix voice" flow. Always just pops with `true` on success —
/// see [_addToBill] — since only the caller knows whether it needs to
/// create the bill screen or is already showing it underneath.
class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key, this.prefill});

  final ParsedLineItem? prefill;

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  late final _nameController = TextEditingController(text: widget.prefill?.itemNameRaw ?? '');
  late QuantityUnit _unit = widget.prefill?.unit ?? QuantityUnit.piece;

  /// Defaults to a single item rather than blank: most sales are one
  /// packaged thing at a flat price, and requiring a quantity to be typed
  /// for every one of those was the bulk of the "this screen is complex"
  /// complaint.
  late String _quantityText =
      widget.prefill != null ? _prefillNumberText(widget.prefill!.quantity) : '1';
  late String _priceText = _prefillNumberText(widget.prefill?.pricePerUnit.rupees);

  /// The unit chips, quantity field and fraction row start hidden — they
  /// only matter for weighed/counted goods. Anything voice already heard as
  /// non-trivial (a real unit, or a quantity that isn't one) opens expanded
  /// so a confirmation never hides a value the retailer needs to check.
  late bool _showQuantity = widget.prefill != null &&
      (widget.prefill!.unit != QuantityUnit.piece || widget.prefill!.quantity != 1);

  late _ActiveField _activeField = _initialActiveField();

  /// If price is the only field the confidence gate flagged — item, unit,
  /// and quantity were all heard fine — jump straight to it instead of
  /// making the retailer tap through fields that were already correct.
  _ActiveField _initialActiveField() {
    if (_priceOnlyLowConfidence) return _ActiveField.price;
    return _showQuantity ? _ActiveField.quantity : _ActiveField.price;
  }

  bool get _priceOnlyLowConfidence {
    final prefill = widget.prefill;
    if (prefill == null) return false;
    return prefill.priceConfidence < ParsedLineItem.confidenceThreshold &&
        prefill.itemNameConfidence >= ParsedLineItem.confidenceThreshold &&
        prefill.quantityConfidence >= ParsedLineItem.confidenceThreshold;
  }

  static String _prefillNumberText(double? value) {
    if (value == null || value == 0) return '';
    return value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _activeText => _activeField == _ActiveField.quantity ? _quantityText : _priceText;

  void _setActiveText(String value) {
    setState(() {
      if (_activeField == _ActiveField.quantity) {
        _quantityText = value;
      } else {
        _priceText = value;
      }
    });
  }

  void _onDigit(String digit) => _setActiveText(_activeText + digit);

  void _onDecimal() {
    if (_activeText.contains('.')) return;
    _setActiveText(_activeText.isEmpty ? '0.' : '$_activeText.');
  }

  void _onBackspace() {
    if (_activeText.isEmpty) return;
    _setActiveText(_activeText.substring(0, _activeText.length - 1));
  }

  void _setFraction(double value) {
    setState(() {
      _activeField = _ActiveField.quantity;
      _quantityText = value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toString();
    });
  }

  bool get _canAdd {
    final qty = double.tryParse(_quantityText);
    final price = double.tryParse(_priceText);
    return _nameController.text.trim().isNotEmpty && qty != null && qty > 0 && price != null && price >= 0;
  }

  void _addToBill() {
    final qty = double.parse(_quantityText);
    final price = double.parse(_priceText);
    ref.read(billingControllerProvider.notifier).addItem(DraftLineItem(
          itemNameRaw: _nameController.text.trim(),
          inputMethod: InputMethod.manual,
          quantity: qty,
          unit: _unit,
          pricePerUnit: Money.fromRupees(price),
        ));
    // Always just pops with a result — this screen no longer decides where
    // to go next. B1 (no bill screen underneath yet) and the bill-in-
    // progress screen (already underneath, already watching the same
    // billingControllerProvider state) need different follow-ups, and only
    // the caller knows which situation it's in.
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;

    final prefill = widget.prefill;
    final nameLowConfidence =
        prefill != null && prefill.itemNameConfidence < ParsedLineItem.confidenceThreshold;
    final quantityLowConfidence =
        prefill != null && prefill.quantityConfidence < ParsedLineItem.confidenceThreshold;
    final priceLowConfidence =
        prefill != null && prefill.priceConfidence < ParsedLineItem.confidenceThreshold;

    return Scaffold(
      appBar: AppBar(title: Text(prefill != null ? l10n.confirmVoiceEntryTitle : l10n.manualEntryTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (prefill != null && prefill.needsConfirmation) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.alertSoft,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hearing_disabled, color: colors.alert, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _priceOnlyLowConfidence ? l10n.priceNotCaughtBanner : l10n.lowConfidenceBanner,
                          style: type.caption.copyWith(color: colors.alert),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(l10n.itemNameLabel, style: type.eyebrow.copyWith(color: colors.textSoft)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                style: type.bodyEmphasis.copyWith(color: colors.text),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(color: nameLowConfidence ? colors.alert : colors.cardBorder, width: nameLowConfidence ? 2 : 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (!_showQuantity) ...[
                _NumberField(
                  label: l10n.priceLabel,
                  value: _priceText,
                  active: true,
                  lowConfidence: priceLowConfidence,
                  onTap: () => setState(() => _activeField = _ActiveField.price),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _showQuantity = true;
                      _activeField = _ActiveField.quantity;
                    }),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.addQuantityOrWeight),
                  ),
                ),
              ] else ...[
                Text(l10n.unitLabel, style: type.eyebrow.copyWith(color: colors.textSoft)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: QuantityUnit.values.map((u) {
                    return BoloChip(
                      label: _unitLabel(l10n, u),
                      selected: _unit == u,
                      onTap: () => setState(() => _unit = u),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        label: l10n.quantityLabel,
                        value: _quantityText,
                        active: _activeField == _ActiveField.quantity,
                        lowConfidence: quantityLowConfidence,
                        onTap: () => setState(() => _activeField = _ActiveField.quantity),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _NumberField(
                        label: l10n.pricePerUnitLabel(_unitLabel(l10n, _unit)),
                        value: _priceText,
                        active: _activeField == _ActiveField.price,
                        lowConfidence: priceLowConfidence,
                        onTap: () => setState(() => _activeField = _ActiveField.price),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    BoloChip(label: '¼', selected: false, onTap: () => _setFraction(0.25)),
                    const SizedBox(width: 6),
                    BoloChip(label: '½', selected: false, onTap: () => _setFraction(0.5)),
                    const SizedBox(width: 6),
                    BoloChip(label: '¾', selected: false, onTap: () => _setFraction(0.75)),
                    const SizedBox(width: 6),
                    BoloChip(label: '1', selected: false, onTap: () => _setFraction(1)),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              NumericKeypad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                leadingKeyLabel: '.',
                onLeadingKeyTap: _onDecimal,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _canAdd ? _addToBill : null,
                icon: const Icon(Icons.add),
                label: Text(l10n.addToBill),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _unitLabel(AppLocalizations l10n, QuantityUnit unit) => switch (unit) {
        QuantityUnit.piece => l10n.unitPiece,
        QuantityUnit.dozen => l10n.unitDozen,
        QuantityUnit.kg => l10n.unitKg,
        QuantityUnit.gram => l10n.unitGram,
        QuantityUnit.litre => l10n.unitLitre,
        QuantityUnit.meter => l10n.unitMeter,
        QuantityUnit.bottle => l10n.unitBottle,
        QuantityUnit.tablet => l10n.unitTablet,
        QuantityUnit.strip => l10n.unitStrip,
        QuantityUnit.packet => l10n.unitPacket,
        QuantityUnit.box => l10n.unitBox,
        QuantityUnit.custom => l10n.unitCustom,
      };
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
    this.lowConfidence = false,
  });

  final String label;
  final String value;
  final bool active;
  final bool lowConfidence;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;
    final borderColor = lowConfidence ? colors.alert : (active ? colors.accent : colors.cardBorder);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: type.caption.copyWith(color: colors.textSoft, fontSize: 10.5)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: borderColor, width: (active || lowConfidence) ? 2 : 1.5),
            ),
            child: Text(
              value.isEmpty ? '0' : value,
              style: type.screenTitle.copyWith(color: colors.accent, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
