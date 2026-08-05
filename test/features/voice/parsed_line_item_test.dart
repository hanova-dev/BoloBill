import 'package:bolobill/core/utils/money.dart';
import 'package:bolobill/domain/entities/enums.dart';
import 'package:bolobill/features/voice/slot_parser/parsed_line_item.dart';
import 'package:flutter_test/flutter_test.dart';

ParsedLineItem _item({
  double itemNameConfidence = 0.9,
  double quantityConfidence = 0.9,
  double priceConfidence = 0.9,
}) {
  return ParsedLineItem(
    itemNameRaw: 'sugar',
    quantity: 2,
    unit: QuantityUnit.kg,
    pricePerUnit: Money.fromRupees(240),
    itemNameConfidence: itemNameConfidence,
    quantityConfidence: quantityConfidence,
    priceConfidence: priceConfidence,
  );
}

void main() {
  group('overallConfidence', () {
    test('is the minimum of the three field scores, not an average', () {
      final item = _item(itemNameConfidence: 0.9, quantityConfidence: 0.95, priceConfidence: 0.4);
      expect(item.overallConfidence, 0.4);
    });

    test('all-high fields yield a high overall score', () {
      final item = _item(itemNameConfidence: 0.9, quantityConfidence: 0.9, priceConfidence: 0.9);
      expect(item.overallConfidence, 0.9);
    });
  });

  group('needsConfirmation gate at threshold 0.7', () {
    test('does not require confirmation when every field is at or above threshold', () {
      final item = _item(itemNameConfidence: 0.9, quantityConfidence: 0.7, priceConfidence: 0.9);
      expect(item.needsConfirmation, isFalse);
    });

    test('requires confirmation when exactly one field is below threshold', () {
      final item = _item(itemNameConfidence: 0.9, quantityConfidence: 0.9, priceConfidence: 0.6);
      expect(item.needsConfirmation, isTrue);
    });

    test('requires confirmation when every field is below threshold', () {
      final item = _item(itemNameConfidence: 0.3, quantityConfidence: 0.0, priceConfidence: 0.0);
      expect(item.needsConfirmation, isTrue);
    });
  });

  test('lineTotal multiplies price per unit by quantity', () {
    final item = _item();
    expect(item.lineTotal, Money.fromRupees(480));
  });
}
