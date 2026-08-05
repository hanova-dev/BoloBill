import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../billing/presentation/billing_home_screen.dart';
import '../application/onboarding_controller.dart';

/// Terminal landing state after onboarding. Not a mockup screen — it's a
/// brief confirmation that the shop was actually created before handing off
/// to B1 (the real billing home, now built in step 4).
class OnboardingCompleteScreen extends ConsumerWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;
    final state = ref.watch(onboardingControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: colors.success, size: 56),
                const SizedBox(height: 16),
                Text(
                  l10n.setupCompleteTitle,
                  style: type.screenTitle.copyWith(color: colors.text),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  state.shopName,
                  style: type.bodyEmphasis.copyWith(color: colors.accent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.setupCompleteBody,
                  style: type.caption.copyWith(color: colors.textSoft),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const BillingHomeScreen()),
                    (route) => false,
                  ),
                  child: Text(l10n.startBillingButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
