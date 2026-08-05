// Runs on a real device/emulator (not `flutter test`) because
// sqflite_sqlcipher is a platform-channel plugin backed by the native
// SQLCipher library — there is no host-side FFI variant that understands
// encrypted databases, so this is the only way to genuinely exercise the
// encrypted local database layer end-to-end.
import 'dart:io';

import 'package:bolobill/core/localization/app_locale.dart';
import 'package:bolobill/core/utils/id_generator.dart';
import 'package:bolobill/core/utils/money.dart';
import 'package:bolobill/data/local/database/app_database.dart';
import 'package:bolobill/data/local/database/daos/bill_items_dao.dart';
import 'package:bolobill/data/local/database/daos/bills_dao.dart';
import 'package:bolobill/data/local/database/daos/customers_dao.dart';
import 'package:bolobill/data/local/database/daos/receipts_dao.dart';
import 'package:bolobill/data/local/database/daos/shops_dao.dart';
import 'package:bolobill/data/local/database/daos/users_dao.dart';
import 'package:bolobill/data/local/encryption_key_provider.dart';
import 'package:bolobill/data/repositories/customer_repository_impl.dart';
import 'package:bolobill/data/repositories/khata_repository_impl.dart';
import 'package:bolobill/data/repositories/receipt_repository_impl.dart';
import 'package:bolobill/domain/entities/app_user.dart';
import 'package:bolobill/domain/entities/bill.dart';
import 'package:bolobill/domain/entities/bill_item.dart';
import 'package:bolobill/domain/entities/customer.dart';
import 'package:bolobill/domain/entities/enums.dart';
import 'package:bolobill/domain/entities/receipt.dart';
import 'package:bolobill/domain/entities/shop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' show DatabaseException;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() async {
    // Clean slate every run so tests don't accumulate state across launches.
    final dir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(dir.path, 'bolobill.db'));
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    database = await AppDatabase.open(keyProvider: EncryptionKeyProvider());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('shop round-trip: insert, lookup by id/phone, update language', (tester) async {
    final shopsDao = ShopsDao(database.db);
    final shop = Shop(
      shopId: IdGenerator.newId(),
      ownerPhone: '+923001234567',
      shopName: 'Rahim Grocery Store',
      businessType: BusinessType.grocery,
      preferredLanguage: AppLocale.urdu,
      createdAt: DateTime.now(),
    );
    await shopsDao.insertShop(shop);

    final byId = await shopsDao.getById(shop.shopId);
    expect(byId, isNotNull);
    expect(byId!.shopName, 'Rahim Grocery Store');
    expect(byId.businessType, BusinessType.grocery);
    expect(byId.preferredLanguage, AppLocale.urdu);
    expect(byId.synced, isFalse);

    final byPhone = await shopsDao.getByOwnerPhone('+923001234567');
    expect(byPhone?.shopId, shop.shopId);

    await shopsDao.updatePreferredLanguage(shop.shopId, AppLocale.english);
    expect((await shopsDao.getById(shop.shopId))!.preferredLanguage, AppLocale.english);

    final usersDao = UsersDao(database.db);
    await usersDao.insertUser(AppUser(
      userId: IdGenerator.newId(),
      shopId: shop.shopId,
      phone: '+923001234567',
      createdAt: DateTime.now(),
    ));
    expect(await usersDao.getUsersByShop(shop.shopId), hasLength(1));
  });

  testWidgets(
    'full flow: draft bill -> line-item correction/removal -> confirm -> '
    'khata debit -> partial payment -> balance recompute stays exact',
    (tester) async {
      final shopsDao = ShopsDao(database.db);
      final shop = Shop(
        shopId: IdGenerator.newId(),
        ownerPhone: '+923001111111',
        shopName: 'Test Shop',
        businessType: BusinessType.grocery,
        preferredLanguage: AppLocale.urdu,
        createdAt: DateTime.now(),
      );
      await shopsDao.insertShop(shop);

      final customerRepo = CustomerRepositoryImpl(CustomersDao(database.db));
      final customer = Customer(
        customerId: IdGenerator.newId(),
        shopId: shop.shopId,
        name: 'Ahmed Uncle',
        createdAt: DateTime.now(),
      );
      await customerRepo.createCustomer(customer);

      // --- Draft bill with three line items ---
      final billsDao = BillsDao(database.db);
      final billItemsDao = BillItemsDao(database.db);
      final bill = Bill(
        billId: IdGenerator.newId(),
        shopId: shop.shopId,
        customerId: customer.customerId,
        paymentType: PaymentType.khata,
        createdAt: DateTime.now(),
      );
      await billsDao.insertBill(bill);

      final item1 = BillItem(
        billItemId: IdGenerator.newId(),
        billId: bill.billId,
        itemNameRaw: 'Tea Leaves',
        inputMethod: InputMethod.voice,
        quantity: 0.5,
        unit: QuantityUnit.kg,
        pricePerUnit: Money.fromRupees(400),
        lineTotal: Money.fromRupees(200),
      );
      final item2 = BillItem(
        billItemId: IdGenerator.newId(),
        billId: bill.billId,
        itemNameRaw: 'Cooking Oil',
        inputMethod: InputMethod.manual,
        quantity: 1,
        unit: QuantityUnit.piece,
        pricePerUnit: Money.fromRupees(650),
        lineTotal: Money.fromRupees(650),
      );
      final itemToRemove = BillItem(
        billItemId: IdGenerator.newId(),
        billId: bill.billId,
        itemNameRaw: 'Misheard Item',
        inputMethod: InputMethod.voice,
        quantity: 1,
        unit: QuantityUnit.piece,
        pricePerUnit: Money.fromRupees(50),
        lineTotal: Money.fromRupees(50),
      );
      await billItemsDao.insertLineItem(item1);
      await billItemsDao.insertLineItem(item2);
      await billItemsDao.insertLineItem(itemToRemove);
      expect(await billItemsDao.getByBill(bill.billId), hasLength(3));

      // FR-3.2.8: correct and remove line items before finalizing.
      await billItemsDao.updateLineItem(
        item2.billItemId,
        pricePerUnit: Money.fromRupees(600),
        lineTotal: Money.fromRupees(600),
      );
      await billItemsDao.deleteLineItem(itemToRemove.billItemId);

      final finalItems = await billItemsDao.getByBill(bill.billId);
      expect(finalItems, hasLength(2));
      final correctedItem2 = finalItems.firstWhere((i) => i.billItemId == item2.billItemId);
      expect(correctedItem2.lineTotal, Money.fromRupees(600));

      // --- Jama Karain: calculate, then confirm ---
      final total = finalItems.fold<Money>(Money.zero, (sum, i) => sum + i.lineTotal);
      expect(total, Money.fromRupees(800));

      await billsDao.updateProgress(bill.billId, totalAmount: total, status: BillStatus.calculated);
      await billsDao.updateProgress(bill.billId, totalAmount: total, status: BillStatus.confirmed);
      final confirmedBill = await billsDao.getById(bill.billId);
      expect(confirmedBill!.status, BillStatus.confirmed);
      expect(confirmedBill.totalAmount, Money.fromRupees(800));

      // --- Khata debit posted for the confirmed khata-type bill (FR-3.4.6) ---
      final khataRepo = KhataRepositoryImpl(database.db);
      await khataRepo.postBillDebit(
        customerId: customer.customerId,
        billId: bill.billId,
        amount: total,
      );
      expect(await khataRepo.getBalance(customer.customerId), Money.fromRupees(800));

      // --- Partial payment recorded independently (FR-3.4.7) ---
      await khataRepo.recordPayment(
        customerId: customer.customerId,
        amountReceived: Money.fromRupees(300),
        recordedVia: InputMethod.manual,
      );

      // Balance is exact — proves integer-minor-unit arithmetic, not float.
      expect(await khataRepo.getBalance(customer.customerId), Money.fromRupees(500));

      final ledger = await khataRepo.getLedger(customer.customerId);
      expect(ledger, hasLength(2));
      final debit = ledger.firstWhere((e) => e.entryType == KhataEntryType.debit);
      final credit = ledger.firstWhere((e) => e.entryType == KhataEntryType.credit);
      expect(debit.amount, Money.fromRupees(800));
      expect(debit.billId, bill.billId);
      expect(credit.amount, Money.fromRupees(300));

      final payments = await khataRepo.getPayments(customer.customerId);
      expect(payments, hasLength(1));
      expect(payments.single.linkedKhataEntryId, credit.entryId);

      // customers.current_balance cache matches the ledger sum exactly.
      final refreshedCustomer = await customerRepo.getCustomer(customer.customerId);
      expect(refreshedCustomer!.currentBalance, Money.fromRupees(500));
      expect(refreshedCustomer.lastTransactionAt, isNotNull);

      // --- Receipt logged against the confirmed bill ---
      final receiptRepo = ReceiptRepositoryImpl(ReceiptsDao(database.db));
      await receiptRepo.createReceipt(Receipt(
        receiptId: IdGenerator.newId(),
        billId: bill.billId,
        format: ReceiptFormat.image,
        deliveryChannel: DeliveryChannel.whatsapp,
        sentAt: DateTime.now(),
      ));
      final receipts = await receiptRepo.getReceiptsForBill(bill.billId);
      expect(receipts, hasLength(1));
      expect(receipts.single.deliveryChannel, DeliveryChannel.whatsapp);
    },
  );

  testWidgets('foreign keys are enforced (PRAGMA foreign_keys = ON takes effect)',
      (tester) async {
    final billItemsDao = BillItemsDao(database.db);
    expect(
      () => billItemsDao.insertLineItem(BillItem(
        billItemId: IdGenerator.newId(),
        billId: 'does-not-exist',
        itemNameRaw: 'Orphan Item',
        inputMethod: InputMethod.manual,
        quantity: 1,
        unit: QuantityUnit.piece,
        pricePerUnit: Money.fromRupees(10),
        lineTotal: Money.fromRupees(10),
      )),
      throwsA(isA<DatabaseException>()),
    );
  });

  testWidgets('CHECK constraints reject out-of-range enum values at the DB level',
      (tester) async {
    expect(
      () => database.db.insert('shops', {
        'shop_id': IdGenerator.newId(),
        'owner_phone': '+920000000000',
        'shop_name': 'Invalid Language Shop',
        'business_type': 'grocery',
        'preferred_language': 'klingon', // not in the CHECK constraint's set
        'color_theme_id': 'default',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'synced': 0,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });
}
