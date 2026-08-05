import 'package:flutter/foundation.dart';

import '../../../core/utils/id_generator.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/enums.dart';

/// A line item still being drafted — no `billId` yet, because the `bills`
/// row doesn't exist until confirmation (see the `BillRepository` doc
/// comment on [createConfirmedBill]). [localId] is only for list
/// add/remove/update within this session, never persisted.
@immutable
class DraftLineItem {
  DraftLineItem({
    required this.itemNameRaw,
    required this.inputMethod,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    String? localId,
  }) : localId = localId ?? IdGenerator.newId();

  final String localId;
  final String itemNameRaw;
  final InputMethod inputMethod;
  final double quantity;
  final QuantityUnit unit;
  final Money pricePerUnit;

  Money get lineTotal => pricePerUnit * quantity;

  DraftLineItem copyWith({
    String? itemNameRaw,
    InputMethod? inputMethod,
    double? quantity,
    QuantityUnit? unit,
    Money? pricePerUnit,
  }) {
    return DraftLineItem(
      localId: localId,
      itemNameRaw: itemNameRaw ?? this.itemNameRaw,
      inputMethod: inputMethod ?? this.inputMethod,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
    );
  }
}
