import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../../domain/entities/payment.dart';

/// Data access for the payments table (SRS §8.2.7) — append-only, no update
/// or delete: a payment is a record of money physically received.
class PaymentsDao {
  PaymentsDao(this._db);

  final DatabaseExecutor _db;

  Future<void> insertPayment(Payment payment) => _db.insert('payments', payment.toMap());

  Future<List<Payment>> getByCustomer(String customerId) async {
    final rows = await _db.query(
      'payments',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'timestamp DESC',
    );
    return rows.map(Payment.fromMap).toList();
  }

  Future<List<Payment>> getUnsynced() async {
    final rows = await _db.query('payments', where: 'synced = 0');
    return rows.map(Payment.fromMap).toList();
  }

  Future<void> markSynced(List<String> paymentIds) async {
    if (paymentIds.isEmpty) return;
    final placeholders = List.filled(paymentIds.length, '?').join(',');
    await _db.update(
      'payments',
      {'synced': 1},
      where: 'payment_id IN ($placeholders)',
      whereArgs: paymentIds,
    );
  }

  /// All local primary keys, for the Sync Manager to diff against a pulled
  /// remote collection in one query rather than one existence check per doc.
  Future<Set<String>> getAllIds() async {
    final rows = await _db.query('payments', columns: ['payment_id']);
    return rows.map((r) => r['payment_id']! as String).toSet();
  }
}
