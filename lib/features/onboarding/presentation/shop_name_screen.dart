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

  @override
  void dispose() {
    _speech.stop();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onMicTap() async {
    setState(() => _micError = null);
    final l10n = AppLocalizations.of(context);

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      setState(() => _micError = l10n.micPermissionDenied);
      return;
    }

    if (!_speechAvailable) {
      _speechAvailable = await _speech.initialize(
        onError: (error) => setState(() => _micError = error.errorMsg),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _listening = false);
          }
        },
      );
    }
    if (!_speechAvailable) {
      setState(() => _micError = l10n.micUnavailable);
      return;
    }

    final locale = ref.read(localeProvider);
    final speechLocaleId = switch (locale) {
      AppLocale.urdu => 'ur_PK',
      AppLocale.romanUrdu || AppLocale.english => 'en_US',
    };
    setState(() => _listening = true);
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
              FabMic(onTap: _onMicTap, listening: _listening),
              const SizedBox(height: 22),
              Text(
                l10n.sayYourShopName,
                style: type.eyebrow.copyWith(color: colors.textSoft),
                textAlign: TextAlign.center,
              ),
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
