import '../../../domain/entities/enums.dart';

/// The domain-constrained grammar layer (SRS §12.3) — sits after raw ASR
/// transcription and recognizes the bounded vocabulary this app actually
/// needs (numbers, fractions, units), rather than attempting open-ended
/// language understanding. Word lists below are the "configuration" NFR
/// §10.6 asks to externalize (editable/extensible without touching the
/// parsing algorithm); the algorithm itself is the fixed logic.
///
/// Numeral recognition tries two paths, in order:
/// 1. Digit sequences already in the transcript ("25", "0.5") — Android's
///    on-device recognizers commonly normalize spoken numbers to digits
///    even mid-sentence, in every language, so this is the common case.
/// 2. Spelled-out number/fraction words (Roman Urdu + Urdu script) via the
///    tables below — the fallback for when digits aren't recognized, and
///    the *only* path for fraction words ("adha", "پاؤ"), which are never
///    auto-digitized since they aren't standard numerals.
abstract final class DomainGrammar {
  // ---- Fraction/modifier words -------------------------------------------
  // "sawa" adds 0.25 to the number that follows (or to 1 if none follows);
  // "paune" subtracts 0.25 from the number that follows; "derh"/"dhai" are
  // fixed words for 1.5/2.5 with no following number. Roman Urdu spelling
  // has no single standard, so common variants are listed per concept.
  static const Map<String, double> fixedFractionWords = {
    'adha': 0.5, 'adhaa': 0.5, 'aadha': 0.5, 'آدھا': 0.5,
    'pao': 0.25, 'paw': 0.25, 'پاؤ': 0.25,
    'derh': 1.5, 'dedh': 1.5, 'ڈیڑھ': 1.5,
    'dhai': 2.5, 'ڈھائی': 2.5,
  };

  static const Set<String> sawaModifierWords = {'sawa', 'سوا'};
  static const Set<String> pauneModifierWords = {'paune', 'pauna', 'پونے'};

  // ---- Unit words ---------------------------------------------------------
  static const Map<String, QuantityUnit> unitWords = {
    'kilo': QuantityUnit.kg, 'kg': QuantityUnit.kg, 'کلو': QuantityUnit.kg,
    'gram': QuantityUnit.gram, 'grams': QuantityUnit.gram, 'گرام': QuantityUnit.gram,
    'piece': QuantityUnit.piece, 'pieces': QuantityUnit.piece, 'pc': QuantityUnit.piece,
    'adad': QuantityUnit.piece, 'عدد': QuantityUnit.piece,
    'dozen': QuantityUnit.dozen, 'darjan': QuantityUnit.dozen, 'درجن': QuantityUnit.dozen,
    'litre': QuantityUnit.litre, 'liter': QuantityUnit.litre, 'لیٹر': QuantityUnit.litre,
    'meter': QuantityUnit.meter, 'metre': QuantityUnit.meter, 'میٹر': QuantityUnit.meter,
    // Countable-item units — packaged goods aren't sold by weight, so a
    // retailer saying "1 shampoo ki bottle" or "2 panadol golian" needs a
    // unit slot to land in, not a silent fall-through to a generic "piece".
    'bottle': QuantityUnit.bottle, 'bottles': QuantityUnit.bottle,
    'botal': QuantityUnit.bottle, 'بوتل': QuantityUnit.bottle,
    'tablet': QuantityUnit.tablet, 'tablets': QuantityUnit.tablet, 'tab': QuantityUnit.tablet,
    'goli': QuantityUnit.tablet, 'golian': QuantityUnit.tablet, 'goliyan': QuantityUnit.tablet,
    'گولی': QuantityUnit.tablet, 'گولیاں': QuantityUnit.tablet,
    'strip': QuantityUnit.strip, 'strips': QuantityUnit.strip, 'سٹرپ': QuantityUnit.strip,
    'packet': QuantityUnit.packet, 'packets': QuantityUnit.packet, 'paket': QuantityUnit.packet,
    'پیکٹ': QuantityUnit.packet,
    'box': QuantityUnit.box, 'boxes': QuantityUnit.box,
    'dabba': QuantityUnit.box, 'dabbi': QuantityUnit.box, 'ڈبہ': QuantityUnit.box, 'ڈبی': QuantityUnit.box,
  };

