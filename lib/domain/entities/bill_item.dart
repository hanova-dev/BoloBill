import 'package:flutter/foundation.dart';

import '../../core/utils/money.dart';
import 'enums.dart';

/// bill_items (SRS §8.2.5) — a freeform line item, no product catalog
/// reference (SRS §2.5). [quantity] is a plain double (not minor-unit scaled
/// like money): it's a per-line measurement, not a value summed across many
/// records the way monetary fields are, so REAL precision to 3 decimal
/// places (matching DECIMAL(10,3)) is more than sufficient for a shop scale.
@immutable
class BillItem {
  const BillItem({
    required this.billItemId,
    required this.billId,
    required this.itemNameRaw,
    required this.inputMethod,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.lineTotal,
  });

  final String billItemId;
  final String billId;
  final String itemNameRaw;
  final InputMethod inputMethod;
  final double quantity;
  final QuantityUnit unit;

  /// Snapshot at time of sale — never recomputed from a later price change
  /// for the same freeform item name (SRS §8.3).
  final Money pricePerUnit;
  final Money lineTotal;

  Map<String, Object?> toMap() => {
        'bill_item_id': billItemId,
        'bill_id': billId,
        'item_name_raw': itemNameRaw,
        'input_method': inputMethod.dbValue,
        'quantity': quantity,
        'unit': unit.dbValue,
        'price_per_unit': pricePerUnit.minorUnits,
        'line_total': lineTotal.minorUnits,
      };

  static BillItem fromMap(Map<String, Object?> map) => BillItem(
        billItemId: map['bill_item_id']! as String,
        billId: map['bill_id']! as String,
        itemNameRaw: map['item_name_raw']! as String,
        inputMethod: InputMethod.fromDb(map['input_method']! as String),
        quantity: (map['quantity']! as num).toDouble(),
        unit: QuantityUnit.fromDb(map['unit']! as String),
        pricePerUnit: Money.fromMinorUnits(map['price_per_unit']! as int),
        lineTotal: Money.fromMinorUnits(map['line_total']! as int),
      );
}
