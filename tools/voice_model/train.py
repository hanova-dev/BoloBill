"""Trains BoloBill's voice slot-tagger and exports it as plain Dart.

What this is
------------
A small supervised token classifier: every word of a spoken bill line is
labelled ITEM / QTY / UNIT / PRICE / OTHER, and the app reassembles those
labels into a line item. This is the standard "slot filling" shape of the
problem, and it is deliberately a *small* model — multinomial logistic
regression over ~24 hand-built features — for three reasons:

  * it exports to a few hundred floats, so inference is pure Dart with no
    new package, no TFLite runtime, and no APK bloat (the alternative,
    bundling a small LLM, costs 500MB+ and seconds per utterance on the
    cheap Android phones this app targets);
  * it runs in well under a millisecond, so voice entry stays instant;
  * it trains in seconds here, so the vocabulary and templates below can be
    extended by anyone without an ML pipeline.

Honest limitation
-----------------
No public dataset of Roman-Urdu retail billing utterances exists, so the
training data is generated from the templates and vocabulary below. A model
trained on generated data mostly learns the patterns encoded in that
generator — it will not invent understanding of phrasings absent from it.
Its real advantage over the hand-written rule parser is softer behaviour on
*unseen wordings and unknown product names*: it scores every token by
context (neighbouring units, price particles, position) instead of needing
one rigid anchor pattern to match, and it emits a genuine probability that
feeds the confidence gate rather than hand-assigned constants.

The way this gets genuinely better is real retailer speech. `REAL_PHRASES`
below is that seed corpus — every verified utterance from a real shop
should be appended there.

Run:  python tools/voice_model/train.py
"""

import json
import random
import re
from pathlib import Path

import numpy as np

random.seed(17)
np.random.seed(17)

# --------------------------------------------------------------------------
# Vocabulary. Kept in sync with lib/features/voice/grammar/domain_grammar.dart
# --------------------------------------------------------------------------

UNIT_WORDS = [
    "kilo", "kg", "کلو", "gram", "grams", "گرام", "piece", "pieces", "pc",
    "adad", "عدد", "dozen", "darjan", "درجن", "litre", "liter", "لیٹر",
    "meter", "metre", "میٹر",
]

PRICE_MARKERS = ["ki", "ka", "ke", "kay", "کی", "کا", "کے",
                 "rupee", "rupya", "rupye", "rupaye", "rs", "روپے"]

FRACTION_WORDS = ["adha", "aadha", "آدھا", "pao", "paw", "پاؤ",
                  "derh", "dedh", "ڈیڑھ", "dhai", "ڈھائی"]

NUMBER_WORDS = [
    "ek", "do", "teen", "chaar", "paanch", "chhay", "saat", "aath", "nau",
    "dus", "gyarah", "barah", "bees", "pachees", "tees", "chalees",
    "pachaas", "saath", "sattar", "assi", "nawway", "sau", "hazar",
]

MODIFIERS = ["sawa", "paune", "سوا", "پونے"]

# Real Pakistani retail stock, across the shop types the app supports.
ITEM_WORDS = [
    # kirana / grocery
    "cheeni", "atta", "chawal", "daal", "ghee", "tel", "namak", "chai",
    "patti", "doodh", "dahi", "anday", "makhan", "besan", "suji", "maida",
    "masala", "haldi", "mirch", "channa", "lobia", "sarson",
    # packaged / general store
    "shampoo", "saban", "soap", "surf", "colgate", "toothpaste", "brush",
    "biscuit", "chips", "juice", "bottle", "packet", "dabba", "sachet",
    "lifebuoy", "sunsilk", "tapal", "lipton", "nestle", "coke", "sprite",
    # medical store
    "panadol", "disprin", "brufen", "augmentin", "flagyl", "calpol",
    "patta", "syrup", "tablet", "capsule", "injection", "bandage",
    "dettol", "cotton", "mask", "sanitizer", "thermometer",
    # descriptors that belong to the name
    "bara", "bari", "chota", "choti", "kala", "kali", "safaid", "lal",
    "desi", "special", "fresh", "purana", "naya",
]

DIGITS = ["5", "10", "20", "25", "30", "50", "60", "80", "100", "120",
          "150", "200", "240", "250", "300", "350", "400", "500", "600",
          "750", "800", "1000", "1200", "1500", "2000"]

SMALL_DIGITS = ["1", "2", "3", "4", "5", "6", "10", "12"]

O, ITEM, QTY, UNIT, PRICE = 0, 1, 2, 3, 4
LABELS = ["O", "ITEM", "QTY", "UNIT", "PRICE"]


def item_phrase():
    n = random.choices([1, 2, 3], weights=[6, 3, 1])[0]
    return random.sample(ITEM_WORDS, n)


