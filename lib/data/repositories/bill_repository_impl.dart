import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../domain/entities/bill.dart';
import '../../domain/entities/bill_item.dart';
import '../../domain/repositories/bill_repository.dart';
import '../local/database/daos/bill_items_dao.dart';
import '../local/database/daos/bills_dao.dart';

class BillRepositoryImpl implements BillRepository {
  BillRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<void> createConfirmedBill(Bill bill, List<BillItem> items) async {
    await _db.transaction((txn) async {
      await BillsDao(txn).insertBill(bill);
      final itemsDao = BillItemsDao(txn);
      for (final item in items) {
        await itemsDao.insertLineItem(item);
      }
    });
  }

  @override
  Future<Bill?> getBill(String billId) => BillsDao(_db).getById(billId);

  @override
  Future<List<Bill>> getBillsForShop(String shopId) => BillsDao(_db).getByShop(shopId);

  @override
  Future<List<Bill>> getBillsForCustomer(String customerId) =>
      BillsDao(_db).getByCustomer(customerId);

  @override
  Future<List<BillItem>> getLineItems(String billId) => BillItemsDao(_db).getByBill(billId);
}
