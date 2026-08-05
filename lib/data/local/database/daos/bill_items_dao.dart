import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../../core/utils/money.dart';
import '../../../../domain/entities/bill_item.dart';
import '../../../../domain/entities/enums.dart';

/// Data access for the bill_items table (SRS §8.2.5).
///
/// [updateLineItem]/[deleteLineItem] exist to satisfy FR-3.2.8 ("allow
/// deletion or correction of any line item before the bill is finalized") —
/// they are only valid while the parent bill is still Draft/Calculated
/// (never synced yet). The Bill Engine (step 4) must stop calling them once
/// the parent bill reaches [BillStatus.confirmed], at which point bill_items
/// become as append-only as the bill itself (FR-3.7.4).
class BillItemsDao {
  BillItemsDao(this._db);

  final DatabaseExecutor _db;

  Future<void> insertLineItem(BillItem item) => _db.insert('bill_items', item.toMap());

  Future<List<BillItem>> getByBill(String billId) async {
    final rows = await _db.query('bill_items', where: 'bill_id = ?', whereArgs: [billId]);
    return rows.map(BillItem.fromMap).toList();
  }

  Future<void> updateLineItem(
    String billItemId, {
    String? itemNameRaw,
    double? quantity,
    QuantityUnit? unit,
    Money? pricePerUnit,
    Money? lineTotal,
  }) {
    final values = <String, Object?>{
      'item_name_raw': ?itemNameRaw,
      'quantity': ?quantity,
      'unit': ?unit?.dbValue,
      'price_per_unit': ?pricePerUnit?.minorUnits,
      'line_total': ?lineTotal?.minorUnits,
    };
    if (values.isEmpty) return Future.value();
    return _db.update('bill_items', values, where: 'bill_item_id = ?', whereArgs: [billItemId]);
  }

  Future<void> deleteLineItem(String billItemId) =>
      _db.delete('bill_items', where: 'bill_item_id = ?', whereArgs: [billItemId]);
}
