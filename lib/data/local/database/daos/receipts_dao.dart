import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../../domain/entities/receipt.dart';

/// Data access for the receipts table (SRS §8.2.8) — append-only: a receipt
/// row logs a delivery event and is never edited after creation.
class ReceiptsDao {
  ReceiptsDao(this._db);

  final DatabaseExecutor _db;

  Future<void> insertReceipt(Receipt receipt) => _db.insert('receipts', receipt.toMap());

  Future<List<Receipt>> getByBill(String billId) async {
    final rows = await _db.query('receipts', where: 'bill_id = ?', whereArgs: [billId]);
    return rows.map(Receipt.fromMap).toList();
  }

  Future<List<Receipt>> getUnsynced() async {
    final rows = await _db.query('receipts', where: 'synced = 0');
    return rows.map(Receipt.fromMap).toList();
  }

  Future<void> markSynced(List<String> receiptIds) async {
    if (receiptIds.isEmpty) return;
    final placeholders = List.filled(receiptIds.length, '?').join(',');
    await _db.update(
      'receipts',
      {'synced': 1},
      where: 'receipt_id IN ($placeholders)',
      whereArgs: receiptIds,
    );
  }

  /// All local primary keys, for the Sync Manager to diff against a pulled
  /// remote collection in one query rather than one existence check per doc.
  Future<Set<String>> getAllIds() async {
    final rows = await _db.query('receipts', columns: ['receipt_id']);
    return rows.map((r) => r['receipt_id']! as String).toSet();
  }
}
