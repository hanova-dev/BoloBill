import '../../core/localization/app_locale.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../local/database/daos/customers_dao.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl(this._dao);

  final CustomersDao _dao;

  @override
  Future<void> createCustomer(Customer customer) => _dao.insertCustomer(customer);

  @override
  Future<Customer?> getCustomer(String customerId) => _dao.getById(customerId);

  @override
  Future<List<Customer>> getCustomersForShop(
    String shopId, {
    CustomerSort sortBy = CustomerSort.highestBalanceFirst,
  }) =>
      _dao.getByShop(shopId, sortBy: sortBy);

  @override
  Future<void> updateProfile(
    String customerId, {
    String? name,
    String? phone,
    String? profilePhotoPath,
    String? cnicPhotoPath,
    AppLocale? preferredLanguage,
  }) =>
      _dao.updateProfile(
        customerId,
        name: name,
        phone: phone,
        profilePhotoPath: profilePhotoPath,
        cnicPhotoPath: cnicPhotoPath,
        preferredLanguage: preferredLanguage,
      );
}
