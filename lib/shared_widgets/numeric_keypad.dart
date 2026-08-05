import 'package:flutter/material.dart';

import '../core/theme/app_color_tokens.dart';
import '../core/theme/app_radii.dart';
import '../core/theme/app_typography.dart';

/// The custom numeric keypad used for phone-number and amount entry
/// (mockup `.keypad`/`.key`/`.key.func`) — not the OS keyboard, so digit
/// size/spacing stays consistent and large (NFR §4.1.1: 56x56dp minimum
/// touch targets) regardless of device keyboard settings.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onLeadingKeyTap,
    this.leadingKeyIcon,
    this.leadingKeyLabel,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  /// The bottom-left function key — e.g. a mic ("🎤 Speak") for phone entry,
  /// or "." for decimal amounts. Null renders an empty placeholder cell.
  final VoidCallback? onLeadingKeyTap;
  final IconData? leadingKeyIcon;
  final String? leadingKeyLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;

    Widget digitKey(String digit) {
      return _KeypadKey(
        onTap: () => onDigit(digit),
        color: colors.surface,
        borderColor: colors.cardBorder,
        child: Text(
          digit,
          style: type.screenTitle.copyWith(color: colors.accent, fontSize: 20),
        ),
      );
    }

    Widget funcKey({required Widget child, required VoidCallback? onTap}) {
      return _KeypadKey(
        onTap: onTap,
        color: colors.tint,
        borderColor: colors.tint,
        child: child,
      );
    }

    // Numeric keypads keep 1-2-3/4-5-6/7-8-9 left-to-right by universal
    // convention, independent of the surrounding text direction — real
    // dialer/calculator apps in Urdu/Arabic do the same. Without this, the
    // ambient RTL Directionality would mirror the whole grid (9-8-7 first).
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.4,
        children: [
          digitKey('1'),
          digitKey('2'),
          digitKey('3'),
          digitKey('4'),
          digitKey('5'),
          digitKey('6'),
          digitKey('7'),
          digitKey('8'),
          digitKey('9'),
          funcKey(
            onTap: onLeadingKeyTap,
            child: leadingKeyIcon != null
                ? Icon(leadingKeyIcon, color: colors.accent, size: 20)
                : Text(
                    leadingKeyLabel ?? '',
                    style: type.buttonLabel.copyWith(
                      color: colors.accent,
                      fontSize: 12,
                    ),
                  ),
          ),
          digitKey('0'),
          funcKey(
            onTap: onBackspace,
            child: Icon(
              Icons.backspace_outlined,
              color: colors.accent,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    required this.child,
    required this.color,
    required this.borderColor,
    this.onTap,
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppRadii.key),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.key),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56, minWidth: 56),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadii.key),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
