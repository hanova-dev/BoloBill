import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// intl exports its own TextDirection class, which collides with Flutter's —
// hidden here since this file only needs intl for DateFormat.
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/di/providers.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/sync/sync_status.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared_widgets/fab_mic.dart';
import '../../khata/presentation/khata_list_screen.dart';
import '../../notifications/presentation/in_app_toast.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'manual_entry_screen.dart';
import 'voice_listening_screen.dart';

/// Screen B1 — the billing home / empty-bill state. Once the first line
/// item exists (voice or manual), B2/B4 replace this with B3 (the running
/// list) — B1 itself is only ever the pre-first-item entry point.
class BillingHomeScreen extends ConsumerWidget {
  const BillingHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final type = Theme.of(context).extension<AppTypographyTokens>()!;
    final shop = ref.watch(currentShopProvider);
    // Keeps the Sync Manager's connectivity/shop listeners alive for the
    // life of the app (build order step 7) — B1 is always on screen or on
    // the back stack whenever a shop exists, unlike D3 Settings.
    ref.watch(syncManagerProvider);
    // Same reasoning for the once-a-day overdue-reminders check (step 8).
    ref.watch(remindersCheckerProvider);
    // F2 toast the moment connectivity actually drops — distinct from D3's
    // persistent sync-status card, which is "look it up"; this is "notice
    // it happened", matching the F2 mock's "No internet — will sync later".
    ref.listen<SyncStatus>(syncManagerProvider, (previous, next) {
      if (next is SyncOffline && previous is! SyncOffline) {
        showBoloToast(context, kind: BoloToastKind.offline, message: l10n.offlineWillSyncToast);
      }
    });

    final dateStr = DateFormat('d MMM').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(shop?.shopName ?? l10n.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: l10n.khataListTitle,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const KhataListScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: l10n.reportsTitle,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(18),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Center(
              child: Builder(
                builder: (context) {
                  final style = type.caption.copyWith(
                    color: colors.appBarForeground.withValues(alpha: 0.8),
                    fontSize: 11,
                  );
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.todayLabel, style: style),
                      Text(' • ', style: style),
                      // Explicit LTR: see the phone-number bidi note in
                      // settings_screen.dart — a formatted date is the same
                      // neutral-character-run problem and reorders under RTL.
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(dateStr, style: style),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.startNewBill,
                        style: type.bodyEmphasis.copyWith(color: colors.text),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.tapMicOrManual,
                        style: type.caption.copyWith(color: colors.textSoft),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                children: [
                  FabMic(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const VoiceListeningScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManualEntryScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.keyboard),
                    label: Text(l10n.enterManually),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
