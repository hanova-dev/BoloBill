import '../../../core/utils/money.dart';
import '../../../domain/entities/enums.dart';
import '../grammar/domain_grammar.dart';
import 'parsed_line_item.dart';

/// Splits a grammar-corrected transcript into the three fields the Bill
/// Engine needs (SRS §12.2 layer 4, FR-3.2.2): item name, quantity+unit,
/// and price. Scans for a unit-anchored quantity phrase and a rupee-
/// anchored price phrase; whatever tokens neither phrase consumes become
/// the item name. Deliberately requires an explicit rupee word ("rupee"/
/// "روپے") to recognize a price — a bare number with no marker is exactly
/// the kind of ambiguity the confidence gate (§12.5) exists to catch,
/// rather than a case to guess at silently.
abstract final class SlotParser {
  static const _rupeeWords = {
    'rupee', 'rupya', 'rupye', 'rupaye', 'rs', 'روپے', 'روپیہ',
  };

  /// Colloquial Urdu genitive particles — "200 *ki*", "600 *ka*" — are how
  /// a price actually gets said out loud far more often than an explicit
  /// "rupee"/"rupya" (confirmed by on-device retailer testing: none of
  /// "cheeni 200 ki", "200 ka kala saban", "kali pati 400 ki" say "rupee"
  /// at all — every one of them would previously parse to Rs. 0). Unlike
  /// [_rupeeWords], "ki"/"ka" are common short words elsewhere in Urdu too
  /// (possessives, unrelated phrases), so — unlike the unconditional
  /// consume-on-sight below for the unambiguous rupee words — one of these
  /// is only treated as a price marker, and only removed from the item
  /// name, when a number actually sits immediately before it. A stray
  /// "ki"/"ka" with nothing to anchor it is left alone as ordinary name
  /// text rather than assumed to be about price.
  static const _genitivePriceWords = {'ki', 'ka', 'ke', 'kay', 'کی', 'کا', 'کے'};

