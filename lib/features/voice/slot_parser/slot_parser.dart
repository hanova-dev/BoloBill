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
      if (!_rupeeWords.contains(DomainGrammar.normalize(tokens[i]))) continue;
      final found = _findNumberBefore(tokens, i, consumed);
      consumed.add(i);
      if (found != null) {
        pricePerUnit = found.value;
        priceConfidence = 0.9;
        consumed.addAll(found.indices);
      }
      break;
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
