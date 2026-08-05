import '../../core/localization/app_locale.dart';
import '../entities/customer.dart';

/// How the C1 photo grid / C5 khata list order customers (FR-3.4.4).
enum CustomerSort { highestBalanceFirst, mostRecentFirst }

/// Customer profile management (SRS §9.1 Khata Engine: createCustomer() /
/// getCustomerList()). Balance mutation is deliberately absent from this
/// interface — see [KhataRepository], the only place a balance may change.
abstract interface class CustomerRepository {
  Future<void> createCustomer(Customer customer);
  Future<Customer?> getCustomer(String customerId);

  Future<List<Customer>> getCustomersForShop(
    String shopId, {
    CustomerSort sortBy = CustomerSort.highestBalanceFirst,
  });

  Future<void> updateProfile(
    String customerId, {
    String? name,
    String? phone,
    String? profilePhotoPath,
    String? cnicPhotoPath,
    AppLocale? preferredLanguage,
  });
}
