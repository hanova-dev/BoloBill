import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../../domain/entities/app_user.dart';

/// Data access for the users table (SRS §8.2.2) — shop staff/owner accounts,
/// surfaced in the D3 Settings "Staff Accounts" row.
class UsersDao {
  UsersDao(this._db);

  final DatabaseExecutor _db;

  Future<void> insertUser(AppUser user) => _db.insert('users', user.toMap());

  Future<List<AppUser>> getUsersByShop(String shopId) async {
    final rows = await _db.query('users', where: 'shop_id = ?', whereArgs: [shopId]);
    return rows.map(AppUser.fromMap).toList();
  }

  Future<List<AppUser>> getUnsynced() async {
    final rows = await _db.query('users', where: 'synced = 0');
    return rows.map(AppUser.fromMap).toList();
  }

  Future<void> markSynced(List<String> userIds) async {
    if (userIds.isEmpty) return;
    final placeholders = List.filled(userIds.length, '?').join(',');
    await _db.update('users', {'synced': 1}, where: 'user_id IN ($placeholders)', whereArgs: userIds);
  }

  /// All local primary keys, for the Sync Manager to diff against a pulled
  /// remote collection in one query rather than one existence check per doc.
  Future<Set<String>> getAllIds() async {
    final rows = await _db.query('users', columns: ['user_id']);
    return rows.map((r) => r['user_id']! as String).toSet();
  }
}
