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

  group('colloquial "ki"/"ka" price markers (real-device retailer testing)', () {
    test('"ki" with no unit spoken at all — flat-priced item, no quantity word', () {
      final parsed = SlotParser.parse('cheeni 200 ki');

      expect(parsed.itemNameRaw, 'cheeni');
      expect(parsed.pricePerUnit.rupees, 200.0);
      expect(parsed.priceConfidence, greaterThanOrEqualTo(0.9));
      // No unit was spoken, which for a flat-priced item means one of it —
      // see the flat/package pricing group below. (This originally asserted
      // a zero-confidence quantity that forced a confirm tap; that was the
      // behavior retailers reported as broken for fixed-rate items.)
      expect(parsed.quantity, 1.0);
      expect(parsed.needsConfirmation, isFalse);
    });

    test('"ka" before the item name, with a descriptive (color) word kept as part of it', () {
      final parsed = SlotParser.parse('200 ka kala saban');

      expect(parsed.itemNameRaw, 'kala saban');
      expect(parsed.pricePerUnit.rupees, 200.0);
    });

    test(
      '"ki" combined with a real unit and fraction word parses as a fully clean '
      'auto-fill, with the spoken number treated as a TOTAL for that quantity '
      '(400 for half a kilo = Rs 800/kg, not Rs 400/kg)',
      () {
        final parsed = SlotParser.parse('adha kilo kali pati 400 ki');

        expect(parsed.itemNameRaw, 'kali pati');
        expect(parsed.quantity, 0.5);
        expect(parsed.unit, QuantityUnit.kg);
        expect(parsed.pricePerUnit.rupees, 800.0);
        expect(parsed.needsConfirmation, isFalse);
      },
    );

    test('a stray "ki" with no adjacent number is left in the item name, not treated as a price', () {
      final parsed = SlotParser.parse('yeh dukaan ki cheeni hai');

      expect(parsed.priceConfidence, 0.0);
      expect(parsed.itemNameRaw, contains('ki'));
    });

    test('"ke" is recognized alongside "ki"/"ka"', () {
      final parsed = SlotParser.parse('ek dozen anday 350 ke');

      expect(parsed.itemNameRaw, 'anday');
      expect(parsed.unit, QuantityUnit.dozen);
      expect(parsed.pricePerUnit.rupees, 350.0);
      expect(parsed.needsConfirmation, isFalse);
    });

    test('a brand name with an embedded digit ("7up") does not get misread as a price', () {
      final parsed = SlotParser.parse('7up ki bottle 120 ki');

      expect(parsed.pricePerUnit.rupees, 120.0);
      expect(parsed.itemNameRaw, contains('7up'));
    });
  });

  group('"ki"-marked total price after an explicit quantity (real retailer report)', () {
    test(
      '"chinni 5 kilo 500 ki" resolves to Rs 100/kg — retailer confirmed 500 was '
      'the TOTAL for 5kg (500 / 5 = a clean 100), not a per-kg rate',
      () {
        final parsed = SlotParser.parse('chinni 5 kilo 500 ki');

        expect(parsed.itemNameRaw, 'chinni');
        expect(parsed.quantity, 5.0);
        expect(parsed.unit, QuantityUnit.kg);
        expect(parsed.pricePerUnit.rupees, 100.0);
        expect(parsed.needsConfirmation, isFalse);
      },
    );

    test(
      'the same total-price division applies to the Urdu-script equivalent',
      () {
        final parsed = SlotParser.parse('چینی 5 کلو 500 کی');

        expect(parsed.quantity, 5.0);
        expect(parsed.pricePerUnit.rupees, 100.0);
      },
    );

    test(
      'the unadorned "rupee" word is left alone — only the genitive particles '
      '("ki"/"ka"/"ke"/"kay") are read as a total, since "<qty> <unit> <price> '
      'rupee" is a separately-established, already-relied-upon pattern',
      () {
        final parsed = SlotParser.parse('chinni 5 kilo 500 rupee');

        expect(parsed.quantity, 5.0);
        expect(parsed.pricePerUnit.rupees, 500.0);
      },
    );
  });

  group('flat / package pricing — no unit word spoken at all', () {
    test('a flat-priced packaged item auto-fills as one piece without a confirm tap', () {
      final parsed = SlotParser.parse('shampoo 600 ka');

      expect(parsed.itemNameRaw, 'shampoo');
      expect(parsed.quantity, 1.0);
      expect(parsed.unit, QuantityUnit.piece);
      expect(parsed.pricePerUnit.rupees, 600.0);
      expect(parsed.needsConfirmation, isFalse);
    });

    test('a leading count is taken as the quantity instead of leaking into the name', () {
      final parsed = SlotParser.parse('1 bari bottle shampoo 600 ki');

      expect(parsed.itemNameRaw, 'bari bottle shampoo');
      expect(parsed.quantity, 1.0);
      expect(parsed.pricePerUnit.rupees, 600.0);
      expect(parsed.needsConfirmation, isFalse);
    });

    test('a medical-store style flat price parses cleanly', () {
      final parsed = SlotParser.parse('panadol 30 ka patta');

      expect(parsed.itemNameRaw, 'panadol patta');
      expect(parsed.pricePerUnit.rupees, 30.0);
      expect(parsed.needsConfirmation, isFalse);
    });

    test('a stray leftover number keeps the line unconfirmed rather than guessing one', () {
      // "2" could be a count, a pack size, or part of the product name —
      // assuming a quantity of 1 here would quietly record the wrong number.
      final parsed = SlotParser.parse('sugar 2 240 rupee');

      expect(parsed.quantityConfidence, 0.0);
      expect(parsed.needsConfirmation, isTrue);
    });
  });

  group('countable-item units (packaged goods aren\'t sold by weight)', () {
    test(
      'a number immediately before a countable unit parses as a clean quantity+unit, '
      'with the "ki"-marked price treated as a TOTAL for both bottles (100 / 2 = Rs 50 each)',
      () {
        final parsed = SlotParser.parse('2 bottle chai 100 ki');

        expect(parsed.quantity, 2.0);
        expect(parsed.unit, QuantityUnit.bottle);
        expect(parsed.pricePerUnit.rupees, 50.0);
        expect(parsed.needsConfirmation, isFalse);
      },
    );

    test(
      '"golian" (tablets) directly after a leading count parses as tablet unit, '
      'with the "ki"-marked price treated as a TOTAL for both tablets (20 / 2 = Rs 10 each)',
      () {
        final parsed = SlotParser.parse('2 golian panadol 20 ki');

        expect(parsed.quantity, 2.0);
        expect(parsed.unit, QuantityUnit.tablet);
        expect(parsed.itemNameRaw, 'panadol');
        expect(parsed.pricePerUnit.rupees, 10.0);
        expect(parsed.needsConfirmation, isFalse);
      },
    );

    test(
      'a countable-unit word with no adjacent number stays in the item name '
      'instead of hijacking the flat-price leading-count fallback '
      '(regression: "1 bari bottle shampoo 600 ki" is a real reported retailer phrase)',
      () {
        final parsed = SlotParser.parse('1 bari bottle shampoo 600 ki');

        expect(parsed.itemNameRaw, 'bari bottle shampoo');
        expect(parsed.quantity, 1.0);
        expect(parsed.pricePerUnit.rupees, 600.0);
        expect(parsed.needsConfirmation, isFalse);
      },
    );
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
