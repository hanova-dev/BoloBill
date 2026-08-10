import '../../core/localization/app_locale.dart';
import '../entities/shop.dart';

/// Shop profile creation and lookup (SRS §9.1 Bill Engine surface / module 3.1).
abstract interface class ShopRepository {
  Future<void> createShop(Shop shop);
  Future<Shop?> getShop(String shopId);

  /// Used during phone sign-in to detect an existing account (FR-3.1.2).
  Future<Shop?> findByOwnerPhone(String ownerPhone);

  /// The device's already-onboarded shop, if any (one shop per device/
  /// install — SRS §9.1). Used at app startup to skip onboarding and resume
  /// straight into billing.
  Future<Shop?> getLocalShop();

  /// Looks up an existing shop in Firestore by the signed-in Firebase uid
  /// that owns it, and — if found — inserts it locally and returns it. Used
  /// right after a fresh sign-in (Google or phone) on a device with no
  /// local shop yet, so a reinstall or new device recognizes an existing
  /// account and skips onboarding-from-scratch instead of silently creating
  /// a second, disconnected shop for the same person. Requires the
  /// Firestore security rules to actually be deployed (see firestore.rules)
  /// — until then this always effectively returns null (permission-denied
  /// is treated as "nothing found", not an error, so a fresh sign-up still
  /// works normally).
  Future<Shop?> restoreFromCloud(String ownerUid);

  /// FR-3.6.1: changeable at any time from settings.
  Future<void> updatePreferredLanguage(String shopId, AppLocale language);
}
