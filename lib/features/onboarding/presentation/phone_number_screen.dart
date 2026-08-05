import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared_widgets/numeric_keypad.dart';
import '../application/onboarding_controller.dart';
import 'business_type_screen.dart';
import 'otp_verify_screen.dart';

/// Screen A3 — phone number entry, shared by both onboarding paths per the
/// resolved sequence:
/// - [PhoneEntryMode.plainCapture] (after Google sign-in): a plain contact
///   field, no OTP round-trip — Google already authenticated the person.
/// - [PhoneEntryMode.otpVerified] (the "Continue with Phone Number" path):
///   the phone number IS the identity being verified (FR-3.1.2), so
///   "Continue" here sends a real OTP via Firebase.
enum PhoneEntryMode { plainCapture, otpVerified }

class PhoneNumberScreen extends ConsumerStatefulWidget {
  const PhoneNumberScreen({super.key, required this.mode});

  final PhoneEntryMode mode;

  @override
  ConsumerState<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends ConsumerState<PhoneNumberScreen> {
  String _digits = '';
  bool _sending = false;
  String? _errorMessage;

  static const _maxDigits = 10;

  String get _e164 => '+92$_digits';

  void _onDigit(String digit) {
    if (_digits.length >= _maxDigits) return;
    setState(() => _digits += digit);
  }

  void _onBackspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  Future<void> _onContinue() async {
    final controller = ref.read(onboardingControllerProvider.notifier);
    controller.setPhoneNumber(_e164);

    if (widget.mode == PhoneEntryMode.plainCapture) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BusinessTypeScreen()));
      return;
    }

    setState(() {
      _sending = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .sendOtp(
            phoneNumber: _e164,
            onAutoVerified: (result) {
              if (!mounted) return;
              controller.setAuthResult(result);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BusinessTypeScreen()),
              );
            },
            onCodeSent: (verificationId) {
              if (!mounted) return;
              controller.setVerificationId(verificationId);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OtpVerifyScreen(phoneNumber: _e164),
                ),
              );
            },
            onFailed: (message) {
              if (!mounted) return;
              setState(() {
                _errorMessage = message;
                _sending = false;
              });
            },
          );
    } finally {
      // onCodeSent/onAutoVerified/onFailed all fire asynchronously later;
      // this only clears the initial "sending" spinner once the request
      // itself has been dispatched.
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;
    final canContinue = _digits.length == _maxDigits && !_sending;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(l10n.enterNumberTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.mobileNumberLabel,
                style: type.eyebrow.copyWith(color: colors.textSoft),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.accent, width: 2),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                // Forced LTR: a phone number is all-neutral characters
                // (digits, "+", the placeholder dots) with no strong-
                // direction character to anchor Unicode bidi resolution, so
                // inside an RTL ambient direction the "+" sign visibly
                // floats to the wrong side ("92+" instead of "+92") without
                // this explicit override.
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    _formatDisplay(),
                    style: type.screenTitle.copyWith(
                      color: colors.accent,
                      fontSize: 19,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              NumericKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: type.caption.copyWith(color: colors.alert),
                ),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: canContinue ? _onContinue : null,
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.mode == PhoneEntryMode.otpVerified
                            ? l10n.sendOtp
                            : l10n.continueLabel,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDisplay() {
    final padded = _digits.padRight(_maxDigits, '●');
    final g1 = padded.substring(0, 3).split('').join(' ');
    final g2 = padded.substring(3, 6).split('').join(' ');
    final g3 = padded.substring(6, 10).split('').join(' ');
    return '+92   $g1   $g2   $g3';
  }
}
