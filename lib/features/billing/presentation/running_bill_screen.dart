import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/localization/app_locale.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/enums.dart';
import '../../../shared_widgets/fab_mic.dart';
import '../../../shared_widgets/line_item_row.dart';
import '../../voice/slot_parser/slot_parser.dart';
import '../application/billing_controller.dart';
import '../application/draft_line_item.dart';
import 'calculate_total_screen.dart';
import 'manual_entry_screen.dart';

/// Screen B2/B3 merged — the bill-in-progress screen: the running line-item
/// list (FR-3.2.7) with voice capture built directly into it, rather than
/// voice living on a separate screen that hands off to this one after every
/// single item.
///
/// That hand-off used to mean a full screen transition for *every* item —
/// fine for one or two, painful for the 10-30+ item bills real retailers
/// actually ring up (reported directly: "if user have list of 10, 20, 30
/// items... very difficult to record all item and again and again
/// navigation to check screen"). Now a successful capture just appends to
/// [BillingState.items] in place and the mic re-arms immediately — no
/// navigation at all between items. A low-confidence capture still opens
/// [ManualEntryScreen] for a one-tap confirm (SRS §12.5), but as a screen
/// *pushed* on top (not a replacement), so popping back lands right back
/// here with the list already showing the new item, not a freshly rebuilt
/// screen.
///
/// No grand total is shown here on purpose — only Jama Karain (B5) reveals
/// it, per the explicit-calculation principle.
class RunningBillScreen extends ConsumerStatefulWidget {
  const RunningBillScreen({super.key});

  @override
  ConsumerState<RunningBillScreen> createState() => _RunningBillScreenState();
}

class _RunningBillScreenState extends ConsumerState<RunningBillScreen> {
  final _speech = stt.SpeechToText();
  bool _listening = false;
  bool _speechAvailable = false;
  String _transcript = '';
  String? _errorMessage;
  double _asrConfidence = -1;

  static const _listenTimeout = Duration(seconds: 15);
  Timer? _listenTimeoutTimer;

  /// Press-and-hold setup is async, so a very quick press-and-release can
  /// finish after the finger's already up; checked right before `.listen()`
  /// so that race never starts listening into an unheld button. Same
  /// pattern as [ShopNameScreen] (A4), which does its own dictation.
  bool _pressed = false;

  /// Pre-warmed in [initState], not lazily on first press — engine init
  /// alone measured multiple seconds on real hardware; see the identical
  /// pattern (and full reasoning) in [ShopNameScreen._prepareSpeechEngine].
  late Future<String?> _speechSetup;

  /// Guards against overlapping `_start` calls from rapid repeated taps.
  int _startToken = 0;

  @override
  void initState() {
    super.initState();
    _speechSetup = _prepareSpeechEngine();
  }

  @override
  void dispose() {
    _listenTimeoutTimer?.cancel();
    _speech.stop();
    super.dispose();
  }

