import 'package:flutter/material.dart';

import '../core/theme/app_color_tokens.dart';
import '../core/theme/app_radii.dart';
import '../core/theme/app_typography.dart';

/// The pill-shaped selectable chip used throughout the mockups (`.chip`,
/// `.chip.active`) — language pills, quick-fraction buttons, payment-type
/// toggles, etc. Deliberately not Material's `ChoiceChip` directly: the
/// mockup's chip has its own padding/radius/weight recipe that doesn't map
/// 1:1 onto Material defaults.
class BoloChip extends StatelessWidget {
  const BoloChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorTokens>()!;
    final type = theme.extension<AppTypographyTokens>()!;
    // Light theme's active chip is Arsenic-on-white; dark theme's is the
    // brighter ember accent, which reads better with dark text on top of it
    // (mirrors `.chip.active` vs `.dark-phone .chip.active` in the mockups).
    final activeLabelColor =
        theme.brightness == Brightness.dark ? colors.scaffoldBackground : Colors.white;

    return Material(
      color: selected ? colors.accent : colors.tint,
      borderRadius: BorderRadius.circular(AppRadii.chip),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.chip),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 6)],
              Text(
                label,
                style: type.caption.copyWith(
                  color: selected ? activeLabelColor : colors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
