import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database/app_database.dart';
import '../../data/local/database/daos/bill_items_dao.dart';
import '../../data/local/database/daos/bills_dao.dart';
import '../../data/local/database/daos/customers_dao.dart';
import '../../data/local/database/daos/khata_entries_dao.dart';
import '../../data/local/database/daos/payments_dao.dart';
import '../../data/local/database/daos/receipts_dao.dart';
import '../../data/local/database/daos/shops_dao.dart';
import '../../data/local/database/daos/users_dao.dart';
import '../../data/remote/firestore_sync_service.dart';
import '../../data/repositories/bill_repository_impl.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../data/repositories/firebase_auth_repository_impl.dart';
import '../../data/repositories/khata_repository_impl.dart';
import '../../data/repositories/receipt_repository_impl.dart';
import '../../data/repositories/shop_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/bill_repository.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/khata_repository.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../../domain/repositories/shop_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../features/notifications/application/local_notifications_service.dart';
import '../../features/notifications/application/reminders_checker.dart';
import '../sync/sync_manager.dart';
import '../sync/sync_status.dart';

/// The single open [AppDatabase] connection, provided as a value override
/// from `main()` once `AppDatabase.open()` resolves — every other provider
/// in this file derives from it, so nothing downstream needs to be async.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden in main()'),
);

final shopsDaoProvider = Provider((ref) => ShopsDao(ref.watch(appDatabaseProvider).db));
final usersDaoProvider = Provider((ref) => UsersDao(ref.watch(appDatabaseProvider).db));
final customersDaoProvider = Provider((ref) => CustomersDao(ref.watch(appDatabaseProvider).db));
final billsDaoProvider = Provider((ref) => BillsDao(ref.watch(appDatabaseProvider).db));
final billItemsDaoProvider = Provider((ref) => BillItemsDao(ref.watch(appDatabaseProvider).db));
final khataEntriesDaoProvider =
    Provider((ref) => KhataEntriesDao(ref.watch(appDatabaseProvider).db));
final paymentsDaoProvider = Provider((ref) => PaymentsDao(ref.watch(appDatabaseProvider).db));

final shopRepositoryProvider =
    Provider<ShopRepository>((ref) => ShopRepositoryImpl(ref.watch(shopsDaoProvider)));
final userRepositoryProvider =
    Provider<UserRepository>((ref) => UserRepositoryImpl(ref.watch(usersDaoProvider)));
final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => CustomerRepositoryImpl(ref.watch(customersDaoProvider)),
);
final billRepositoryProvider = Provider<BillRepository>(
  (ref) => BillRepositoryImpl(ref.watch(appDatabaseProvider).db),
);
final khataRepositoryProvider = Provider<KhataRepository>(
  (ref) => KhataRepositoryImpl(ref.watch(appDatabaseProvider).db),
);
final receiptsDaoProvider = Provider((ref) => ReceiptsDao(ref.watch(appDatabaseProvider).db));
final receiptRepositoryProvider = Provider<ReceiptRepository>(
  (ref) => ReceiptRepositoryImpl(ref.watch(receiptsDaoProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) => FirebaseAuthRepository());

/// The signed-in shop for this session (SRS: one shop per device/install).
/// Set once by [OnboardingController.completeOnboarding]; billing/khata
/// screens read it to scope every query. A full "does a shop already exist"
/// resume-without-onboarding check at app startup is a known gap — see the
/// step 4 summary — this only covers the shop created in the current run.
final currentShopProvider = StateProvider<Shop?>((ref) => null);

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final firestoreSyncServiceProvider = Provider<FirestoreSyncService>(
  (ref) => FirestoreSyncService(
    shopsDao: ref.watch(shopsDaoProvider),
    usersDao: ref.watch(usersDaoProvider),
    customersDao: ref.watch(customersDaoProvider),
    billsDao: ref.watch(billsDaoProvider),
    billItemsDao: ref.watch(billItemsDaoProvider),
    khataEntriesDao: ref.watch(khataEntriesDaoProvider),
    paymentsDao: ref.watch(paymentsDaoProvider),
    receiptsDao: ref.watch(receiptsDaoProvider),
    db: ref.watch(appDatabaseProvider).db,
    firestore: ref.watch(firestoreProvider),
  ),
);

/// Kept alive by a `ref.watch` in [BillingHomeScreen] (build order step 3's
/// post-onboarding home, always on screen whenever a shop exists) so the
/// connectivity/shop listeners it sets up in its constructor stay active for
/// the life of the app rather than only while D3 Settings happens to be open.
final syncManagerProvider = StateNotifierProvider<SyncManager, SyncStatus>(
  (ref) => SyncManager(ref, ref.watch(firestoreSyncServiceProvider), ref.watch(connectivityProvider)),
);

final localNotificationsServiceProvider =
    Provider<LocalNotificationsService>((ref) => LocalNotificationsService());

/// Kept alive the same way as [syncManagerProvider] — a `ref.watch` in
/// [BillingHomeScreen] — so the once-a-day overdue check actually runs
/// rather than only existing when something happens to read it.
final remindersCheckerProvider = Provider<RemindersChecker>((ref) {
  final checker = RemindersChecker(ref, ref.watch(localNotificationsServiceProvider));
  ref.onDispose(checker.dispose);
  return checker;
});