  static ParsedLineItem parse(String rawTranscript) {
    final trimmed = rawTranscript.trim();
    final tokens = trimmed.isEmpty ? const <String>[] : trimmed.split(RegExp(r'\s+'));
    final consumed = <int>{};

    var quantity = 1.0;
    var unit = QuantityUnit.piece;
    var quantityConfidence = 0.0;

    for (var i = 0; i < tokens.length; i++) {
      final u = DomainGrammar.parseUnit(tokens[i]);
      if (u == null) continue;
      final found = _findNumberBefore(tokens, i, consumed);
      unit = u;
      consumed.add(i);
      if (found != null) {
        quantity = found.value;
        quantityConfidence = 0.9;
        consumed.addAll(found.indices);
      } else {
        // Unit spoken with no quantity ("cooking oil ... piece") — a
        // single unit is a reasonable default, but it's an assumption,
        // not something heard, so it's flagged for confirmation.
        quantity = 1;
        quantityConfidence = 0.6;
      }
      break;
    }

    var pricePerUnit = 0.0;
    var priceConfidence = 0.0;
    for (var i = 0; i < tokens.length; i++) {
      if (consumed.contains(i)) continue;
      final norm = DomainGrammar.normalize(tokens[i]);
      final isStrictMarker = _rupeeWords.contains(norm);
      final isGenitiveMarker = _genitivePriceWords.contains(norm);
      if (!isStrictMarker && !isGenitiveMarker) continue;
      final found = _findNumberBefore(tokens, i, consumed);
      // A genitive particle only counts as a price marker when there's
      // actually a number right before it — otherwise it's just an
      // ordinary word and scanning continues past it.
      if (found == null && isGenitiveMarker) continue;
      consumed.add(i);
      if (found != null) {
        pricePerUnit = found.value;
        priceConfidence = 0.9;
        consumed.addAll(found.indices);
      }
      break;
    }

    // ---- Flat / package pricing --------------------------------------------
    // Packaged goods are quoted as a flat price for the item, with no unit
    // word at all: "shampoo 600 ka", "200 ka kala saban", "panadol 30 ka
    // patta". Requiring a spoken unit before trusting the quantity meant
    // every one of these was dragged to the confirmation screen even though
    // the name and price were both heard perfectly — reported as "you didn't
    // fix the issue for those prices which have a fixed rate".
    //
    // So: when a price was heard but no unit word was spoken anywhere, one
    // piece is the intended quantity. A leading bare number is taken as that
    // quantity ("1 bari bottle shampoo 600 ki" — otherwise the "1" leaks into
    // the item name); otherwise it's an implied single item. Scored just
    // above the gate rather than at full confidence: the price and name were
    // genuinely heard, but the count is inferred, so it stays the weakest
    // field and any ASR uncertainty (see [withAsrConfidence]) still pulls the
    // whole line back under the gate.
    final unitWasSpoken = quantityConfidence > 0;
    if (!unitWasSpoken && priceConfidence > 0) {
      final leading = _leadingCountBefore(tokens, consumed);
      if (leading != null) {
        quantity = leading.value;
        consumed.addAll(leading.indices);
        unit = QuantityUnit.piece;
        quantityConfidence = 0.8;
      } else if (!_hasUnconsumedNumber(tokens, consumed)) {
        // Nothing number-ish left over: an unambiguous flat price for one
        // item.
        quantity = 1;
        unit = QuantityUnit.piece;
        quantityConfidence = 0.8;
      }
      // Otherwise a stray number is still floating in the utterance
      // ("sugar 2 240 rupee") — that 2 could be a count, a pack size, or
      // part of the product name, and guessing "1" would quietly record
      // the wrong quantity. Left at zero confidence so the gate asks.
    }

    final nameTokens = [
      for (var i = 0; i < tokens.length; i++)
        if (!consumed.contains(i)) tokens[i],
    ];
    final itemNameRaw = nameTokens.join(' ').trim();
    final itemNameConfidence = switch (itemNameRaw) {
      '' => 0.0,
      // Nothing besides the name was recognized at all — likely the whole
      // utterance was just a name with no price/quantity spoken yet.
      _ when itemNameRaw == trimmed => 0.3,
      _ => 0.9,
    };

    return ParsedLineItem(
      itemNameRaw: itemNameRaw.isEmpty ? trimmed : itemNameRaw,
      quantity: quantity,
      unit: unit,
      pricePerUnit: Money.fromRupees(pricePerUnit),
      itemNameConfidence: itemNameConfidence,
      quantityConfidence: quantityConfidence,
      priceConfidence: priceConfidence,
    );
  }

  /// Folds the ASR engine's own confidence in the *whole utterance* into a
  /// parsed line's per-field scores — the missing half of the confidence
  /// gate (SRS §12.5). [SlotParser.parse] only ever sees the recognized
  /// text, so it can perfectly match a unit/price pattern that the
  /// recognizer itself was actually unsure about (background noise,
  /// mumbled speech) and nothing above would catch that. [asrConfidence]
  /// is `speech_to_text`'s `SpeechRecognitionResult.confidence`: a negative
  /// value means the engine didn't supply one (nothing to adjust), and
  /// otherwise every field's confidence is scaled by it — so a low-
  /// confidence noisy recognition drags the whole line back under the
  /// gate threshold even when the grammar match looked clean, while a
  /// confident recognition leaves the parse essentially untouched.
  static ParsedLineItem withAsrConfidence(ParsedLineItem parsed, double asrConfidence) {
    if (asrConfidence < 0) return parsed;
    final factor = asrConfidence.clamp(0.0, 1.0);
    return ParsedLineItem(
      itemNameRaw: parsed.itemNameRaw,
      quantity: parsed.quantity,
      unit: parsed.unit,
      pricePerUnit: parsed.pricePerUnit,
      itemNameConfidence: parsed.itemNameConfidence * factor,
      quantityConfidence: parsed.quantityConfidence * factor,
      priceConfidence: parsed.priceConfidence * factor,
    );
  }