  // ---- Numeral words (1-100), Roman Urdu ----------------------------------
  // Standard Hindi-Urdu spoken numerals, irregular from 21-99 — there is no
  // compositional shortcut, so the fallback path is a direct lookup table.
  static const Map<String, int> numeralWords = {
    'ek': 1, 'do': 2, 'teen': 3, 'chaar': 4, 'char': 4, 'paanch': 5, 'panch': 5,
    'chhay': 6, 'che': 6, 'saat': 7, 'aath': 8, 'nau': 9, 'dus': 10, 'das': 10,
    'gyarah': 11, 'barah': 12, 'tera': 13, 'chauda': 14, 'pandrah': 15,
    'solah': 16, 'satrah': 17, 'atharah': 18, 'unnees': 19, 'bees': 20,
    'ikkees': 21, 'baees': 22, 'teiees': 23, 'chaubees': 24, 'pachees': 25,
    'chhabees': 26, 'sattaees': 27, 'atthaees': 28, 'untees': 29, 'tees': 30,
    'iktees': 31, 'battees': 32, 'taintees': 33, 'chauntees': 34, 'paintees': 35,
    'chhattees': 36, 'saintees': 37, 'adtees': 38, 'untalees': 39, 'chalees': 40,
    'iktalees': 41, 'bayalees': 42, 'taintalees': 43, 'chawalees': 44, 'paintalees': 45,
    'chheyalees': 46, 'saintalees': 47, 'adtalees': 48, 'unchaas': 49, 'pachaas': 50,
    'ikyawan': 51, 'bawan': 52, 'tirpan': 53, 'chauwan': 54, 'pachpan': 55,
    'chhappan': 56, 'sattawan': 57, 'atthawan': 58, 'unsath': 59, 'saath': 60,
    'iksath': 61, 'baasath': 62, 'tirsath': 63, 'chausath': 64, 'painsath': 65,
    'chhiyasath': 66, 'sarsath': 67, 'arsath': 68, 'unhattar': 69, 'sattar': 70,
    'ikhattar': 71, 'bahattar': 72, 'tihattar': 73, 'chauhattar': 74, 'pachhattar': 75,
    'chhihattar': 76, 'satattar': 77, 'athhattar': 78, 'unyasi': 79, 'assi': 80,
    'ikyasi': 81, 'bayasi': 82, 'tirasi': 83, 'chaurasi': 84, 'pachasi': 85,
    'chhiyasi': 86, 'sattasi': 87, 'atthasi': 88, 'nawasi': 89, 'nawway': 90,
    'ikyanway': 91, 'bayanway': 92, 'tiranway': 93, 'chauranway': 94, 'pachanway': 95,
    'chhiyanway': 96, 'sattanway': 97, 'atthanway': 98, 'ninyanway': 99,
    'sau': 100, 'سو': 100,
  };

  static const Set<String> hundredWords = {'sau', 'سو'};
  static const Set<String> thousandWords = {'hazar', 'hazaar', 'ہزار'};

  /// "sawa sau" (125), "dhai sau" (250) etc. are idiomatic — a quarter of
  /// *that specific* round number, not the flat "+0.25" that "sawa"/"dhai"
  /// apply to small numbers ("sawa do" = 2.25, not 2.5). Listed directly
  /// rather than derived, since generalizing the rule would get this wrong.
  static const Map<String, double> compoundHundredWords = {
    'sawa sau': 125, 'سوا سو': 125,
    'derh sau': 150, 'ڈیڑھ سو': 150,
    'dhai sau': 250, 'ڈھائی سو': 250,
    'sawa hazar': 1250, 'سوا ہزار': 1250,
    'derh hazar': 1500, 'ڈیڑھ ہزار': 1500,
    'dhai hazar': 2500, 'ڈھائی ہزار': 2500,
  };

  // ---- Roman Urdu spelling normalization (FR-3.6.5) ------------------------
  // Maps common spelling variants to one canonical token so downstream
  // storage/analytics aren't fragmented by spelling drift.
  static const Map<String, String> spellingVariants = {
    'kitna': 'kitna', 'kitne': 'kitna', 'kithna': 'kitna', 'kitni': 'kitna',
    'rupay': 'rupee', 'rupaye': 'rupee', 'rupees': 'rupee', 'roopay': 'rupee',
    'kilogram': 'kilo', 'killo': 'kilo',
  };

  static String normalize(String word) {
    final lower = word.toLowerCase();
    return spellingVariants[lower] ?? lower;
  }

  static QuantityUnit? parseUnit(String word) => unitWords[normalize(word)];

  /// Parses a single token as a plain integer/decimal — digits only, no
  /// word lookup (see [parseNumberWords] for the spelled-out fallback).
  ///
  /// A token that's *purely* digits always parses. A digit run glued to a
  /// recognized unit word also parses with that suffix stripped — Android's
  /// recognizer sometimes emits "25kg" as one token instead of "25 kg" as
  /// two — but a digit run glued to anything else does not: brand names
  /// routinely embed a digit ("7up", "3M", "5star"), and blindly stripping
  /// every non-digit character used to read the "7" out of "7up" as a real
  /// number, which then got treated as an actual price or quantity next to
  /// a marker word ("7up ki bottle 120 ki" priced itself at Rs. 7 instead of
  /// 120). An unrecognized suffix means this is product-name text, not a
  /// number someone said out loud.
  static double? parseDigits(String token) {
    final trimmed = token.trim();
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(trimmed)) {
      return double.tryParse(trimmed);
    }
    final match = RegExp(r'^(\d+(?:\.\d+)?)([a-zA-Z؀-ۿ]+)$').firstMatch(trimmed);
    if (match != null && unitWords.containsKey(normalize(match.group(2)!))) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Parses a run of number words (e.g. ["teen", "sau"] -> 300,
  /// ["do", "hazar"] -> 2000, ["pachees"] -> 25) starting at [start].
  /// Returns the parsed value and how many tokens were consumed, or null.
  static ({double value, int consumed})? parseNumberWords(List<String> tokens, int start) {
    if (start >= tokens.length) return null;
    final first = normalize(tokens[start]);

    // Idiomatic two-word compounds ("sawa sau", "dhai hazar") take priority
    // over generic composition — see [compoundHundredWords].
    if (start + 1 < tokens.length) {
      final pair = '$first ${normalize(tokens[start + 1])}';
      final compound = compoundHundredWords[pair];
      if (compound != null) return (value: compound, consumed: 2);
    }

    final ones = numeralWords[first];
    if (ones == null) return null;

    // "do sau" (200), "teen hazar" (3000) — multiplier composition.
    if (start + 1 < tokens.length) {
      final next = normalize(tokens[start + 1]);
      if (hundredWords.contains(next) && !hundredWords.contains(first)) {
        return (value: (ones * 100).toDouble(), consumed: 2);
      }
      if (thousandWords.contains(next)) {
        return (value: (ones * 1000).toDouble(), consumed: 2);
      }
    }
    return (value: ones.toDouble(), consumed: 1);
  }
}
