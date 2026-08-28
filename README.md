# BoloBill

**A voice-first billing and khata (credit ledger) Android app for retailers who can't type.**

Flutter · Clean Architecture · Offline-first with AES-256 encrypted local storage · English, Urdu and Roman Urdu

---

## Why this exists

I spent time behind the counter at my father's general store in Attock. Two things were obvious within an hour:

1. Customers come in bursts. There is no time to tap out an itemised bill for every sale.
2. The retailer is *fast* on a physical calculator — faster than anyone is on a phone keyboard.

Most billing apps assume a product catalogue, a barcode scanner and a literate operator who can type. In a village general store none of those hold: prices fluctuate daily, customers buy 50 grams of something, and the person behind the counter may not read.

So BoloBill has no catalogue and no barcode scanner. You speak the sale, or you type it. Nothing else.

---

## The interesting problem: Urdu price grammar is ambiguous

A custom slot parser extracts `item`, `quantity`, `unit` and `price` from a single natural spoken phrase. Transcription is the easy half. This is the hard half:

| Spoken | Means |
|---|---|
| `chinni 5 kilo 100 ka` | sugar, 5 kg, **Rs 100 per kg** → Rs 500 total |
| `chinni 5 kilo 500 ki` | sugar, 5 kg, **Rs 500 total** → Rs 100 per kg |

One letter. The `ki` / `ka` marker after a quantity flips whether the number that follows is a unit price or a total. Default to unit price and you silently hand the customer a bill that is five times wrong.

The parser handles this explicitly, and it is covered by tests:

```
lib/features/voice/grammar/domain_grammar.dart      → the marker grammar
lib/features/voice/slot_parser/slot_parser.dart     → extraction + confidence
lib/features/voice/ml/slot_model_weights.dart       → trained model weights
test/features/voice/slot_parser_test.dart
test/features/voice/domain_grammar_test.dart
test/features/voice/parsed_line_item_test.dart
```

When parser confidence on one field is low, the app asks the retailer to confirm **that field only**, rather than discarding the whole utterance and making them start again.

---

## An engineering decision worth reading

I trained a **custom slot model** for this, expecting it to beat the hand-written parser on noisy shop audio and mixed accents.

It did not. The rule-based parser outperformed it on the real test recordings.

So the rule-based parser is what ships, and the model weights stay in the tree as the record of the experiment. That is the honest result — the interesting engineering turned out to be in the price-marker grammar, not in the model.

---

## Features

**Billing** — voice or manual line-item entry, a running bill, an explicit *"Jama Karain"* (calculate) action that totals the items and **reads the total back aloud** via TTS, and payment-type selection.

**Khata (credit ledger)** — customer profiles with name, photo, CNIC photo and phone number, entered by hand or by voice the way a paper register works. Generate a receipt against an existing customer and it files itself into their ledger.

**Receipts** — WhatsApp delivery via share intent, plus **Bluetooth thermal printer** support (ESC/POS).

**Reports** — sales and ledger views over the local database.

**Trilingual** — full ARB localisation for English, Urdu and Roman Urdu (`app_en.arb`, `app_ur.arb`, `app_ur_Latn.arb`), with Noto Nastaliq Urdu bundled locally so typography works with zero connectivity.

---

## Architecture

Clean Architecture, strictly layered:

```
lib/
├── core/           di · localization · navigation · sync · theme
├── domain/         entities · repository interfaces
├── data/
│   ├── local/      SQLCipher database + DAOs
│   ├── remote/     firestore_sync_service.dart
│   └── repositories/
└── features/       billing · khata · receipts · reports
                    voice · onboarding · notifications · settings
```

**Offline-first, then sync.** Every write lands in the encrypted local database first. `core/sync/sync_manager.dart` reconciles with Firestore when connectivity returns — client-generated UUIDs as primary keys keep that offline-safe, and `integration_test/sync_test.dart` exercises the path.

**Security.** The local database is SQLCipher with AES-256; the passphrase lives in the Android Keystore via `flutter_secure_storage`, not in the source.

---

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.11+ / Dart |
| State | Riverpod |
| Local database | `sqflite_sqlcipher` (AES-256) + Android Keystore |
| Sync | Cloud Firestore, offline-first via `sync_manager` |
| Auth | Firebase Auth — Google Sign-In and phone OTP |
| Speech | `speech_to_text` (push-to-talk), `flutter_tts` for read-back |
| Printing | `print_bluetooth_thermal` + `esc_pos_utils_plus` |
| Sharing | `share_plus` (WhatsApp) |
| Testing | `flutter_test`, `integration_test`, `fake_cloud_firestore` — 18 test files |

Android, min SDK 26. Current version **1.0.7+8**.

---

## Running it

```bash
git clone https://github.com/hanova-dev/BoloBill.git
cd BoloBill
flutter pub get
flutter run
```

Requires Flutter 3.11+ and an Android device or emulator with microphone access. You'll need your own `google-services.json` for the Firebase features.

---

## Status and current work

Shipped and tested with a working retailer.

- Extending the unit taxonomy beyond weight and count (`piece, dozen, kg, gram, litre, metre`) to include `bottle, packet, strip, box` — wired through enum, schema, grammar, UI and receipt formatting.
- Reducing time-to-first-listen after the mic button is pressed.
- Exploring a calculator-style fast entry mode for high-volume moments, based on retailer feedback.

---

## Author

**Muhammad Abdul Hanan** — Flutter Developer, final-year BS Software Engineering at COMSATS University Islamabad.

[LinkedIn](https://www.linkedin.com/in/hananbinsaleh) · [GitHub](https://github.com/hanova-dev) · callmeabdulhanann@gmail.com
