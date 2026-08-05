import 'package:flutter/foundation.dart';

import '../../../core/utils/money.dart';
import '../../../domain/entities/enums.dart';

/// The output of [SlotParser] — a candidate line item plus per-field
/// confidence, which the confidence gate (SRS §12.5) uses to decide
/// whether the retailer must tap to confirm before it's added to the bill.
@immutable
class ParsedLineItem {
  const ParsedLineItem({
    required this.itemNameRaw,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.itemNameConfidence,
    required this.quantityConfidence,
    required this.priceConfidence,
  });

  final String itemNameRaw;
  final double quantity;
  final QuantityUnit unit;
  final Money pricePerUnit;

  final double itemNameConfidence;
  final double quantityConfidence;
  final double priceConfidence;

  Money get lineTotal => pricePerUnit * quantity;

  /// The weakest of the three per-field scores — SRS §12.5: "each
  /// voice-parsed line item carries a confidence score", singular; the
  /// whole line is only as trustworthy as its least-certain field.
  double get overallConfidence =>
      [itemNameConfidence, quantityConfidence, priceConfidence].reduce((a, b) => a < b ? a : b);

  static const confidenceThreshold = 0.7;

  bool get needsConfirmation => overallConfidence < confidenceThreshold;
}
