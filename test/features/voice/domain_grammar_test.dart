import 'package:bolobill/domain/entities/enums.dart';
import 'package:bolobill/features/voice/grammar/domain_grammar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalize', () {
    test('maps spelling variants to a single canonical token', () {
      expect(DomainGrammar.normalize('rupaye'), 'rupee');
      expect(DomainGrammar.normalize('roopay'), 'rupee');
      expect(DomainGrammar.normalize('killo'), 'kilo');
      expect(DomainGrammar.normalize('kithna'), 'kitna');
    });

    test('is case-insensitive and passes through unknown words unchanged', () {
      expect(DomainGrammar.normalize('CHEENI'), 'cheeni');
      expect(DomainGrammar.normalize('Kilo'), 'kilo');
    });
  });

  group('parseUnit', () {
    test('recognizes Roman Urdu, English, and Urdu-script unit words', () {
      expect(DomainGrammar.parseUnit('kilo'), QuantityUnit.kg);
      expect(DomainGrammar.parseUnit('kg'), QuantityUnit.kg);
      expect(DomainGrammar.parseUnit('کلو'), QuantityUnit.kg);
      expect(DomainGrammar.parseUnit('darjan'), QuantityUnit.dozen);
      expect(DomainGrammar.parseUnit('عدد'), QuantityUnit.piece);
    });

    test('returns null for non-unit words', () {
      expect(DomainGrammar.parseUnit('cheeni'), isNull);
    });
  });

  group('parseDigits', () {
    test('parses plain integer and decimal digit tokens', () {
      expect(DomainGrammar.parseDigits('25'), 25.0);
      expect(DomainGrammar.parseDigits('0.5'), 0.5);
    });

    test('strips stray non-digit characters and parses what remains', () {
      expect(DomainGrammar.parseDigits('25kg'), 25.0);
    });

    test('returns null when there are no digits at all', () {
      expect(DomainGrammar.parseDigits('teen'), isNull);
    });
  });

  group('parseNumberWords — single-word irregular numerals', () {
    test('looks up small numbers directly (no compositional rule below 100)', () {
      expect(DomainGrammar.parseNumberWords(['ek'], 0), (value: 1.0, consumed: 1));
      expect(DomainGrammar.parseNumberWords(['pachees'], 0), (value: 25.0, consumed: 1));
      expect(DomainGrammar.parseNumberWords(['ninyanway'], 0), (value: 99.0, consumed: 1));
    });

    test('returns null for a word not in the numeral table', () {
      expect(DomainGrammar.parseNumberWords(['cheeni'], 0), isNull);
    });

    test('returns null past the end of the token list', () {
      expect(DomainGrammar.parseNumberWords(['ek'], 5), isNull);
    });
  });

  group('parseNumberWords — hundred/thousand composition', () {
    test('composes "<digit> sau" as digit * 100', () {
      expect(DomainGrammar.parseNumberWords(['teen', 'sau'], 0), (value: 300.0, consumed: 2));
      expect(DomainGrammar.parseNumberWords(['do', 'hazar'], 0), (value: 2000.0, consumed: 2));
    });

    test('"sau" alone (100) does not also try to compose with itself', () {
      expect(DomainGrammar.parseNumberWords(['sau'], 0), (value: 100.0, consumed: 1));
    });
  });

  group('parseNumberWords — idiomatic compounds take priority over composition', () {
    test('"sawa sau" is 125, not the flat +0.25 applied to 100', () {
      expect(DomainGrammar.parseNumberWords(['sawa', 'sau'], 0), (value: 125.0, consumed: 2));
    });

    test('"dhai sau" is 250, not a compositional "2.5 * 100"', () {
      expect(DomainGrammar.parseNumberWords(['dhai', 'sau'], 0), (value: 250.0, consumed: 2));
    });

    test('"derh hazar" is 1500', () {
      expect(DomainGrammar.parseNumberWords(['derh', 'hazar'], 0), (value: 1500.0, consumed: 2));
    });

    test('Urdu-script compounds resolve identically to their Roman Urdu counterparts', () {
      expect(DomainGrammar.parseNumberWords(['سوا', 'سو'], 0), (value: 125.0, consumed: 2));
      expect(DomainGrammar.parseNumberWords(['ڈھائی', 'ہزار'], 0), (value: 2500.0, consumed: 2));
    });
  });

  test('fixedFractionWords carries the four standard fraction terms in both scripts', () {
    expect(DomainGrammar.fixedFractionWords['adha'], 0.5);
    expect(DomainGrammar.fixedFractionWords['pao'], 0.25);
    expect(DomainGrammar.fixedFractionWords['derh'], 1.5);
    expect(DomainGrammar.fixedFractionWords['dhai'], 2.5);
    expect(DomainGrammar.fixedFractionWords['آدھا'], 0.5);
  });
}
