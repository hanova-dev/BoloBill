import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../../core/utils/money.dart';
import '../../../../domain/entities/khata_entry.dart';

/// Aggregate result backing the "current_balance is a cached, derived value"
/// rule in SRS §8.3 — the authoritative balance is always this sum, never a
/// directly editable field (FR-3.4.8).
class CustomerLedgerSummary {
  const CustomerLedgerSummary({required this.balance, this.lastTransactionAt});

  final Money balance;
  final DateTime? lastTransactionAt;
}

/// Data access for the khata_entries table (SRS §8.2.6) — genuinely
/// append-only, per FR-3.4.8/FR-3.7.4: there is no update or delete method
/// on this DAO, full stop. Corrections are new offsetting entries.
class KhataEntriesDao {
  KhataEntriesDao(this._db);

  final DatabaseExecutor _db;

  Future<void> insertEntry(KhataEntry entry) => _db.insert('khata_entries', entry.toMap());

  /// Chronological ledger for a customer's full itemized history (FR-3.4.9).
  Future<List<KhataEntry>> getByCustomer(String customerId) async {
    final rows = await _db.query(
      'khata_entries',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'timestamp DESC',
    );
    return rows.map(KhataEntry.fromMap).toList();
  }

  /// debits minus credits, aggregated directly in SQL so the sum is exact
  /// (no intermediate float/Dart-side accumulation across many rows).
  Future<CustomerLedgerSummary> summarizeForCustomer(String customerId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN entry_type = 'debit' THEN amount ELSE -amount END), 0) AS balance,
        MAX(timestamp) AS last_transaction_at
      FROM khata_entries
      WHERE customer_id = ?
      ''',
      [customerId],
    );
    final row = rows.first;
    final lastTransactionAtMillis = row['last_transaction_at'] as int?;
    return CustomerLedgerSummary(
      balance: Money.fromMinorUnits(row['balance']! as int),
      lastTransactionAt: lastTransactionAtMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastTransactionAtMillis),
    );
  }

  Future<List<KhataEntry>> getUnsynced() async {
    final rows = await _db.query('khata_entries', where: 'synced = 0');
    return rows.map(KhataEntry.fromMap).toList();
  }

  Future<void> markSynced(List<String> entryIds) async {
    if (entryIds.isEmpty) return;
    final placeholders = List.filled(entryIds.length, '?').join(',');
    await _db.update(
      'khata_entries',
      {'synced': 1},
      where: 'entry_id IN ($placeholders)',
      whereArgs: entryIds,
    );
  }

  /// All local primary keys, for the Sync Manager to diff against a pulled
  /// remote collection in one query rather than one existence check per doc.
  Future<Set<String>> getAllIds() async {
    final rows = await _db.query('khata_entries', columns: ['entry_id']);
    return rows.map((r) => r['entry_id']! as String).toSet();
  }
}
