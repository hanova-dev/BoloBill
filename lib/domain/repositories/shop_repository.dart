import '../../core/localization/app_locale.dart';
import '../entities/shop.dart';

/// Shop profile creation and lookup (SRS §9.1 Bill Engine surface / module 3.1).
abstract interface class ShopRepository {
  Future<void> createShop(Shop shop);
  Future<Shop?> getShop(String shopId);

  /// Used during phone sign-in to detect an existing account (FR-3.1.2).
  Future<Shop?> findByOwnerPhone(String ownerPhone);

  /// FR-3.6.1: changeable at any time from settings.
  Future<void> updatePreferredLanguage(String shopId, AppLocale language);
}
