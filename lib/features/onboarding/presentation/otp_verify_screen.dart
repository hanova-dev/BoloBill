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

/// Not one of the 26 mockup screens — Android's SMS Retriever auto-verifies
/// most of the time (FR-3.1.2's "one-tap" case, handled directly on A3 via
/// `onAutoVerified`), but auto-retrieval routinely fails on emulators and on
/// real devices without Play Services / with multiple SIMs. A manual code
/// entry fallback is required for the phone path to actually be usable, not
/// just usable-in-the-common-case.
class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  String _code = '';
  bool _verifying = false;
  String? _errorMessage;

  static const _codeLength = 6;

  void _onDigit(String digit) {
    if (_code.length >= _codeLength) return;
    setState(() => _code += digit);
  }

  void _onBackspace() {
    if (_code.isEmpty) return;
    setState(() => _code = _code.substring(0, _code.length - 1));
  }

  Future<void> _onVerify() async {
    final state = ref.read(onboardingControllerProvider);
    final verificationId = state.verificationId;
    if (verificationId == null) return;

    setState(() {
      _verifying = true;
      _errorMessage = null;
    });
    final l10n = AppLocalizations.of(context);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .verifyOtp(verificationId: verificationId, smsCode: _code);
      if (!mounted) return;
      ref.read(onboardingControllerProvider.notifier).setAuthResult(result);
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BusinessTypeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = l10n.otpIncorrectMessage);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;
    final canVerify = _code.length == _codeLength && !_verifying;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.enterCodeTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.otpSentTo(widget.phoneNumber),
                style: type.caption.copyWith(color: colors.textSoft),
              ),
              const SizedBox(height: 16),
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
                alignment: Alignment.center,
                // Same forced-LTR reasoning as the phone number field —
                // an all-neutral-character string has no bidi anchor.
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    _code.padRight(_codeLength, '●').split('').join(' '),
                    style: type.screenTitle.copyWith(
                      color: colors.accent,
                      fontSize: 22,
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
                onPressed: canVerify ? _onVerify : null,
                child: _verifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.verifyLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
