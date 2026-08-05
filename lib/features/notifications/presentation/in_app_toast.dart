import 'package:flutter/material.dart';

import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';

/// F2 — in-app toast confirmations (build order step 8): transient,
/// self-dismissing banners for events that just happened in this session
/// (bill saved, receipt sent, connectivity dropped) — distinct from F1/F3's
/// system-tray notifications, which fire outside the app for things the
/// retailer needs to come back and act on.
enum BoloToastKind { success, whatsapp, offline }

/// Inserted into the *root* overlay (not the current route's) so it
/// survives the `pushAndRemoveUntil` that typically follows the action it's
/// confirming (e.g. bill confirm → receipt screen) rather than disappearing
/// the instant the triggering screen is popped.
void showBoloToast(BuildContext context, {required BoloToastKind kind, required String message}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _BoloToast(kind: kind, message: message, onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _BoloToast extends StatefulWidget {
  const _BoloToast({required this.kind, required this.message, required this.onDone});

  final BoloToastKind kind;
  final String message;
  final VoidCallback onDone;

  @override
  State<_BoloToast> createState() => _BoloToastState();
}

class _BoloToastState extends State<_BoloToast> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;
    final (background, icon) = switch (widget.kind) {
      BoloToastKind.success => (colors.success, Icons.check_circle_outline),
      BoloToastKind.whatsapp => (colors.accent, Icons.chat_outlined),
      BoloToastKind.offline => (colors.text, Icons.cloud_off_outlined),
    };

    return Positioned(
      top: MediaQuery.of(context).padding.top + 14,
      left: 14,
      right: 14,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(_opacity),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppRadii.md),
                boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 20, offset: Offset(0, 8))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: type.bodyEmphasis.copyWith(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
