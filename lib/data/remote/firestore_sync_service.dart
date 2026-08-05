import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/bill.dart';
import '../../domain/entities/bill_item.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/khata_entry.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/entities/shop.dart';
import '../local/database/daos/bill_items_dao.dart';
import '../local/database/daos/bills_dao.dart';
import '../local/database/daos/customers_dao.dart';
import '../local/database/daos/khata_entries_dao.dart';
import '../local/database/daos/payments_dao.dart';
import '../local/database/daos/receipts_dao.dart';
import '../local/database/daos/shops_dao.dart';
import '../local/database/daos/users_dao.dart';
import 'firestore_paths.dart';

/// Batched push/pull against Firestore for one shop (SRS §5.3), driven
/// entirely by each table's `synced` flag — see db_schema.dart. This class
/// never touches connectivity or scheduling (that's [SyncManager]'s job in
/// core/sync/); it is a pure "given a shopId, move rows" worker so it can be
/// unit-tested against `fake_cloud_firestore` without a real device.
///
/// Conflict policy (SRS §5.3 "union, no field merge"): every table here is
/// either genuinely append-only (bills — confirmed only, khata_entries,
/// payments, receipts, users) where a client-generated UUID means "push" is
/// really "create if the remote doesn't already have it" and no conflict can
/// occur, or mutable-but-single-owner (shops, customers) where push always
/// fully overwrites the remote doc (no field-level merge) and pull only
/// inserts a row that doesn't exist locally yet — it never overwrites local
/// state, so an offline edit already made on this device is never clobbered
/// by a stale remote copy. This is deliberately simple: the SRS assumes one
/// shop per device/install, so real concurrent-edit conflicts aren't a
/// scenario this MVP needs to resolve.
class FirestoreSyncService {
  FirestoreSyncService({
    required this.shopsDao,
    required this.usersDao,
    required this.customersDao,
    required this.billsDao,
    required this.billItemsDao,
    required this.khataEntriesDao,
    required this.paymentsDao,
    required this.receiptsDao,
    required Database db,
    FirebaseFirestore? firestore,
  })  : _db = db,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _paths = FirestorePaths(_firestore);
  }

  final ShopsDao shopsDao;
  final UsersDao usersDao;
  final CustomersDao customersDao;
  final BillsDao billsDao;
  final BillItemsDao billItemsDao;
  final KhataEntriesDao khataEntriesDao;
  final PaymentsDao paymentsDao;
  final ReceiptsDao receiptsDao;
  final Database _db;
  final FirebaseFirestore _firestore;
  late final FirestorePaths _paths;

  /// Firestore batched writes cap at 500 ops; chunked well under that so a
  /// single shop's backlog never trips the limit even with headroom.
  static const int _batchSize = 400;

  Future<void> push(String shopId) async {
    await _pushSimple<Shop>(
      rows: await shopsDao.getUnsynced(),
      toMap: (s) => s.toMap(),
      idOf: (s) => s.shopId,
      docFor: (s) => _paths.shop(s.shopId),
      markSynced: shopsDao.markSynced,
    );
    await _pushSimple<AppUser>(
      rows: await usersDao.getUnsynced(),
      toMap: (u) => u.toMap(),
      idOf: (u) => u.userId,
      collection: _paths.users(shopId),
      markSynced: usersDao.markSynced,
    );
    await _pushSimple<Customer>(
      rows: await customersDao.getUnsynced(),
      toMap: (c) => c.toMap(),
      idOf: (c) => c.customerId,
      collection: _paths.customers(shopId),
      markSynced: customersDao.markSynced,
    );
    await _pushBills(shopId);
    await _pushSimple<KhataEntry>(
      rows: await khataEntriesDao.getUnsynced(),
      toMap: (e) => e.toMap(),
      idOf: (e) => e.entryId,
      collection: _paths.khataEntries(shopId),
      markSynced: khataEntriesDao.markSynced,
    );
    await _pushSimple<Payment>(
      rows: await paymentsDao.getUnsynced(),
      toMap: (p) => p.toMap(),
      idOf: (p) => p.paymentId,
      collection: _paths.payments(shopId),
      markSynced: paymentsDao.markSynced,
    );
    await _pushSimple<Receipt>(
      rows: await receiptsDao.getUnsynced(),
      toMap: (r) => r.toMap(),
      idOf: (r) => r.receiptId,
      collection: _paths.receipts(shopId),
      markSynced: receiptsDao.markSynced,
    );
  }

  Future<void> pull(String shopId) async {
    final shopDoc = await _paths.shop(shopId).get();
    if (shopDoc.exists && await shopsDao.getById(shopId) == null) {
      await shopsDao.insertShop(Shop.fromMap(_asLocal(shopDoc.data()!)));
    }

    await _pullSimple<AppUser>(
      collection: _paths.users(shopId),
      localIds: await usersDao.getAllIds(),
      fromMap: AppUser.fromMap,
      insert: usersDao.insertUser,
    );
    await _pullSimple<Customer>(
      collection: _paths.customers(shopId),
      localIds: await customersDao.getAllIds(),
      fromMap: Customer.fromMap,
      insert: customersDao.insertCustomer,
    );
    await _pullBills(shopId);
    await _pullSimple<KhataEntry>(
      collection: _paths.khataEntries(shopId),
      localIds: await khataEntriesDao.getAllIds(),
      fromMap: KhataEntry.fromMap,
      insert: khataEntriesDao.insertEntry,
    );
    await _pullSimple<Payment>(
      collection: _paths.payments(shopId),
      localIds: await paymentsDao.getAllIds(),
      fromMap: Payment.fromMap,
      insert: paymentsDao.insertPayment,
    );
    await _pullSimple<Receipt>(
      collection: _paths.receipts(shopId),
      localIds: await receiptsDao.getAllIds(),
      fromMap: Receipt.fromMap,
      insert: receiptsDao.insertReceipt,
    );
  }

  Future<void> _pushBills(String shopId) async {
    final bills = await billsDao.getUnsynced();
    for (final chunk in _chunks(bills, _batchSize)) {
      final batch = _firestore.batch();
      for (final bill in chunk) {
        final items = await billItemsDao.getByBill(bill.billId);
        final payload = bill.toMap()..remove('synced');
        payload['items'] = items.map((item) => item.toMap()).toList();
        batch.set(_paths.bills(shopId).doc(bill.billId), payload);
      }
      await batch.commit();
      await billsDao.markSynced(chunk.map((b) => b.billId).toList());
    }
  }

  Future<void> _pullBills(String shopId) async {
    final snapshot = await _paths.bills(shopId).get();
    final localIds = await billsDao.getAllIds();
    for (final doc in snapshot.docs) {
      if (localIds.contains(doc.id)) continue;
      final data = _asLocal(doc.data());
      final rawItems = (data.remove('items') as List<Object?>? ?? const []);
      final bill = Bill.fromMap(data);
      await _db.transaction((txn) async {
        await BillsDao(txn).insertBill(bill);
        final itemsDao = BillItemsDao(txn);
        for (final rawItem in rawItems) {
          final itemMap = Map<String, dynamic>.from(rawItem! as Map);
          await itemsDao.insertLineItem(BillItem.fromMap(itemMap));
        }
      });
    }
  }

  Future<void> _pushSimple<T>({
    required List<T> rows,
    required Map<String, dynamic> Function(T row) toMap,
    required String Function(T row) idOf,
    required Future<void> Function(List<String> ids) markSynced,
    CollectionReference<Map<String, dynamic>>? collection,
    DocumentReference<Map<String, dynamic>> Function(T row)? docFor,
  }) async {
    for (final chunk in _chunks(rows, _batchSize)) {
      final batch = _firestore.batch();
      for (final row in chunk) {
        final payload = toMap(row)..remove('synced');
        final ref = docFor != null ? docFor(row) : collection!.doc(idOf(row));
        batch.set(ref, payload);
      }
      await batch.commit();
      await markSynced(chunk.map(idOf).toList());
    }
  }

  Future<void> _pullSimple<T>({
    required CollectionReference<Map<String, dynamic>> collection,
    required Set<String> localIds,
    required T Function(Map<String, dynamic> map) fromMap,
    required Future<void> Function(T row) insert,
  }) async {
    final snapshot = await collection.get();
    for (final doc in snapshot.docs) {
      if (localIds.contains(doc.id)) continue;
      await insert(fromMap(_asLocal(doc.data())));
    }
  }

  /// A row pulled from Firestore is, by definition, already synced from this
  /// device's perspective — the push side strips `synced` entirely before
  /// writing (it is a local push-tracking flag, not part of the domain
  /// document), so the pull side fills it back in as 1 before handing the
  /// map to the entity's `fromMap`.
  Map<String, dynamic> _asLocal(Map<String, dynamic> remote) =>
      Map<String, dynamic>.from(remote)..['synced'] = 1;

  Iterable<List<T>> _chunks<T>(List<T> items, int size) sync* {
    for (var i = 0; i < items.length; i += size) {
      yield items.sublist(i, i + size > items.length ? items.length : i + size);
    }
  }
}
