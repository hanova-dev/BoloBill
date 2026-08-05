import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../domain/usecases/reminders/overdue_reminder.dart';

/// F1 (system tray) and F3 (expanded reminder) — both are OS chrome this
/// class only feeds bytes to; the overdue-balance decision itself lives
/// entirely in [OverdueReminders] (build order step 8: "F1/F3 payload
/// builders only render whatever that usecase decides — no business logic
/// in the presentation layer").
///
/// A single overdue customer renders as one notification matching the F1
/// mock ("Salman Khan — overdue 30 days" / "Rs. 2,100 owed."). Two or more
/// collapse into one grouped notification with an inbox-style list and
/// "View Khata"/"Later" actions, matching F3 — one notification per
/// customer would just be spam once a shop has several overdue accounts.
class LocalNotificationsService {
  LocalNotificationsService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _channelId = 'khata_reminders';
  static const viewKhataActionId = 'view_khata';
  static const _laterActionId = 'later';

  /// [onAction] fires for both a plain tap and the "View Khata" action —
  /// there is only one destination this notification ever points at — and
  /// is skipped for "Later", which just dismisses.
  Future<void> initialize({required void Function() onAction}) async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId == _laterActionId) return;
        onAction();
      },
    );
    _initialized = true;
  }

  Future<void> showOverdueReminders(
    List<OverdueReminder> reminders,
    AppLocalizations l10n,
  ) async {
    if (reminders.isEmpty) return;
    // Best-effort: the retailer may have declined the E5 permission prompt
    // during onboarding, or be on a device where it was never granted.
    // Missing a reminder is never worth surfacing an error for.
    if (!await Permission.notification.isGranted) return;

    final actions = [
      AndroidNotificationAction(viewKhataActionId, l10n.viewKhataAction, showsUserInterface: true),
      AndroidNotificationAction(_laterActionId, l10n.laterReminderAction),
    ];

    if (reminders.length == 1) {
      final reminder = reminders.single;
      await _plugin.show(
        id: reminder.customerId.hashCode,
        title: l10n.overdueReminderTitle(reminder.customerName, reminder.daysOverdue),
        body: l10n.overdueReminderBody(reminder.amountOwed.format()),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            l10n.remindersChannelName,
            channelDescription: l10n.remindersChannelDescription,
            actions: actions,
          ),
        ),
      );
      return;
    }

    final lines = [for (final r in reminders) '${r.customerName}   ${r.amountOwed.format()}'];
    await _plugin.show(
      id: 0,
      title: l10n.overdueReminderGroupTitle(reminders.length),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          l10n.remindersChannelName,
          channelDescription: l10n.remindersChannelDescription,
          styleInformation: InboxStyleInformation(
            lines,
            contentTitle: l10n.overdueReminderGroupTitle(reminders.length),
          ),
          actions: actions,
        ),
      ),
    );
  }
}
