import '../../core/localization/app_locale.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repositories/shop_repository.dart';
import '../local/database/daos/shops_dao.dart';

class ShopRepositoryImpl implements ShopRepository {
  ShopRepositoryImpl(this._dao);

  final ShopsDao _dao;

  @override
  Future<void> createShop(Shop shop) => _dao.insertShop(shop);

  @override
  Future<Shop?> getShop(String shopId) => _dao.getById(shopId);

  @override
  Future<Shop?> findByOwnerPhone(String ownerPhone) => _dao.getByOwnerPhone(ownerPhone);

  @override
  Future<Shop?> getLocalShop() => _dao.getFirst();

  @override
  Future<void> updatePreferredLanguage(String shopId, AppLocale language) =>
      _dao.updatePreferredLanguage(shopId, language);
}
