import '../entities/app_user.dart';

/// Shop staff/owner account management (SRS §8.2.2, D3 "Staff Accounts").
abstract interface class UserRepository {
  Future<void> createUser(AppUser user);
  Future<List<AppUser>> getStaffForShop(String shopId);
}