def qty_tokens():
    """A quantity expression plus the labels for each of its tokens."""
    kind = random.choices(["digit", "word", "fraction", "modified"],
                          weights=[5, 3, 2, 1])[0]
    if kind == "digit":
        return [(random.choice(SMALL_DIGITS), QTY)]
    if kind == "word":
        return [(random.choice(NUMBER_WORDS[:12]), QTY)]
    if kind == "fraction":
        return [(random.choice(FRACTION_WORDS), QTY)]
    return [(random.choice(MODIFIERS), QTY), (random.choice(NUMBER_WORDS[:6]), QTY)]


def price_tokens():
    toks = [(random.choice(DIGITS), PRICE)]
    if random.random() < 0.15:  # "do sau" style compounds
        toks = [(random.choice(NUMBER_WORDS[:9]), PRICE), ("sau", PRICE)]
    toks.append((random.choice(PRICE_MARKERS), O))
    return toks


def make_example():
    """One labelled utterance, drawn from the shapes retailers actually use."""
    item = [(w, ITEM) for w in item_phrase()]
    unit = [(random.choice(UNIT_WORDS), UNIT)]
    qty = qty_tokens()
    price = price_tokens()

    shape = random.choices(
        ["qty_unit_item_price", "item_qty_unit_price", "price_qty_unit_item",
         "flat_item_price", "flat_price_item", "flat_count_item_price",
         "item_price_only", "item_only"],
        weights=[5, 5, 2, 6, 3, 2, 2, 1])[0]

    if shape == "qty_unit_item_price":
        seq = qty + unit + item + price
    elif shape == "item_qty_unit_price":
        seq = item + qty + unit + price
    elif shape == "price_qty_unit_item":
        seq = price + qty + unit + item
    elif shape == "flat_item_price":
        seq = item + price
    elif shape == "flat_price_item":
        seq = price + item
    elif shape == "flat_count_item_price":
        seq = [(random.choice(SMALL_DIGITS), QTY)] + item + price
    elif shape == "item_price_only":
        seq = item + [(random.choice(DIGITS), PRICE), (random.choice(PRICE_MARKERS), O)]
    else:
        seq = item
    return seq


# Verified real-shop utterances. Weighted up during training so the shapes
# that actually occur in the field dominate the generated ones.
REAL_PHRASES = [
    [("cheeni", ITEM), ("200", PRICE), ("ki", O)],
    [("200", PRICE), ("ka", O), ("kala", ITEM), ("saban", ITEM)],
    [("adha", QTY), ("kilo", UNIT), ("kali", ITEM), ("pati", ITEM),
     ("400", PRICE), ("ki", O)],
    [("1", QTY), ("bari", ITEM), ("bottle", ITEM), ("shampoo", ITEM),
     ("600", PRICE), ("ki", O)],
    [("panadol", ITEM), ("30", PRICE), ("ka", O), ("patta", ITEM)],
    [("ek", QTY), ("dozen", UNIT), ("anday", ITEM), ("350", PRICE), ("ke", O)],
]

# --------------------------------------------------------------------------
# Features — MUST stay identical to lib/features/voice/ml/slot_features.dart
# --------------------------------------------------------------------------

FEATURE_NAMES = [
    "bias", "is_digit", "is_number_word", "is_fraction_word", "is_modifier",
    "is_unit_word", "is_price_marker", "is_known_item", "is_first", "is_last",
    "prev_is_digit", "prev_is_unit", "prev_is_price_marker", "prev_is_numeric",
    "next_is_digit", "next_is_unit", "next_is_price_marker", "next_is_numeric",
    "next2_is_price_marker", "rel_position", "is_numeric", "prev_is_item",
    "len_short", "len_long",
]

UNIT_SET = set(UNIT_WORDS)
PRICE_SET = set(PRICE_MARKERS)
FRAC_SET = set(FRACTION_WORDS)
NUM_SET = set(NUMBER_WORDS)
MOD_SET = set(MODIFIERS)
ITEM_SET = set(ITEM_WORDS)


def is_digit(t):
    return bool(re.fullmatch(r"[0-9]+(\.[0-9]+)?", t))


def numeric(t):
    return is_digit(t) or t in NUM_SET or t in FRAC_SET


