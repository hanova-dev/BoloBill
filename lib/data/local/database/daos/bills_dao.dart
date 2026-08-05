import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../../core/utils/money.dart';
import '../../../../domain/entities/bill.dart';
import '../../../../domain/entities/enums.dart';

/// Data access for the bills table (SRS §8.2.4).
///
/// [updateProgress] is the only mutation and exists solely to carry a bill
/// through Draft → Calculated → Confirmed (SRS §7.4) before it is ever
/// synced. Per FR-3.7.4 ("never editing a synced record in place"), the Bill
/// Engine (build order step 4) must not call this once a bill's status is
/// already [BillStatus.confirmed] — corrections after that point are new
/// offsetting bills, not edits to this row.
class BillsDao {
  BillsDao(this._db);

  final DatabaseExecutor _db;

  Future<void> insertBill(Bill bill) => _db.insert('bills', bill.toMap());

  Future<Bill?> getById(String billId) async {
    final rows = await _db.query('bills', where: 'bill_id = ?', whereArgs: [billId], limit: 1);
    return rows.isEmpty ? null : Bill.fromMap(rows.first);
  }

  Future<List<Bill>> getByShop(String shopId) async {
    final rows = await _db.query(
      'bills',
      where: 'shop_id = ?',
      whereArgs: [shopId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Bill.fromMap).toList();
  }

  Future<List<Bill>> getByCustomer(String customerId) async {
    final rows = await _db.query(
      'bills',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Bill.fromMap).toList();
  }

  Future<void> updateProgress(
    String billId, {
    required Money totalAmount,
    required BillStatus status,
  }) {
    return _db.update(
      'bills',
      {'total_amount': totalAmount.minorUnits, 'status': status.dbValue},
      where: 'bill_id = ?',
      whereArgs: [billId],
    );
  }

  /// Only confirmed bills are ever synced (SRS §7.4/§5.3) — a draft or
  /// calculated bill is transient in-progress state on this device, not yet
  /// the immutable snapshot the Sync Manager (build order step 7) pushes.
  Future<List<Bill>> getUnsynced() async {
    final rows = await _db.query(
      'bills',
      where: "synced = 0 AND status = 'confirmed'",
    );
    return rows.map(Bill.fromMap).toList();
  }

  Future<void> markSynced(List<String> billIds) async {
    if (billIds.isEmpty) return;
    final placeholders = List.filled(billIds.length, '?').join(',');
    await _db.update('bills', {'synced': 1}, where: 'bill_id IN ($placeholders)', whereArgs: billIds);
  }

  /// All local primary keys, for the Sync Manager to diff against a pulled
  /// remote collection in one query rather than one existence check per doc.
  Future<Set<String>> getAllIds() async {
    final rows = await _db.query('bills', columns: ['bill_id']);
    return rows.map((r) => r['bill_id']! as String).toSet();
  }
}
