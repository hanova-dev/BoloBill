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
import '../../voice/slot_parser/slot_parser.dart';
import '../application/billing_controller.dart';
import '../application/draft_line_item.dart';
import 'manual_entry_screen.dart';
import 'running_bill_screen.dart';

/// Screen B2 — voice line-item capture (SRS §12 pipeline).
///
/// "VAD" here is push-to-talk plus Android SpeechRecognizer's own built-in
/// endpoint detection (§12.6: "push-to-talk ... is the default interaction,
/// not always-on listening" — bounding the audio window this way is itself
/// the noise-reduction strategy) rather than a separate custom on-device VAD
/// model — §12.9 recommends the built-in recognizer as the v1 baseline
/// specifically *paired with* the grammar/confidence layers, not a bespoke
/// signal-processing stack. Layers 3-5 (domain grammar, slot parser,
/// confidence gate) are the custom logic actually built here, in
/// `features/voice/`.
class VoiceListeningScreen extends ConsumerStatefulWidget {
  const VoiceListeningScreen({super.key});

  @override
  ConsumerState<VoiceListeningScreen> createState() => _VoiceListeningScreenState();
}

class _VoiceListeningScreenState extends ConsumerState<VoiceListeningScreen> {
  final _speech = stt.SpeechToText();
  bool _listening = false;
  bool _speechAvailable = false;
  String _transcript = '';
  String? _errorMessage;

  /// The ASR engine's own confidence in the whole utterance just heard
  /// (`speech_to_text`'s convention: -1 means "not supplied"). Folded into
  /// the confidence gate in [_onCaptureFinished] — see
  /// [SlotParser.withAsrConfidence] for why the grammar/parser layer alone
  /// can't catch a noisy-but-grammatically-clean misrecognition.
  double _asrConfidence = -1;

  /// Safety net: on-device testing surfaced a real failure mode where the
  /// platform recognizer starts listening (confirmed via the OS's own mic-
  /// in-use indicator) but never fires *any* callback — no result, no
  /// error, no status — leaving the screen stuck on "Listening…"
  /// indefinitely with no way out except leaving the screen. Android's
  /// SpeechRecognizer is supposed to end-of-speech-detect off the live
  /// audio stream, but that has nothing to key off of when there's no
  /// audio input at all. A hard client-side timeout guarantees the retailer
  /// is never stranded here, on any device.
  static const _listenTimeout = Duration(seconds: 15);
  Timer? _listenTimeoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _listenTimeoutTimer?.cancel();
    _speech.stop();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _errorMessage = null);
    final l10n = AppLocalizations.of(context);

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      setState(() => _errorMessage = l10n.micPermissionDenied);
      return;
    }

    if (!_speechAvailable) {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _errorMessage = l10n.noisyPrompt;
            _listening = false;
          });
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _onCaptureFinished();
          }
        },
      );
    }
    if (!_speechAvailable) {
      if (mounted) setState(() => _errorMessage = l10n.micUnavailable);
      return;
    }

    final locale = ref.read(localeProvider);
    final speechLocaleId = switch (locale) {
      AppLocale.urdu => 'ur_PK',
      AppLocale.romanUrdu || AppLocale.english => 'en_US',
    };

    // Not every device ships speech recognition for every language — Urdu
    // in particular isn't universally available. Checking first means an
    // unsupported language surfaces as a clear "voice isn't available"
    // message instead of an opaque recognizer error after tapping the mic.
    final available = await _speech.locales();
    if (!available.any((l) => l.localeId == speechLocaleId)) {
      if (mounted) setState(() => _errorMessage = l10n.micUnavailable);
      return;
    }

    setState(() {
      _listening = true;
      _transcript = '';
      _asrConfidence = -1;
    });
    _listenTimeoutTimer?.cancel();
    _listenTimeoutTimer = Timer(_listenTimeout, () {
      // Belt-and-suspenders: stop() *should* fire onStatus itself, but the
      // failure mode this guards against is exactly the platform side
      // going silent, so _onCaptureFinished is also called directly rather
      // than trusting that callback to arrive.
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

  void _onCaptureFinished() {
    if (!mounted || !_listening) return;
    _listenTimeoutTimer?.cancel();
    setState(() => _listening = false);

    final l10n = AppLocalizations.of(context);
    if (_transcript.trim().isEmpty) {
      setState(() => _errorMessage = l10n.noisyPrompt);
      return;
    }

    final parsed = SlotParser.withAsrConfidence(SlotParser.parse(_transcript), _asrConfidence);
    final controller = ref.read(billingControllerProvider.notifier);

    if (!parsed.needsConfirmation) {
      // High confidence across every field — auto-fills per SRS §12.2
      // layer 5, no tap required.
      controller.addItem(DraftLineItem(
        itemNameRaw: parsed.itemNameRaw,
        inputMethod: InputMethod.voice,
        quantity: parsed.quantity,
        unit: parsed.unit,
        pricePerUnit: parsed.pricePerUnit,
      ));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RunningBillScreen()),
      );
      return;
    }

    // Low confidence on at least one field — the confidence gate: hand off
    // to the manual entry screen, pre-filled, for a one-tap confirm/correct
    // (SRS §12.5) rather than silently accepting a guess.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ManualEntryScreen(prefill: parsed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FabMic(onTap: _start, size: 96, listening: _listening),
                const SizedBox(height: 22),
                Text(
                  _listening ? l10n.listeningEllipsis : l10n.tapMicToRetry,
                  style: type.eyebrow.copyWith(color: colors.textSoft),
                  textAlign: TextAlign.center,
                ),
                if (_transcript.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    '"$_transcript"',
                    style: type.bodyEmphasis.copyWith(color: colors.accent, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(_errorMessage!, style: type.caption.copyWith(color: colors.alert)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
