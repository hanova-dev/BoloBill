import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/providers.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/navigation/root_navigator_key.dart';
import '../../../domain/entities/shop.dart';
import '../../../domain/usecases/reminders/overdue_reminder.dart';
import '../../khata/presentation/khata_list_screen.dart';
import 'local_notifications_service.dart';

/// Runs the overdue-balance check (build order step 8) once a shop is
/// available, same trigger shape as [SyncManager] — a shop becoming
/// available on this device is the only signal an offline-first app with no
/// background scheduler has to work with (see the on-device summary for why
/// true background-scheduled reminders are out of scope for this pass).
///
/// Capped at once per calendar day via [SharedPreferences] — re-showing the
/// same "N customers overdue" notification every time the retailer opens
/// the app (which could be dozens of times a day) would train them to
/// ignore it.
class RemindersChecker {
  RemindersChecker(this._ref, this._notifications) {
    _notifications.initialize(onAction: _openKhataList);
    _shopSub = _ref.listen<Shop?>(currentShopProvider, (previous, next) {
      if (previous == null && next != null) _checkOnce(next);
    });
    final shop = _ref.read(currentShopProvider);
    if (shop != null) _checkOnce(shop);
  }

  // A tapped notification fires from the OS, not from any widget's event
  // handler, so there is no BuildContext to push from — the root navigator
  // key (set on MaterialApp in app.dart) is the standard way to navigate
  // from that kind of callback. "View Khata" only ever points at one
  // destination, so pushing it directly here (rather than threading a
  // callback all the way through the provider graph) is the pragmatic
  // choice, consistent with how other plugin-driven screens in this app
  // (e.g. voice/Bluetooth) call their platform APIs directly.
  void _openKhataList() {
    rootNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const KhataListScreen()),
    );
  }

  static const _lastCheckedKey = 'reminders_last_checked_date';

  final Ref _ref;
  final LocalNotificationsService _notifications;
  late final ProviderSubscription<Shop?> _shopSub;

  Future<void> _checkOnce(Shop shop) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    if (prefs.getString(_lastCheckedKey) == today) return;

    final customers = await _ref.read(customerRepositoryProvider).getCustomersForShop(shop.shopId);
    final reminders = OverdueReminders.evaluate(customers);
    if (reminders.isNotEmpty) {
      // No BuildContext is available here — this runs from provider
      // construction, not a widget build — so the l10n lookup goes through
      // the generated delegate directly rather than `AppLocalizations.of`.
      final locale = _ref.read(localeProvider);
      final l10n = await AppLocalizations.delegate.load(locale.locale);
      await _notifications.showOverdueReminders(reminders, l10n);
    }
    await prefs.setString(_lastCheckedKey, today);
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void dispose() => _shopSub.close();
}
