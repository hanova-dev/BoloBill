import 'package:flutter/material.dart';

import '../core/theme/app_color_tokens.dart';
import '../core/theme/app_radii.dart';
import '../core/theme/app_typography.dart';

/// The selectable grid tile used for business-type selection (A2) and
/// payment-type selection (B6) — mockup `.icon-tile` / `.icon-tile.selected`.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadii.tile),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.tile),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56, minWidth: 56),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.tile),
            border: Border.all(
              color: selected ? colors.accent : colors.cardBorder,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: type.caption.copyWith(color: colors.text, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
