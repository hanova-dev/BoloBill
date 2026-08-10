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
/// "VAD" here is push-to-talk: the retailer holds the mic down for exactly
/// as long as they're speaking and lets go when done, rather than the app
/// guessing from silence when they've finished (§12.6: "push-to-talk ... is
/// the default interaction, not always-on listening" — bounding the audio
/// window this way is itself the noise-reduction strategy). Real-device
/// testing in market-noise conditions found the platform's own silence
/// detection an unreliable way to end a recording — it either cuts someone
/// off mid-sentence or, if background noise reads as "still talking", keeps
/// listening well past when they're done. Direct physical control removes
/// that guess entirely. §12.9 recommends the built-in recognizer as the v1
/// baseline specifically *paired with* the grammar/confidence layers, not a
/// bespoke signal-processing stack — layers 3-5 (domain grammar, slot
/// parser, confidence gate) are the custom logic actually built here, in
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

  /// Tracks whether the finger is still down — [_start]'s remaining setup
  /// (mainly the permission check; engine init and locale lookup are
  /// pre-warmed, see [_speechSetup]) is still async, so a very quick
  /// press-and-release can finish *before* it does. Checked right before
  /// actually calling `.listen()` so a tap-and-immediately-let-go never
  /// starts listening after the retailer has already lifted their finger,
  /// which would be a confusing "I let go and it's still recording."
  bool _pressed = false;

  /// Kicked off in [initState], not lazily on first press — real-device
  /// testing measured `speech_to_text.initialize()` alone (it binds to the
  /// platform recognizer service) taking multiple seconds, and that whole
  /// chain used to sit between the retailer's touch and the button showing
  /// anything at all. Pre-warming it here means a later press only ever
  /// waits on the permission check (near-instant once granted) before
  /// `.listen()` actually starts.
  late Future<String?> _speechSetup;

  /// Bumped on every press; each in-flight [_start] captures its own copy
  /// and checks it against this before touching shared state or calling
  /// `.listen()`. Repeated rapid taps during the old dead-feedback window
  /// could otherwise spawn several overlapping `_start` calls — each
  /// re-running the same async setup, stacking up latency and occasionally
  /// letting a stale attempt fire `.listen()` after the finger was already
  /// off the button. A superseded attempt now just quietly bails out.
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

  /// Engine init + locale resolution only — no permission check (that has
  /// to happen live, right before recording, since it can change at any
  /// time) and no `l10n`/`context` use (this runs from [initState], before
  /// the first frame). Returns the resolved locale id to pass to
  /// `.listen()`, or null if voice isn't usable at all — [_start] turns
  /// that into the one existing "mic unavailable" message, same as before.
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

    // Not every device ships speech recognition for every language — Urdu
    // in particular isn't universally available — so this checks first
    // rather than surfacing an opaque recognizer error after tapping the
    // mic. Two things real-device testing found the original exact-match
    // version got wrong: (1) `locales()` is itself unreliable on some
    // devices/plugin versions, coming back empty even though recognition
    // works fine — an empty list is now treated as "unknown, proceed"
    // rather than "unavailable"; (2) real phones report all sorts of
    // regional variants (en_GB, en_IN, en_PK, ...), so matching is now
    // language-family-based rather than requiring the literal 'en_US' or
    // 'ur_PK' string, which was rejecting working voice recognition on
    // real devices outside the US/Pakistan-exact locale.
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

    // The permission check above is async — if the retailer already let go
    // before it finished, don't start listening into what's now an unheld
    // button.
    if (!_pressed) return;

    setState(() {
      _listening = true;
      _transcript = '';
      _asrConfidence = -1;
    });
    _listenTimeoutTimer?.cancel();
    _listenTimeoutTimer = Timer(_listenTimeout, () {
      // Caps how long a single hold can run (nobody needs to hold the mic
      // for a whole billing line) and doubles as a hang safety net:
      // stop() *should* fire onStatus itself, but the failure mode this
      // guards against is exactly the platform side going silent, so
      // _onCaptureFinished is also called directly rather than trusting
      // that callback to arrive.
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
                FabMic(
                  onHoldStart: _onHoldStart,
                  onHoldEnd: _onHoldEnd,
                  size: 96,
                  listening: _listening,
                ),
                const SizedBox(height: 22),
                Text(
                  _listening ? l10n.listeningEllipsis : l10n.holdMicToSpeak,
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
