import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_radii.dart';
import '../core/theme/app_typography.dart';

/// The "Continue with Google" button (mockup `.g-btn`): white background,
/// the multicolor Google "G" mark, dark label text — visually distinct from
/// [OutlinedButton]/[ElevatedButton] on purpose, since Google's brand
/// guidelines require its own button treatment, not the app's accent color.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.label, required this.onPressed, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<AppTypographyTokens>()!;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.button),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.button),
        onTap: loading ? null : onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.button),
            border: Border.all(color: const Color(0xFFE3DED5), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const _GoogleMark(size: 18),
              const SizedBox(width: 10),
              Text(
                label,
                style: type.buttonLabel.copyWith(color: const Color(0xFF3C3C3C)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _GoogleMarkPainter()));
  }
}

/// A simplified four-quadrant rendition of the Google "G" mark's brand
/// colors — not a traced SVG, but instantly recognizable at button size.
class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    void arc(double startDeg, double sweepDeg, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startDeg * math.pi / 180, sweepDeg * math.pi / 180, false, paint);
    }

    arc(-90, 80, const Color(0xFF4285F4));
    arc(-6, 100, const Color(0xFF34A853));
    arc(96, 80, const Color(0xFFFBBC05));
    arc(178, 80, const Color(0xFFEA4335));

    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - strokeWidth / 2, radius - strokeWidth * 0.3, strokeWidth),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
