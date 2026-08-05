import 'package:bolobill/domain/entities/enums.dart';
import 'package:bolobill/features/voice/slot_parser/slot_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('high-confidence full parses', () {
    test('digit quantity + unit + rupee-marked price', () {
      final parsed = SlotParser.parse('sugar 2 kilo 240 rupee');

      expect(parsed.itemNameRaw, 'sugar');
      expect(parsed.quantity, 2.0);
      expect(parsed.unit, QuantityUnit.kg);
      expect(parsed.pricePerUnit.rupees, 240.0);
      expect(parsed.needsConfirmation, isFalse);
    });

    test('spelled-out numeral quantity', () {
      final parsed = SlotParser.parse('rice paanch kilo 150 rupee');

      expect(parsed.itemNameRaw, 'rice');
      expect(parsed.quantity, 5.0);
      expect(parsed.unit, QuantityUnit.kg);
      expect(parsed.pricePerUnit.rupees, 150.0);
    });

    test('fixed-fraction quantity word ("adha kilo" = 0.5kg)', () {
      final parsed = SlotParser.parse('atta adha kilo 60 rupee');

      expect(parsed.itemNameRaw, 'atta');
      expect(parsed.quantity, 0.5);
      expect(parsed.quantityConfidence, greaterThanOrEqualTo(0.9));
    });

    test('sawa-modified quantity ("sawa do kilo" = 2.25kg)', () {
      final parsed = SlotParser.parse('cheeni sawa do kilo 300 rupee');

      expect(parsed.quantity, 2.25);
    });

    test('paune-modified quantity ("paune teen kilo" = 2.75kg)', () {
      final parsed = SlotParser.parse('daal paune teen kilo 400 rupee');

      expect(parsed.quantity, 2.75);
    });

    test('bare sawa/paune modifier with implied "1" before the unit', () {
      expect(SlotParser.parse('doodh sawa kilo 100 rupee').quantity, 1.25);
      expect(SlotParser.parse('doodh paune kilo 100 rupee').quantity, 0.75);
    });

    test('compound hundred price ("dhai sau rupee" = Rs 250)', () {
      final parsed = SlotParser.parse('oil 1 litre dhai sau rupee');

      expect(parsed.pricePerUnit.rupees, 250.0);
    });

    test('multi-word item name is preserved when quantity/price are found', () {
      final parsed = SlotParser.parse('basmati chawal 5 kilo 200 rupee');

      expect(parsed.itemNameRaw, 'basmati chawal');
    });

    test('Urdu-script transcript parses identically to its Roman Urdu equivalent', () {
      final parsed = SlotParser.parse('چینی 2 کلو 240 روپے');

      expect(parsed.quantity, 2.0);
      expect(parsed.unit, QuantityUnit.kg);
      expect(parsed.pricePerUnit.rupees, 240.0);
    });
  });

  group('low-confidence / ambiguous parses that must trip the confidence gate', () {
    test('unit spoken with no quantity defaults to 1 but is flagged', () {
      final parsed = SlotParser.parse('cooking oil litre 300 rupee');

      expect(parsed.quantity, 1.0);
      expect(parsed.quantityConfidence, 0.6);
      expect(parsed.needsConfirmation, isTrue);
    });

    test('a bare number with no rupee marker is never guessed as a price', () {
      final parsed = SlotParser.parse('sugar 2 kilo 240');

      expect(parsed.priceConfidence, 0.0);
      expect(parsed.pricePerUnit.rupees, 0.0);
      expect(parsed.needsConfirmation, isTrue);
    });

    test('a bare number with no unit is never guessed as a quantity', () {
      final parsed = SlotParser.parse('sugar 2 240 rupee');

      expect(parsed.quantityConfidence, 0.0);
      expect(parsed.needsConfirmation, isTrue);
    });

    test('whole transcript recognized as nothing but a name gets low confidence', () {
      final parsed = SlotParser.parse('cheeni');

      expect(parsed.itemNameRaw, 'cheeni');
      expect(parsed.itemNameConfidence, 0.3);
      expect(parsed.needsConfirmation, isTrue);
    });

    test('empty transcript yields an empty, unconfirmable parse', () {
      final parsed = SlotParser.parse('   ');

      expect(parsed.itemNameRaw, '');
      expect(parsed.itemNameConfidence, 0.0);
      expect(parsed.needsConfirmation, isTrue);
    });
  });

  group('withAsrConfidence — folding the recognizer\'s own confidence into the gate', () {
    test('a missing ASR confidence (-1, the package\'s "not supplied" sentinel) leaves the parse untouched', () {
      final parsed = SlotParser.parse('sugar 2 kilo 240 rupee');
      final adjusted = SlotParser.withAsrConfidence(parsed, -1);

      expect(adjusted.quantityConfidence, parsed.quantityConfidence);
      expect(adjusted.priceConfidence, parsed.priceConfidence);
      expect(adjusted.itemNameConfidence, parsed.itemNameConfidence);
      expect(adjusted.needsConfirmation, isFalse);
    });

    test('a high ASR confidence barely changes an otherwise-clean parse', () {
      final parsed = SlotParser.parse('sugar 2 kilo 240 rupee');
      final adjusted = SlotParser.withAsrConfidence(parsed, 0.95);

      expect(adjusted.needsConfirmation, isFalse);
    });

    test('a noisy/low ASR confidence forces confirmation even when every field parsed cleanly', () {
      // Every field here would independently pass the 0.7 gate on grammar
      // alone — this is exactly the case the parser/grammar layer can't
      // catch by itself: a confident-looking parse of a recognition the
      // engine itself was unsure about (background noise, mumbled speech).
      final parsed = SlotParser.parse('sugar 2 kilo 240 rupee');
      expect(parsed.needsConfirmation, isFalse, reason: 'sanity check: grammar alone says confident');

      final adjusted = SlotParser.withAsrConfidence(parsed, 0.3);

      expect(adjusted.needsConfirmation, isTrue);
    });

    test('scales every field proportionally, not just one', () {
      final parsed = SlotParser.parse('sugar 2 kilo 240 rupee');
      final adjusted = SlotParser.withAsrConfidence(parsed, 0.5);

      expect(adjusted.itemNameConfidence, closeTo(parsed.itemNameConfidence * 0.5, 1e-9));
      expect(adjusted.quantityConfidence, closeTo(parsed.quantityConfidence * 0.5, 1e-9));
      expect(adjusted.priceConfidence, closeTo(parsed.priceConfidence * 0.5, 1e-9));
    });

    test('an already-low-confidence grammar parse stays unconfirmable regardless of ASR confidence', () {
      final parsed = SlotParser.parse('cheeni');
      final adjusted = SlotParser.withAsrConfidence(parsed, 1.0);

      expect(adjusted.needsConfirmation, isTrue);
    });

    test('parsed field values themselves (name/quantity/unit/price) are never altered, only confidences', () {
      final parsed = SlotParser.parse('sugar 2 kilo 240 rupee');
      final adjusted = SlotParser.withAsrConfidence(parsed, 0.3);

      expect(adjusted.itemNameRaw, parsed.itemNameRaw);
      expect(adjusted.quantity, parsed.quantity);
      expect(adjusted.unit, parsed.unit);
      expect(adjusted.pricePerUnit, parsed.pricePerUnit);
    });
  });
}
