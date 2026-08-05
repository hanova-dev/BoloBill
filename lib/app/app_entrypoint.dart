import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/providers.dart';
import '../core/localization/locale_provider.dart';
import '../core/theme/app_color_tokens.dart';
import '../features/billing/presentation/billing_home_screen.dart';
import '../features/onboarding/presentation/language_select_screen.dart';
import '../shared_widgets/fab_mic.dart';

/// The app's real entry point (MaterialApp.home) — decides whether to show
/// onboarding or resume straight into billing.
///
/// SRS §9.1: one shop per device/install. A local shop row already existing
/// means this device has already been onboarded, so re-running onboarding
/// on every launch (the previous behavior) was a bug, not a design choice —
/// [core/di/providers.dart]'s `currentShopProvider` doc comment flagged this
/// exact gap. The local DB is the source of truth here (not Firebase Auth's
/// persisted session), consistent with the app being offline-first: a shop
/// that was set up while online must still resume correctly with no
/// connectivity at all on a later launch.
class AppEntrypoint extends ConsumerStatefulWidget {
  const AppEntrypoint({super.key});

  @override
  ConsumerState<AppEntrypoint> createState() => _AppEntrypointState();
}

class _AppEntrypointState extends ConsumerState<AppEntrypoint> {
  late final Future<bool> _resumed = _tryResume();

  Future<bool> _tryResume() async {
    // Falls through to onboarding on any lookup failure rather than
    // crashing — an unreadable local shop record should never be a harder
    // failure than "this device looks unonboarded".
    try {
      final shop = await ref.read(shopRepositoryProvider).getLocalShop();
      if (shop == null) return false;
      ref.read(currentShopProvider.notifier).state = shop;
      ref.read(localeProvider.notifier).state = shop.preferredLanguage;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _resumed,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          final colors = Theme.of(context).extension<AppColorTokens>()!;
          return Scaffold(
            backgroundColor: colors.surface,
            body: Center(child: FabMic(onTap: () {}, size: 72, listening: false)),
          );
        }
        return snapshot.data! ? const BillingHomeScreen() : const LanguageSelectScreen();
      },
    );
  }
}
