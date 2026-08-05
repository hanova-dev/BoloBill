// Runs on a real device/emulator, same reason as database_test.dart:
// FirestoreSyncService drives real DAOs against the real encrypted SQLCipher
// database. The Firestore side uses fake_cloud_firestore (pure Dart, no
// network/device requirement) so this exercises the actual push/pull logic
// without needing a deployed project or real connectivity.
import 'dart:io';

import 'package:bolobill/core/localization/app_locale.dart';
import 'package:bolobill/core/utils/id_generator.dart';
import 'package:bolobill/core/utils/money.dart';
import 'package:bolobill/data/local/database/app_database.dart';
import 'package:bolobill/data/local/database/daos/bill_items_dao.dart';
import 'package:bolobill/data/local/database/daos/bills_dao.dart';
import 'package:bolobill/data/local/database/daos/customers_dao.dart';
import 'package:bolobill/data/local/database/daos/khata_entries_dao.dart';
import 'package:bolobill/data/local/database/daos/payments_dao.dart';
import 'package:bolobill/data/local/database/daos/receipts_dao.dart';
import 'package:bolobill/data/local/database/daos/shops_dao.dart';
import 'package:bolobill/data/local/database/daos/users_dao.dart';
import 'package:bolobill/data/local/encryption_key_provider.dart';
import 'package:bolobill/data/remote/firestore_sync_service.dart';
import 'package:bolobill/domain/entities/app_user.dart';
import 'package:bolobill/domain/entities/bill.dart';
import 'package:bolobill/domain/entities/bill_item.dart';
import 'package:bolobill/domain/entities/customer.dart';
import 'package:bolobill/domain/entities/enums.dart';
import 'package:bolobill/domain/entities/khata_entry.dart';
import 'package:bolobill/domain/entities/payment.dart';
import 'package:bolobill/domain/entities/receipt.dart';
import 'package:bolobill/domain/entities/shop.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class _Rig {
  _Rig(this.database, this.service, this.shop);

  final AppDatabase database;
  final FirestoreSyncService service;
  final Shop shop;

  ShopsDao get shopsDao => ShopsDao(database.db);
  UsersDao get usersDao => UsersDao(database.db);
  CustomersDao get customersDao => CustomersDao(database.db);
  BillsDao get billsDao => BillsDao(database.db);
  BillItemsDao get billItemsDao => BillItemsDao(database.db);
  KhataEntriesDao get khataEntriesDao => KhataEntriesDao(database.db);
  PaymentsDao get paymentsDao => PaymentsDao(database.db);
  ReceiptsDao get receiptsDao => ReceiptsDao(database.db);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<_Rig> openRig(String dirName, FakeFirebaseFirestore firestore, Shop shop) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, dirName));
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);

    final database = await AppDatabase.open(
      keyProvider: EncryptionKeyProvider(),
      testDirectoryPath: dir.path,
    );
    final service = FirestoreSyncService(
      shopsDao: ShopsDao(database.db),
      usersDao: UsersDao(database.db),
      customersDao: CustomersDao(database.db),
      billsDao: BillsDao(database.db),
      billItemsDao: BillItemsDao(database.db),
      khataEntriesDao: KhataEntriesDao(database.db),
      paymentsDao: PaymentsDao(database.db),
      receiptsDao: ReceiptsDao(database.db),
      db: database.db,
      firestore: firestore,
    );
    return _Rig(database, service, shop);
  }

  testWidgets(
    'push writes every table to Firestore (bills embed their line items) and marks rows synced',
    (tester) async {
      final firestore = FakeFirebaseFirestore();
      final shop = Shop(
        shopId: IdGenerator.newId(),
        ownerPhone: '+923005550001',
        ownerUid: 'owner-uid-1',
        shopName: 'Push Test Store',
        businessType: BusinessType.grocery,
        preferredLanguage: AppLocale.english,
        createdAt: DateTime.now(),
      );
      final rig = await openRig('sync_push_test', firestore, shop);
      addTearDown(rig.database.close);

      await rig.shopsDao.insertShop(shop);
      await rig.usersDao.insertUser(AppUser(
        userId: IdGenerator.newId(),
        shopId: shop.shopId,
        phone: shop.ownerPhone,
        createdAt: DateTime.now(),
      ));
      final customer = Customer(
        customerId: IdGenerator.newId(),
        shopId: shop.shopId,
        name: 'Bilal',
        createdAt: DateTime.now(),
      );
      await rig.customersDao.insertCustomer(customer);

      // A draft bill must NOT be pushed — only confirmed bills are (see
      // BillsDao.getUnsynced).
      final draftBill = Bill(
        billId: IdGenerator.newId(),
        shopId: shop.shopId,
        paymentType: PaymentType.cash,
        createdAt: DateTime.now(),
      );
      await rig.billsDao.insertBill(draftBill);

      final confirmedBill = Bill(
        billId: IdGenerator.newId(),
        shopId: shop.shopId,
        customerId: customer.customerId,
        paymentType: PaymentType.khata,
        totalAmount: Money.fromRupees(300),
        status: BillStatus.confirmed,
        createdAt: DateTime.now(),
      );
      await rig.billsDao.insertBill(confirmedBill);
      final item = BillItem(
        billItemId: IdGenerator.newId(),
        billId: confirmedBill.billId,
        itemNameRaw: 'Rice',
        inputMethod: InputMethod.manual,
        quantity: 1,
        unit: QuantityUnit.kg,
        pricePerUnit: Money.fromRupees(300),
        lineTotal: Money.fromRupees(300),
      );
      await rig.billItemsDao.insertLineItem(item);

      final entry = KhataEntry(
        entryId: IdGenerator.newId(),
        customerId: customer.customerId,
        billId: confirmedBill.billId,
        entryType: KhataEntryType.debit,
        amount: Money.fromRupees(300),
        timestamp: DateTime.now(),
      );
      await rig.khataEntriesDao.insertEntry(entry);
      final payment = Payment(
        paymentId: IdGenerator.newId(),
        customerId: customer.customerId,
        amountReceived: Money.fromRupees(100),
        recordedVia: InputMethod.manual,
        timestamp: DateTime.now(),
        linkedKhataEntryId: entry.entryId,
      );
      await rig.paymentsDao.insertPayment(payment);
      final receipt = Receipt(
        receiptId: IdGenerator.newId(),
        billId: confirmedBill.billId,
        format: ReceiptFormat.image,
        deliveryChannel: DeliveryChannel.whatsapp,
        sentAt: DateTime.now(),
      );
      await rig.receiptsDao.insertReceipt(receipt);

      await rig.service.push(shop.shopId);

      // Remote side has the right shape.
      final shopDoc = await firestore.collection('shops').doc(shop.shopId).get();
      expect(shopDoc.exists, isTrue);
      expect(shopDoc.data()!['owner_uid'], 'owner-uid-1');
      expect(shopDoc.data()!.containsKey('synced'), isFalse,
          reason: 'synced is a local push-tracking flag, never part of the remote document');

      final billsSnapshot =
          await firestore.collection('shops').doc(shop.shopId).collection('bills').get();
      expect(billsSnapshot.docs, hasLength(1), reason: 'the draft bill must not be pushed');
      final pushedBill = billsSnapshot.docs.single;
      expect(pushedBill.id, confirmedBill.billId);
      final pushedItems = pushedBill.data()['items'] as List<dynamic>;
      expect(pushedItems, hasLength(1));
      expect(pushedItems.single['item_name_raw'], 'Rice');

      for (final collection in ['customers', 'khataEntries', 'payments', 'receipts', 'users']) {
        final snapshot =
            await firestore.collection('shops').doc(shop.shopId).collection(collection).get();
        expect(snapshot.docs, hasLength(1), reason: '$collection should have exactly one doc');
      }

      // Local side is marked synced.
      expect((await rig.shopsDao.getById(shop.shopId))!.synced, isTrue);
      expect((await rig.customersDao.getById(customer.customerId))!.synced, isTrue);
      expect((await rig.billsDao.getById(confirmedBill.billId))!.synced, isTrue);
      expect((await rig.billsDao.getById(draftBill.billId))!.synced, isFalse);
      expect(await rig.billsDao.getUnsynced(), isEmpty);
      expect(await rig.khataEntriesDao.getUnsynced(), isEmpty);
      expect(await rig.paymentsDao.getUnsynced(), isEmpty);
      expect(await rig.receiptsDao.getUnsynced(), isEmpty);
    },
  );

  testWidgets(
    'pull inserts rows missing on a second device, embeds items back into '
    'bill_items, and never overwrites a row that already exists locally',
    (tester) async {
      final firestore = FakeFirebaseFirestore();
      final shop = Shop(
        shopId: IdGenerator.newId(),
        ownerPhone: '+923005550002',
        ownerUid: 'owner-uid-2',
        shopName: 'Original Name',
        businessType: BusinessType.teaStall,
        preferredLanguage: AppLocale.english,
        createdAt: DateTime.now(),
      );

      // --- Device A: create data and push it up. ---
      final deviceA = await openRig('sync_pull_device_a', firestore, shop);
      addTearDown(deviceA.database.close);
      await deviceA.shopsDao.insertShop(shop);
      final customer = Customer(
        customerId: IdGenerator.newId(),
        shopId: shop.shopId,
        name: 'Sana',
        createdAt: DateTime.now(),
      );
      await deviceA.customersDao.insertCustomer(customer);
      final bill = Bill(
        billId: IdGenerator.newId(),
        shopId: shop.shopId,
        customerId: customer.customerId,
        paymentType: PaymentType.khata,
        totalAmount: Money.fromRupees(150),
        status: BillStatus.confirmed,
        createdAt: DateTime.now(),
      );
      await deviceA.billsDao.insertBill(bill);
      await deviceA.billItemsDao.insertLineItem(BillItem(
        billItemId: IdGenerator.newId(),
        billId: bill.billId,
        itemNameRaw: 'Sugar',
        inputMethod: InputMethod.manual,
        quantity: 1,
        unit: QuantityUnit.kg,
        pricePerUnit: Money.fromRupees(150),
        lineTotal: Money.fromRupees(150),
      ));
      await deviceA.service.push(shop.shopId);

      // --- Device B: starts empty, pulls. ---
      final deviceB = await openRig('sync_pull_device_b', firestore, shop);
      addTearDown(deviceB.database.close);
      expect(await deviceB.shopsDao.getById(shop.shopId), isNull);

      await deviceB.service.pull(shop.shopId);

      final pulledShop = await deviceB.shopsDao.getById(shop.shopId);
      expect(pulledShop, isNotNull);
      expect(pulledShop!.shopName, 'Original Name');
      expect(pulledShop.synced, isTrue,
          reason: 'a row that came from Firestore is already in sync by definition');

      final pulledCustomer = await deviceB.customersDao.getById(customer.customerId);
      expect(pulledCustomer, isNotNull);
      expect(pulledCustomer!.name, 'Sana');

      final pulledBill = await deviceB.billsDao.getById(bill.billId);
      expect(pulledBill, isNotNull);
      final pulledItems = await deviceB.billItemsDao.getByBill(bill.billId);
      expect(pulledItems, hasLength(1));
      expect(pulledItems.single.itemNameRaw, 'Sugar');
      expect(pulledItems.single.lineTotal, Money.fromRupees(150));

      // --- Device B already has its own (unsynced) edit to the same
      // customer row locally — pulling again must not clobber it, since the
      // conflict policy is "local always wins on this device" (see
      // FirestoreSyncService's class doc).
      await deviceB.customersDao.updateProfile(customer.customerId, name: 'Sana (edited on B)');
      await deviceB.service.pull(shop.shopId);
      final afterSecondPull = await deviceB.customersDao.getById(customer.customerId);
      expect(afterSecondPull!.name, 'Sana (edited on B)');
    },
  );
}