def featurize(tokens, i):
    t = tokens[i].lower()
    prev = tokens[i - 1].lower() if i > 0 else ""
    nxt = tokens[i + 1].lower() if i + 1 < len(tokens) else ""
    nxt2 = tokens[i + 2].lower() if i + 2 < len(tokens) else ""
    n = len(tokens)
    return [
        1.0,
        float(is_digit(t)),
        float(t in NUM_SET),
        float(t in FRAC_SET),
        float(t in MOD_SET),
        float(t in UNIT_SET),
        float(t in PRICE_SET),
        float(t in ITEM_SET),
        float(i == 0),
        float(i == n - 1),
        float(is_digit(prev)),
        float(prev in UNIT_SET),
        float(prev in PRICE_SET),
        float(numeric(prev)),
        float(is_digit(nxt)),
        float(nxt in UNIT_SET),
        float(nxt in PRICE_SET),
        float(numeric(nxt)),
        float(nxt2 in PRICE_SET),
        i / max(n - 1, 1),
        float(numeric(t)),
        float(prev in ITEM_SET),
        float(len(t) <= 3),
        float(len(t) >= 7),
    ]


def to_xy(examples):
    X, y = [], []
    for seq in examples:
        toks = [w for w, _ in seq]
        for i, (_, lab) in enumerate(seq):
            X.append(featurize(toks, i))
            y.append(lab)
    return np.array(X, dtype=np.float64), np.array(y, dtype=np.int64)


def softmax(z):
    z = z - z.max(axis=1, keepdims=True)
    e = np.exp(z)
    return e / e.sum(axis=1, keepdims=True)


def train(X, y, classes, epochs=600, lr=0.5, l2=1e-4):
    n, d = X.shape
    W = np.zeros((d, classes))
    Y = np.zeros((n, classes))
    Y[np.arange(n), y] = 1
    for _ in range(epochs):
        P = softmax(X @ W)
        grad = X.T @ (P - Y) / n + l2 * W
        W -= lr * grad
    return W


def accuracy(W, X, y):
    return float((softmax(X @ W).argmax(axis=1) == y).mean())


def main():
    train_ex = [make_example() for _ in range(9000)]
    train_ex += REAL_PHRASES * 200          # weight verified real speech up
    test_ex = [make_example() for _ in range(1500)]

    Xtr, ytr = to_xy(train_ex)
    Xte, yte = to_xy(test_ex)
    W = train(Xtr, ytr, len(LABELS))

    print(f"train tokens   : {len(ytr)}")
    print(f"train accuracy : {accuracy(W, Xtr, ytr):.4f}")
    print(f"holdout accuracy: {accuracy(W, Xte, yte):.4f}")

    Xr, yr = to_xy(REAL_PHRASES)
    print(f"real-phrase accuracy: {accuracy(W, Xr, yr):.4f}")

    # Per-label recall, so a class that is quietly never predicted is visible
    pred = softmax(Xte @ W).argmax(axis=1)
    print("\nper-label recall (holdout):")
    for k, name in enumerate(LABELS):
        mask = yte == k
        if mask.sum():
            print(f"  {name:6s} {(pred[mask] == k).mean():.3f}  (n={int(mask.sum())})")

    out = Path(__file__).resolve().parents[2] / "lib/features/voice/ml/slot_model_weights.dart"
    out.parent.mkdir(parents=True, exist_ok=True)
    rows = ",\n  ".join(
        "[" + ", ".join(f"{v:.6f}" for v in W[i]) + "]" for i in range(W.shape[0])
    )

    def dart_set(name, values):
        items = ", ".join("'" + v.replace("'", r"\'") + "'" for v in sorted(values))
        return f"const {name} = <String>{{{items}}};\n"

    # The vocabulary is exported with the weights rather than re-typed in
    # Dart: the features are vocabulary lookups, so any drift between the two
    # sides would silently change what the model sees at inference time
    # versus what it was trained on.
    out.write_text(
        "// GENERATED FILE — do not edit by hand.\n"
        "// Produced by tools/voice_model/train.py; retrain and regenerate\n"
        "// after changing the vocabulary, templates, or REAL_PHRASES corpus.\n"
        "//\n"
        f"// Multinomial logistic regression, {W.shape[0]} features x {W.shape[1]} labels.\n"
        f"// Holdout token accuracy at export: {accuracy(W, Xte, yte):.4f} — note that\n"
        "// the holdout is drawn from the same generator as the training data, so\n"
        "// this measures self-consistency, NOT real-world accuracy.\n"
        "\n"
        "/// Label order: O, ITEM, QTY, UNIT, PRICE.\n"
        "const slotModelWeights = <List<double>>[\n  " + rows + ",\n];\n"
        "\n"
        + dart_set("slotUnitWords", UNIT_SET)
        + dart_set("slotPriceMarkers", PRICE_SET)
        + dart_set("slotFractionWords", FRAC_SET)
        + dart_set("slotNumberWords", NUM_SET)
        + dart_set("slotModifierWords", MOD_SET)
        + dart_set("slotItemWords", ITEM_SET),
        encoding="utf-8",
    )
    print(f"\nexported -> {out}")

    meta = Path(__file__).with_name("feature_names.json")
    meta.write_text(json.dumps(FEATURE_NAMES, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
