import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/enums.dart';
import '../../../shared_widgets/numeric_keypad.dart';

/// Screen C4 — recording a payment against a customer's khata balance
/// (FR-3.4.7), independent of any new sale. Manual-entry only: this is a
/// single number with no item/unit ambiguity for voice parsing to resolve,
/// so the keypad alone is simpler and just as fast as speaking it.
class RecordPaymentScreen extends ConsumerStatefulWidget {
  const RecordPaymentScreen({super.key, required this.customerId, required this.customerName});

  final String customerId;
  final String customerName;

  @override
  ConsumerState<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  String _amountText = '';
  bool _saving = false;

  void _onDigit(String digit) => setState(() => _amountText += digit);

  void _onDecimal() {
    if (_amountText.contains('.')) return;
    setState(() => _amountText = _amountText.isEmpty ? '0.' : '$_amountText.');
  }

  void _onBackspace() {
    if (_amountText.isEmpty) return;
    setState(() => _amountText = _amountText.substring(0, _amountText.length - 1));
  }

  bool get _canSave {
    final value = double.tryParse(_amountText);
    return value != null && value > 0;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    await ref.read(khataRepositoryProvider).recordPayment(
          customerId: widget.customerId,
          amountReceived: Money.fromRupees(double.parse(_amountText)),
          recordedVia: InputMethod.manual,
        );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recordPaymentTitle)),
      body: SafeArea(
        child: _saving
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.paymentFromLabel(widget.customerName),
                      style: type.eyebrow.copyWith(color: colors.textSoft),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: colors.accent, width: 2),
                      ),
                      child: Text(
                        _amountText.isEmpty ? 'Rs. 0' : 'Rs. $_amountText',
                        style: type.amountHero.copyWith(color: colors.accent, fontSize: 32),
                      ),
                    ),
                    const SizedBox(height: 22),
                    NumericKeypad(
                      onDigit: _onDigit,
                      onBackspace: _onBackspace,
                      leadingKeyLabel: '.',
                      onLeadingKeyTap: _onDecimal,
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _canSave ? _save : null,
                      icon: const Icon(Icons.check),
                      label: Text(l10n.recordPaymentButton),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
