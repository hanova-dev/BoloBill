import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../domain/entities/shop.dart';

/// Data access for the shops table (SRS §8.2.1). One row per shop; there is
/// no delete path — shops are never removed, matching the fact that no
/// deletion functionality is described anywhere in the SRS.
class ShopsDao {
  ShopsDao(this._db);

  final DatabaseExecutor _db;

  Future<void> insertShop(Shop shop) => _db.insert('shops', shop.toMap());

  Future<Shop?> getById(String shopId) async {
    final rows = await _db.query('shops', where: 'shop_id = ?', whereArgs: [shopId], limit: 1);
    return rows.isEmpty ? null : Shop.fromMap(rows.first);
  }

  /// One shop per device/install (SRS §9.1) — used at app startup to resume
  /// straight into billing on a device that's already been set up, instead
  /// of re-running onboarding every launch.
  Future<Shop?> getFirst() async {
    final rows = await _db.query('shops', limit: 1);
    return rows.isEmpty ? null : Shop.fromMap(rows.first);
  }

  /// Used to detect an existing account during phone-OTP sign-in (FR-3.1.2).
  Future<Shop?> getByOwnerPhone(String ownerPhone) async {
    final rows =
        await _db.query('shops', where: 'owner_phone = ?', whereArgs: [ownerPhone], limit: 1);
    return rows.isEmpty ? null : Shop.fromMap(rows.first);
  }

  /// FR-3.6.1: shop-level default language, changeable any time from settings.
  /// Resets `synced` so the Sync Manager (build order step 7) re-pushes the
  /// updated row on its next cycle.
  Future<void> updatePreferredLanguage(String shopId, AppLocale language) => _db.update(
        'shops',
        {'preferred_language': language.dbCode, 'synced': 0},
        where: 'shop_id = ?',
        whereArgs: [shopId],
      );

  Future<List<Shop>> getUnsynced() async {
    final rows = await _db.query('shops', where: 'synced = 0');
    return rows.map(Shop.fromMap).toList();
  }

  Future<void> markSynced(List<String> shopIds) async {
    if (shopIds.isEmpty) return;
    final placeholders = List.filled(shopIds.length, '?').join(',');
    await _db.update(
      'shops',
      {'synced': 1},
      where: 'shop_id IN ($placeholders)',
      whereArgs: shopIds,
    );
  }
}
