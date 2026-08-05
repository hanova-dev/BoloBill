import '../../domain/entities/app_user.dart';
import '../../domain/repositories/user_repository.dart';
import '../local/database/daos/users_dao.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._dao);

  final UsersDao _dao;

  @override
  Future<void> createUser(AppUser user) => _dao.insertUser(user);

  @override
  Future<List<AppUser>> getStaffForShop(String shopId) => _dao.getUsersByShop(shopId);
}
