import 'package:flutter/material.dart';

import '../core/theme/app_color_tokens.dart';

/// The circular mic button with pulsing rings (mockup `.fab-mic`), used
/// wherever voice entry is the primary action — A4 shop-name capture here,
/// and the billing voice screens (B module) later.
class FabMic extends StatefulWidget {
  const FabMic({
    super.key,
    required this.onTap,
    this.size = 78,
    this.listening = false,
  });

  final VoidCallback onTap;
  final double size;

  /// Whether the mic is actively capturing — drives the pulsing rings.
  final bool listening;

  @override
  State<FabMic> createState() => _FabMicState();
}

class _FabMicState extends State<FabMic> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Created unconditionally in initState, not lazily via a `late final =`
    // field initializer: build() only reads `_controller` when
    // `widget.listening` is true, so a lazy initializer left it uncreated
    // until dispose()'s first read — constructing an AnimationController
    // that late tries to walk an already-deactivating element tree and
    // throws "Looking up a deactivated widget's ancestor is unsafe."
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    if (widget.listening) _controller.repeat();
  }

  @override
  void didUpdateWidget(FabMic oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The rings should only actively animate while listening — an
    // unconditionally-repeating controller never lets animations "settle"
    // (breaks `pumpAndSettle` in tests) and burns battery for a visual
    // effect that isn't even shown when idle (see the `if (widget.listening)`
    // guard in build() below).
    if (widget.listening && !oldWidget.listening) {
      _controller.repeat();
    } else if (!widget.listening && oldWidget.listening) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;

    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.listening) ...[
            _Ring(controller: _controller, delay: 0, baseSize: widget.size, color: colors.accent),
            _Ring(controller: _controller, delay: 0.33, baseSize: widget.size, color: colors.accent),
            _Ring(controller: _controller, delay: 0.66, baseSize: widget.size, color: colors.accent),
          ],
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onTap,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.4),
                    colors: [colors.accentGradientEnd, colors.accent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(Icons.mic, color: Colors.white, size: widget.size * 0.38),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.controller, required this.delay, required this.baseSize, required this.color});

  final AnimationController controller;
  final double delay;
  final double baseSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = (controller.value + delay) % 1.0;
        final size = baseSize + (baseSize * 0.9 * t);
        final opacity = (1 - t).clamp(0.0, 1.0) * 0.6;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: opacity), width: 1.5),
          ),
        );
      },
    );
  }
}