  /// Whether any leftover token still looks like a number — the signal that
  /// a flat-price reading would be a guess rather than a safe default.
  static bool _hasUnconsumedNumber(List<String> tokens, Set<int> consumed) {
    for (var i = 0; i < tokens.length; i++) {
      if (consumed.contains(i)) continue;
      if (DomainGrammar.parseDigits(tokens[i]) != null) return true;
      if (DomainGrammar.parseNumberWords(tokens, i) != null) return true;
      if (DomainGrammar.fixedFractionWords.containsKey(DomainGrammar.normalize(tokens[i]))) {
        return true;
      }
    }
    return false;
  }

  /// A count at the very start of what's left of the utterance ("**1** bari
  /// bottle shampoo", "**ek** packet chai) — only consulted for flat-priced
  /// items, where there's no unit word to anchor the quantity to. Restricted
  /// to the leading position on purpose: a number anywhere else in a name is
  /// far more likely to be part of the product itself ("Surf Excel 500",
  /// "7Up") than a count.
  static ({double value, List<int> indices})? _leadingCountBefore(
    List<String> tokens,
    Set<int> consumed,
  ) {
    final first = [
      for (var i = 0; i < tokens.length; i++)
        if (!consumed.contains(i)) i,
    ].firstOrNull;
    if (first == null) return null;

    final digits = DomainGrammar.parseDigits(tokens[first]);
    if (digits != null && digits > 0) return (value: digits, indices: [first]);

    final word = DomainGrammar.parseNumberWords(tokens, first);
    if (word != null && word.consumed == 1 && word.value > 0) {
      return (value: word.value, indices: [first]);
    }
    return null;
  }

  /// Looks immediately before [anchorIndex] (a unit or rupee word) for a
  /// number: a fixed-fraction word, a sawa/paune-modified number, spelled-
  /// out number words (possibly two tokens, e.g. "do sau"), or plain digits.
  static ({double value, List<int> indices})? _findNumberBefore(
    List<String> tokens,
    int anchorIndex,
    Set<int> consumed,
  ) {
    final idx = anchorIndex - 1;
    if (idx < 0 || consumed.contains(idx)) return null;

    final norm = DomainGrammar.normalize(tokens[idx]);

    if (DomainGrammar.fixedFractionWords.containsKey(norm)) {
      return (value: DomainGrammar.fixedFractionWords[norm]!, indices: [idx]);
    }

    final digitVal = DomainGrammar.parseDigits(tokens[idx]);
    if (digitVal != null) {
      final modified = _applyModifierBefore(tokens, idx, digitVal, consumed);
      return modified ?? (value: digitVal, indices: [idx]);
    }

    if (idx - 1 >= 0 && !consumed.contains(idx - 1)) {
      final twoWord = DomainGrammar.parseNumberWords(tokens, idx - 1);
      if (twoWord != null && twoWord.consumed == 2) {
        return (value: twoWord.value, indices: [idx - 1, idx]);
      }
    }

    final oneWord = DomainGrammar.parseNumberWords(tokens, idx);
    if (oneWord != null && oneWord.consumed == 1) {
      final modified = _applyModifierBefore(tokens, idx, oneWord.value, consumed);
      return modified ?? (value: oneWord.value, indices: [idx]);
    }

    // A bare modifier immediately before the unit, with an implied "1"
    // ("sawa kilo" = 1.25kg, "paune kilo" = 0.75kg).
    if (DomainGrammar.sawaModifierWords.contains(norm)) {
      return (value: 1.25, indices: [idx]);
    }
    if (DomainGrammar.pauneModifierWords.contains(norm)) {
      return (value: 0.75, indices: [idx]);
    }

    return null;
  }

  static ({double value, List<int> indices})? _applyModifierBefore(
    List<String> tokens,
    int numberIndex,
    double numberValue,
    Set<int> consumed,
  ) {
    final modifierIndex = numberIndex - 1;
    if (modifierIndex < 0 || consumed.contains(modifierIndex)) return null;
    final norm = DomainGrammar.normalize(tokens[modifierIndex]);
    if (DomainGrammar.sawaModifierWords.contains(norm)) {
      return (value: numberValue + 0.25, indices: [modifierIndex, numberIndex]);
    }
    if (DomainGrammar.pauneModifierWords.contains(norm)) {
      return (value: numberValue - 0.25, indices: [modifierIndex, numberIndex]);
    }
    return null;
  }
}
