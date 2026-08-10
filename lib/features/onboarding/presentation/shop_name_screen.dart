import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/localization/app_locale.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared_widgets/bolo_chip.dart';
import '../../../shared_widgets/fab_mic.dart';
import '../application/onboarding_controller.dart';
import 'onboarding_complete_screen.dart';

/// Screen A4 — shop name via voice or manual entry (FR-3.1.4). The
/// recognized-speech display is itself the editable text field: tapping the
/// mic fills it, tapping the field and typing corrects/replaces it — voice
/// and manual are the same control, not a primary path with a hidden manual
/// fallback (per the "equal status" architectural principle).
///
/// Uses `speech_to_text` for raw dictation only — the full VAD/domain-
/// grammar/confidence-gate pipeline (SRS §12) is for structured billing
/// entries (item/price/quantity) and belongs to build order step 4; a shop
/// name is a single freeform string with nothing to parse.
class ShopNameScreen extends ConsumerStatefulWidget {
  const ShopNameScreen({super.key});

  @override
  ConsumerState<ShopNameScreen> createState() => _ShopNameScreenState();
}

class _ShopNameScreenState extends ConsumerState<ShopNameScreen> {
  final _speech = stt.SpeechToText();
  final _nameController = TextEditingController();
  bool _listening = false;
  bool _speechAvailable = false;
  String? _micError;
  bool _completing = false;

  /// Same safety net as the bill-in-progress screen's voice capture
  /// (RunningBillScreen) — on-device testing found the platform recognizer
  /// can start listening and then never fire any callback at all, leaving
  /// the mic stuck "listening" forever with no way out. A4 never had this
  /// guard even though it shares the exact same underlying `speech_to_text`
  /// call.
  static const _listenTimeout = Duration(seconds: 15);
  Timer? _listenTimeoutTimer;

  /// See [RunningBillScreen]'s `_pressed` — press-and-hold setup is async,
  /// so a very quick press-and-release can finish *after* the finger's
  /// already up; checked right before `.listen()` so that race never starts
  /// listening into an unheld button.
  bool _pressed = false;

  /// See [RunningBillScreen]'s `_speechSetup` — pre-warmed in [initState]
  /// rather than lazily on first press, since engine init alone measured
  /// multiple seconds on real hardware and used to sit entirely between the
  /// retailer's touch and any visible response.
  late Future<String?> _speechSetup;

  /// See [RunningBillScreen]'s `_startToken` — guards against overlapping
  /// `_start` calls from rapid repeated taps during that dead window.
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
    _nameController.dispose();
    super.dispose();
  }

  Future<String?> _prepareSpeechEngine() async {
    _speechAvailable = await _speech.initialize(
      // speech_to_text's error codes ("error_speech_timeout",
      // "error_no_match", ...) are internal platform identifiers, not
      // user-facing text — showing them raw to a low-literacy retailer
      // defeats the point of a voice-first app. Every error, from the
      // engine or from the timeout below, collapses to the same one
      // friendly retry prompt already used on the bill-in-progress screen.
      onError: (error) {
        if (!mounted) return;
        _listenTimeoutTimer?.cancel();
        setState(() {
          _micError = AppLocalizations.of(context).noisyPrompt;
          _listening = false;
        });
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _listenTimeoutTimer?.cancel();
          if (mounted) setState(() => _listening = false);
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

    // Same language-family matching as the bill-in-progress screen's voice
    // pipeline — real devices routinely report a regional variant (en_GB,
    // en_IN, en_PK, ...) rather than the literal en_US/ur_PK, and locales()
    // itself is sometimes empty even on a device where recognition works
    // fine. See RunningBillScreen's `_prepareSpeechEngine` for the full
    // reasoning.
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
    setState(() => _micError = null);
    final l10n = AppLocalizations.of(context);

    final status = await Permission.microphone.request();
    if (token != _startToken) return;
    if (!status.isGranted) {
      setState(() => _micError = l10n.micPermissionDenied);
      return;
    }

    final speechLocaleId = await _speechSetup;
    if (token != _startToken) return;
    if (speechLocaleId == null) {
      setState(() => _micError = l10n.micUnavailable);
      return;
    }

    if (!_pressed) return;

    setState(() => _listening = true);
    _listenTimeoutTimer?.cancel();
    _listenTimeoutTimer = Timer(_listenTimeout, () {
      _speech.stop();
      if (mounted) setState(() => _listening = false);
    });
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(localeId: speechLocaleId),
      onResult: (result) => setState(() => _nameController.text = result.recognizedWords),
    );
  }

  Future<void> _onContinue() async {
    setState(() => _completing = true);
    final controller = ref.read(onboardingControllerProvider.notifier);
    controller.setShopName(_nameController.text.trim());

    // E5: requested at the end of onboarding, once there's something worth
    // notifying about (sync completion, khata reminders — steps 7/8).
    await Permission.notification.request();

    try {
      await controller.completeOnboarding();
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingCompleteScreen()),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;
    final hasName = _nameController.text.trim().isNotEmpty;

    // No AppBar — the mockup's A4 is deliberately chrome-less, full-bleed
    // content. Android's system back gesture still pops the Navigator stack
    // without needing a visible back button here.
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          child: Column(
            children: [
              const Spacer(),
              FabMic(onHoldStart: _onHoldStart, onHoldEnd: _onHoldEnd, listening: _listening),
              const SizedBox(height: 22),
              Text(
                _listening ? l10n.listeningEllipsis : l10n.sayYourShopName,
                style: type.eyebrow.copyWith(color: colors.textSoft),
                textAlign: TextAlign.center,
              ),
              if (!_listening) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.holdMicToSpeak,
                  style: type.caption.copyWith(color: colors.textSoft),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                onChanged: (_) => setState(() {}),
                style: type.screenTitle.copyWith(color: colors.accent, fontSize: 20),
                decoration: InputDecoration(
                  hintText: l10n.shopNameHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                ),
              ),
              const SizedBox(height: 16),
              if (hasName)
                BoloChip(label: l10n.heardItCorrect, selected: false, leading: const Icon(Icons.check, size: 14)),
              if (_micError != null) ...[
                const SizedBox(height: 12),
                Text(_micError!, style: type.caption.copyWith(color: colors.alert)),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: hasName && !_completing ? _onContinue : null,
                child: _completing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l10n.continueLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
