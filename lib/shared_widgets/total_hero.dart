import 'package:flutter/material.dart';

import '../core/theme/app_color_tokens.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/money.dart';

/// The large, high-contrast total display (mockup `.total-hero`) — used for
/// Jama Karain (B5, FR-3.3.3) and later for khata balance displays.
class TotalHero extends StatelessWidget {
  const TotalHero({super.key, required this.label, required this.amount, this.amountColor, this.child});

  final String label;
  final Money amount;
  final Color? amountColor;

  /// Optional extra content below the amount (e.g. the TTS read-back chip).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.surfaceAlt, colors.scaffoldBackground],
        ),
      ),
      child: Column(
        children: [
          Text(label, style: type.eyebrow.copyWith(color: colors.textSoft)),
          const SizedBox(height: 6),
          Text(amount.format(), style: type.amountHero.copyWith(color: amountColor ?? colors.accent)),
          if (child != null) ...[const SizedBox(height: 12), child!],
        ],
      ),
    );
  }
}
