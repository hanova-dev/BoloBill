import 'package:flutter/foundation.dart';

import '../../../core/utils/money.dart';
import '../../entities/customer.dart';

/// A single customer flagged by [OverdueReminders.evaluate] — the decision
/// F1 (system tray) and F3 (expanded reminder) notification builders render,
/// per the build-order-step-8 rule that they hold no business logic of
/// their own.
@immutable
class OverdueReminder {
  const OverdueReminder({
    required this.customerId,
    required this.customerName,
    required this.amountOwed,
    required this.daysOverdue,
  });

  final String customerId;
  final String customerName;
  final Money amountOwed;
  final int daysOverdue;
}

/// Decides which customers are overdue on their khata balance (SRS F3 mock:
/// "30+ days"). Pure and DB/plugin-free — takes the customer list the
/// caller already has, so it's trivially unit-testable and reusable from
/// both the notification checker and, if ever needed, a UI list.
abstract final class OverdueReminders {
  static const overdueThresholdDays = 30;

  /// A customer is overdue when they currently owe the shop money
  /// ([Customer.currentBalance] positive — a negative or zero balance means
  /// the shop owes them or they're settled, neither of which is "overdue")
  /// and it's been [overdueThresholdDays] or more since the last activity
  /// on their ledger ([Customer.lastTransactionAt]) — SRS §8.2.3's existing
  /// cached fields, not a new signal. Sorted most-overdue first, matching
  /// how a retailer would triage who to chase.
  static List<OverdueReminder> evaluate(List<Customer> customers, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final reminders = <OverdueReminder>[
      for (final customer in customers)
        if (customer.currentBalance.minorUnits > 0 && customer.lastTransactionAt != null)
          if (today.difference(customer.lastTransactionAt!).inDays >= overdueThresholdDays)
            OverdueReminder(
              customerId: customer.customerId,
              customerName: customer.name,
              amountOwed: customer.currentBalance,
              daysOverdue: today.difference(customer.lastTransactionAt!).inDays,
            ),
    ];
    reminders.sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));
    return reminders;
  }
}
