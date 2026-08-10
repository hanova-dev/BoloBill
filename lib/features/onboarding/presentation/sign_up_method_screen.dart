import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../shared_widgets/google_sign_in_button.dart';
import '../../billing/presentation/billing_home_screen.dart';
import '../application/onboarding_controller.dart';
import 'phone_number_screen.dart';

/// Screen E1 — resolved onboarding sequence: Google is the primary path
/// (zero typing); phone is the alternate path where the phone number IS the
/// identity being verified (see the implementation plan's "Resolved
/// conflict: sign-up method").
class SignUpMethodScreen extends ConsumerStatefulWidget {
  const SignUpMethodScreen({super.key});

  @override
  ConsumerState<SignUpMethodScreen> createState() => _SignUpMethodScreenState();
}

class _SignUpMethodScreenState extends ConsumerState<SignUpMethodScreen> {
  bool _googleLoading = false;
  String? _errorMessage;

  Future<void> _continueWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _errorMessage = null;
    });
    final l10n = AppLocalizations.of(context);
    try {
      final result = await ref.read(authRepositoryProvider).signInWithGoogle();
      if (!mounted) return;
      final controller = ref.read(onboardingControllerProvider.notifier);
      controller.setSignInMethod(SignInMethod.google);
      controller.setAuthResult(result);

      // This Google account may already own a shop from a previous install
      // — check before running through onboarding-from-scratch again.
      final restored = await controller.tryRestoreFromCloud();
      if (!mounted) return;
      if (restored != null) {
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BillingHomeScreen()),
          (route) => false,
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PhoneNumberScreen(mode: PhoneEntryMode.plainCapture)),
      );
    } on AuthCancelledException {
      // Person backed out of the picker — not an error, just try again.
    } catch (e) {
      setState(() => _errorMessage = l10n.signInFailedMessage);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _continueWithPhone() {
    ref.read(onboardingControllerProvider.notifier).setSignInMethod(SignInMethod.phone);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PhoneNumberScreen(mode: PhoneEntryMode.otpVerified)),
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
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: colors.accent, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.mic, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 16),
                Text(l10n.createAccountTitle, style: type.screenTitle.copyWith(color: colors.accent)),
                const SizedBox(height: 6),
                Text(l10n.chooseAMethod, style: type.caption.copyWith(color: colors.textSoft)),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: GoogleSignInButton(
                    label: l10n.continueWithGoogle,
                    loading: _googleLoading,
                    onPressed: _continueWithGoogle,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _continueWithPhone,
                    icon: const Icon(Icons.phone_android),
                    label: Text(l10n.continueWithPhone),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: type.caption.copyWith(color: colors.alert)),
                ],
                const SizedBox(height: 18),
                Text(
                  l10n.googlePrivacyNote,
                  textAlign: TextAlign.center,
                  style: type.caption.copyWith(color: colors.textSoft, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
