import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/utils/money.dart';
import '../../../../domain/entities/customer.dart';
import '../../../../domain/repositories/customer_repository.dart' show CustomerSort;

/// Data access for the customers table (SRS §8.2.3). Profile fields (name,
/// phone, photos, language) are editable; [current_balance] is not — it is
/// only ever written by [updateCachedBalance], which the KhataRepository
/// calls after recomputing it from khata_entries (SRS §8.3: "the cache is
/// recomputed on every write to that customer's ledger").
class CustomersDao {
  CustomersDao(this._db);

  final DatabaseExecutor _db;

  Future<void> insertCustomer(Customer customer) => _db.insert('customers', customer.toMap());

  Future<Customer?> getById(String customerId) async {
    final rows =
        await _db.query('customers', where: 'customer_id = ?', whereArgs: [customerId], limit: 1);
    return rows.isEmpty ? null : Customer.fromMap(rows.first);
  }

  Future<List<Customer>> getByShop(
    String shopId, {
    CustomerSort sortBy = CustomerSort.highestBalanceFirst,
  }) async {
    final orderBy = switch (sortBy) {
      CustomerSort.highestBalanceFirst => 'current_balance DESC',
      CustomerSort.mostRecentFirst => 'last_transaction_at DESC',
    };
    final rows = await _db.query(
      'customers',
      where: 'shop_id = ?',
      whereArgs: [shopId],
      orderBy: orderBy,
    );
    return rows.map(Customer.fromMap).toList();
  }

  /// Resets `synced` so the Sync Manager (build order step 7) re-pushes the
  /// updated row on its next cycle.
  Future<void> updateProfile(
    String customerId, {
    String? name,
    String? phone,
    String? profilePhotoPath,
    String? cnicPhotoPath,
    AppLocale? preferredLanguage,
  }) {
    final values = <String, Object?>{
      'name': ?name,
      'phone': ?phone,
      'profile_photo_path': ?profilePhotoPath,
      'cnic_photo_path': ?cnicPhotoPath,
      'preferred_language': ?preferredLanguage?.dbCode,
    };
    if (values.isEmpty) return Future.value();
    values['synced'] = 0;
    return _db.update('customers', values, where: 'customer_id = ?', whereArgs: [customerId]);
  }

  /// The only way current_balance/last_transaction_at ever change — always
  /// called with values freshly aggregated from khata_entries, never a
  /// caller-supplied balance. Also resets `synced` since the cached balance
  /// is part of what the Sync Manager pushes for this customer.
  Future<void> updateCachedBalance(
    String customerId, {
    required Money balance,
    DateTime? lastTransactionAt,
  }) {
    return _db.update(
      'customers',
      {
        'current_balance': balance.minorUnits,
        'last_transaction_at': lastTransactionAt?.millisecondsSinceEpoch,
        'synced': 0,
      },
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
  }

  Future<List<Customer>> getUnsynced() async {
    final rows = await _db.query('customers', where: 'synced = 0');
    return rows.map(Customer.fromMap).toList();
  }

  Future<void> markSynced(List<String> customerIds) async {
    if (customerIds.isEmpty) return;
    final placeholders = List.filled(customerIds.length, '?').join(',');
    await _db.update(
      'customers',
      {'synced': 1},
      where: 'customer_id IN ($placeholders)',
      whereArgs: customerIds,
    );
  }

  /// All local primary keys, for the Sync Manager to diff against a pulled
  /// remote collection in one query rather than one existence check per doc.
  Future<Set<String>> getAllIds() async {
    final rows = await _db.query('customers', columns: ['customer_id']);
    return rows.map((r) => r['customer_id']! as String).toSet();
  }
}
