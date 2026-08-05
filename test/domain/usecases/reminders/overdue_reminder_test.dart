import 'package:bolobill/core/utils/money.dart';
import 'package:bolobill/domain/entities/customer.dart';
import 'package:bolobill/domain/usecases/reminders/overdue_reminder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 4);

  Customer customer({
    required String id,
    required String name,
    required Money balance,
    DateTime? lastTransactionAt,
  }) {
    return Customer(
      customerId: id,
      shopId: 'shop-1',
      name: name,
      currentBalance: balance,
      createdAt: now.subtract(const Duration(days: 100)),
      lastTransactionAt: lastTransactionAt,
    );
  }

  group('OverdueReminders.evaluate', () {
    test('flags a customer whose balance is owed and last activity is exactly 30 days old', () {
      final customers = [
        customer(
          id: 'c1',
          name: 'Salman Khan',
          balance: Money.fromRupees(2100),
          lastTransactionAt: now.subtract(const Duration(days: 30)),
        ),
      ];

      final reminders = OverdueReminders.evaluate(customers, now: now);

      expect(reminders, hasLength(1));
      expect(reminders.single.customerId, 'c1');
      expect(reminders.single.customerName, 'Salman Khan');
      expect(reminders.single.amountOwed, Money.fromRupees(2100));
      expect(reminders.single.daysOverdue, 30);
    });

    test('does not flag a customer whose last activity is only 29 days old', () {
      final customers = [
        customer(
          id: 'c1',
          name: 'Ahmed Uncle',
          balance: Money.fromRupees(850),
          lastTransactionAt: now.subtract(const Duration(days: 29)),
        ),
      ];

      expect(OverdueReminders.evaluate(customers, now: now), isEmpty);
    });

    test('does not flag a customer who is settled (zero balance) no matter how stale', () {
      final customers = [
        customer(
          id: 'c1',
          name: 'Settled Sana',
          balance: Money.zero,
          lastTransactionAt: now.subtract(const Duration(days: 200)),
        ),
      ];

      expect(OverdueReminders.evaluate(customers, now: now), isEmpty);
    });

    test('does not flag a customer the shop owes money to (negative balance)', () {
      final customers = [
        customer(
          id: 'c1',
          name: 'Overpaid Omar',
          balance: Money.fromRupees(-500),
          lastTransactionAt: now.subtract(const Duration(days: 200)),
        ),
      ];

      expect(OverdueReminders.evaluate(customers, now: now), isEmpty);
    });

    test('does not flag a customer with a balance but no recorded activity at all', () {
      final customers = [
        customer(id: 'c1', name: 'No History', balance: Money.fromRupees(500)),
      ];

      expect(OverdueReminders.evaluate(customers, now: now), isEmpty);
    });

    test('sorts most-overdue first', () {
      final customers = [
        customer(
          id: 'c1',
          name: 'Thirty Days',
          balance: Money.fromRupees(100),
          lastTransactionAt: now.subtract(const Duration(days: 30)),
        ),
        customer(
          id: 'c2',
          name: 'Ninety Days',
          balance: Money.fromRupees(200),
          lastTransactionAt: now.subtract(const Duration(days: 90)),
        ),
        customer(
          id: 'c3',
          name: 'Forty Days',
          balance: Money.fromRupees(300),
          lastTransactionAt: now.subtract(const Duration(days: 40)),
        ),
      ];

      final reminders = OverdueReminders.evaluate(customers, now: now);

      expect(reminders.map((r) => r.customerId), ['c2', 'c3', 'c1']);
    });

    test('an empty customer list yields no reminders', () {
      expect(OverdueReminders.evaluate(const [], now: now), isEmpty);
    });

    test('a mixed list only flags the customers that qualify', () {
      final customers = [
        customer(
          id: 'overdue',
          name: 'Overdue',
          balance: Money.fromRupees(500),
          lastTransactionAt: now.subtract(const Duration(days: 45)),
        ),
        customer(
          id: 'recent',
          name: 'Recent',
          balance: Money.fromRupees(500),
          lastTransactionAt: now.subtract(const Duration(days: 5)),
        ),
        customer(
          id: 'settled',
          name: 'Settled',
          balance: Money.zero,
          lastTransactionAt: now.subtract(const Duration(days: 45)),
        ),
      ];

      final reminders = OverdueReminders.evaluate(customers, now: now);

      expect(reminders.map((r) => r.customerId), ['overdue']);
    });
  });
}
