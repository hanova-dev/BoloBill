"""Does the trained tagger generalize, or has it just memorised the generator?

The headline holdout number from train.py is drawn from the same generator as
the training data, so it can only show self-consistency. This script is the
honest counter-test: hand-written utterances whose product names are absent
from the training vocabulary, with filler words and orderings the templates
never emit. Failures here are the real measure.

Run:  python tools/voice_model/evaluate_generalization.py
"""

import numpy as np

from train import (ITEM, O, PRICE, QTY, UNIT, LABELS, featurize, softmax,
                   make_example, to_xy, train, REAL_PHRASES)

# Products deliberately absent from ITEM_WORDS, plus fillers ("wala", "de
# do", "aur") and orderings the templates never produce.
UNSEEN = [
    # unknown brand, familiar shape
    [("olpers", ITEM), ("doodh", ITEM), ("2", QTY), ("litre", UNIT),
     ("400", PRICE), ("ka", O)],
    # unknown medicine, flat price
    [("ciprofloxacin", ITEM), ("250", PRICE), ("ka", O)],
    # filler word mid-utterance
    [("mujhe", O), ("dalda", ITEM), ("ghee", ITEM), ("1", QTY),
     ("kilo", UNIT), ("650", PRICE), ("ka", O)],
    # trailing politeness
    [("nirma", ITEM), ("surf", ITEM), ("180", PRICE), ("ka", O),
     ("dena", O)],
    # unknown item, unit-first ordering
    [("teen", QTY), ("packet", UNIT), ("kurkure", ITEM), ("60", PRICE),
     ("ke", O)],
    # brand with a number in the name — the classic trap
    [("7up", ITEM), ("ki", O), ("bottle", ITEM), ("120", PRICE), ("ki", O)],
    # two unknown descriptors
    [("imported", ITEM), ("khajoor", ITEM), ("adha", QTY), ("kilo", UNIT),
     ("900", PRICE), ("ki", O)],
    # no price particle at all
    [("kinnow", ITEM), ("5", QTY), ("kilo", UNIT), ("300", PRICE)],
]


def main():
    train_ex = [make_example() for _ in range(9000)] + REAL_PHRASES * 200
    Xtr, ytr = to_xy(train_ex)
    W = train(Xtr, ytr, len(LABELS))

    Xu, yu = to_xy(UNSEEN)
    pred = softmax(Xu @ W).argmax(axis=1)
    print(f"unseen-utterance token accuracy: {(pred == yu).mean():.3f}\n")

    k = 0
    for seq in UNSEEN:
        toks = [w for w, _ in seq]
        gold = [l for _, l in seq]
        got = pred[k:k + len(seq)]
        k += len(seq)
        ok = "OK  " if list(got) == gold else "MISS"
        print(f"{ok} {' '.join(toks)}")
        if list(got) != gold:
            for t, g, p in zip(toks, gold, got):
                flag = "" if g == p else "   <-- wrong"
                print(f"       {t:16s} gold={LABELS[g]:6s} pred={LABELS[p]:6s}{flag}")
    print()


if __name__ == "__main__":
    main()