  Future<String?> _prepareSpeechEngine() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = AppLocalizations.of(context).noisyPrompt;
          _listening = false;
        });
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _onCaptureFinished();
        }
      },
    );
    if (!_speechAvailable) return null;

    final locale = ref.read(localeProvider);
    final preferredLocaleId = switch (locale) {
      AppLocale.urdu => 'ur_PK',
      AppLocale.romanUrdu || AppLocale.english => 'en_US',
    };
    final languagePrefix = switch (locale) {
      AppLocale.urdu => 'ur',
      AppLocale.romanUrdu || AppLocale.english => 'en',
    };

    // locales() is itself sometimes unreliable (empty even when recognition
    // works), and real phones report regional variants rather than the
    // literal en_US/ur_PK, so matching is language-family-based.
    final available = await _speech.locales();
    stt.LocaleName? matched;
    for (final l in available) {
      if (l.localeId == preferredLocaleId) {
        matched = l;
        break;
      }
    }
    if (matched == null) {
      for (final l in available) {
        if (l.localeId.toLowerCase().startsWith(languagePrefix)) {
          matched = l;
          break;
        }
      }
    }
    if (available.isNotEmpty && matched == null) return null;
    return matched?.localeId ?? preferredLocaleId;
  }

  void _onHoldStart() {
    _pressed = true;
    _start(++_startToken);
  }

  void _onHoldEnd() {
    _pressed = false;
    if (_listening) _speech.stop();
  }

  Future<void> _start(int token) async {
    setState(() => _errorMessage = null);
    final l10n = AppLocalizations.of(context);

    final status = await Permission.microphone.request();
    if (token != _startToken) return;
    if (!status.isGranted) {
      setState(() => _errorMessage = l10n.micPermissionDenied);
      return;
    }

    final speechLocaleId = await _speechSetup;
    if (token != _startToken) return;
    if (speechLocaleId == null) {
      if (mounted) setState(() => _errorMessage = l10n.micUnavailable);
      return;
    }

    if (!_pressed) return;

    setState(() {
      _listening = true;
      _transcript = '';
      _asrConfidence = -1;
    });
    _listenTimeoutTimer?.cancel();
    _listenTimeoutTimer = Timer(_listenTimeout, () {
      _speech.stop();
      _onCaptureFinished();
    });
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        localeId: speechLocaleId,
      ),
      onResult: (result) => setState(() {
        _transcript = result.recognizedWords;
        _asrConfidence = result.confidence;
      }),
    );
  }

  Future<void> _onCaptureFinished() async {
    if (!mounted || !_listening) return;
    _listenTimeoutTimer?.cancel();
    setState(() => _listening = false);

    final l10n = AppLocalizations.of(context);
    if (_transcript.trim().isEmpty) {
      setState(() => _errorMessage = l10n.noisyPrompt);
      return;
    }

    final parsed = SlotParser.withAsrConfidence(SlotParser.parse(_transcript), _asrConfidence);

    if (!parsed.needsConfirmation) {
      // High confidence across every field — auto-fills per SRS §12.2
      // layer 5, no tap required, and no navigation: it just lands in the
      // list already on screen and the mic is immediately ready again.
      ref.read(billingControllerProvider.notifier).addItem(DraftLineItem(
            itemNameRaw: parsed.itemNameRaw,
            inputMethod: InputMethod.voice,
            quantity: parsed.quantity,
            unit: parsed.unit,
            pricePerUnit: parsed.pricePerUnit,
          ));
      setState(() => _transcript = '');
      return;
    }

    // Low confidence on at least one field — the confidence gate: hand off
    // to the manual entry screen, pre-filled, for a one-tap confirm/correct
    // (SRS §12.5). Pushed, not replaced, so popping back returns to this
    // same list instead of rebuilding it from scratch.
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ManualEntryScreen(prefill: parsed)),
    );
    if (mounted) setState(() => _transcript = '');
  }

  Future<void> _openManualEntry() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ManualEntryScreen()),
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

  String _formatQuantity(double quantity) =>
      quantity == quantity.roundToDouble() ? quantity.toStringAsFixed(0) : quantity.toString();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;
    final state = ref.watch(billingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newBillTitle),
        bottom: state.customer != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(18),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${state.customer!.name} • ${l10n.khataTag}',
                    style: type.caption.copyWith(
                      color: colors.appBarForeground.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: state.items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_transcript.isNotEmpty) ...[
                              Text(
                                '"$_transcript"',
                                style: type.bodyEmphasis.copyWith(color: colors.accent, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                            ],
                            Text(
                              l10n.tapMicOrManual,
                              style: type.caption.copyWith(color: colors.textSoft),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      children: [
                        for (final item in state.items)
                          LineItemRow(
                            name: item.itemNameRaw,
                            meta: '${_formatQuantity(item.quantity)} ${_unitLabel(l10n, item.unit)} × '
                                '${item.pricePerUnit.format()}',
                            amount: item.lineTotal,
                            onDelete: () =>
                                ref.read(billingControllerProvider.notifier).removeItem(item.localId),
                          ),
                        if (_transcript.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            '"$_transcript"',
                            style: type.bodyEmphasis.copyWith(color: colors.accent, fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 14),
                      ],
                    ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(_errorMessage!, style: type.caption.copyWith(color: colors.alert)),
              ),
            const SizedBox(height: 4),
            // Mic pinned low, thumb-reachable, with the manual-entry and
            // Jama Karain controls stacked just above it rather than the
            // mic sitting mid-screen — real-device feedback specifically
            // asked for this arrangement.
            FabMic(onHoldStart: _onHoldStart, onHoldEnd: _onHoldEnd, listening: _listening),
            const SizedBox(height: 10),
            Text(
              _listening ? l10n.listeningEllipsis : l10n.holdMicToSpeak,
              style: type.eyebrow.copyWith(color: colors.textSoft),
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: _openManualEntry,
                    icon: const Icon(Icons.keyboard),
                    label: Text(l10n.manualLabel),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: state.hasItems
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CalculateTotalScreen()),
                            )
                        : null,
                    child: Text(l10n.calculateTotal),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
