import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/localization/app_locale.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repositories/shop_repository.dart';
import '../local/database/daos/shops_dao.dart';

class ShopRepositoryImpl implements ShopRepository {
  ShopRepositoryImpl(this._dao, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final ShopsDao _dao;
  final FirebaseFirestore _firestore;

  @override
  Future<void> createShop(Shop shop) => _dao.insertShop(shop);

  @override
  Future<Shop?> getShop(String shopId) => _dao.getById(shopId);

  @override
  Future<Shop?> findByOwnerPhone(String ownerPhone) => _dao.getByOwnerPhone(ownerPhone);

  @override
  Future<Shop?> getLocalShop() => _dao.getFirst();

  @override
  Future<Shop?> restoreFromCloud(String ownerUid) async {
    try {
      final snapshot = await _firestore
          .collection('shops')
          .where('owner_uid', isEqualTo: ownerUid)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      // A row read back from Firestore is, by definition, already synced
      // from this device's perspective — same convention as
      // FirestoreSyncService's pull side.
      final shop = Shop.fromMap({...snapshot.docs.first.data(), 'synced': 1});
      await _dao.insertShop(shop);
      return shop;
    } catch (_) {
      // Covers permission-denied (rules not deployed yet — see
      // ShopRepository.restoreFromCloud's doc comment), offline, or any
      // other transient failure. None of these should block sign-in; they
      // just mean "nothing to restore right now," same as a genuinely new
      // account.
      return null;
    }
  }

  @override
  Future<void> updatePreferredLanguage(String shopId, AppLocale language) =>
      _dao.updatePreferredLanguage(shopId, language);
}
