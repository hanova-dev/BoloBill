<p align="center">
  <img src="assets/icon/app_icon.png" width="120" alt="BoloBill icon" />
</p>

<h1 align="center">BoloBill</h1>
<p align="center"><em>بولو اور بل بناؤ — speak it, bill it.</em></p>

<p align="center">
  <a href="https://github.com/hanova-dev/BoloBill/releases/latest">
    <img src="https://img.shields.io/badge/Download-APK-4A3225?style=for-the-badge&logo=android&logoColor=white" alt="Download APK" />
  </a>
</p>

BoloBill is a voice-first billing and **khata** (credit ledger) app built for
illiterate and low-literacy retailers in Pakistan. A shopkeeper can build a
bill by speaking item names, quantities, and prices out loud, hear the total
read back before confirming, and record a sale as cash or against a
customer's khata — all without needing to read or type.

## Download

Grab the latest APK from the [Releases page](https://github.com/hanova-dev/BoloBill/releases/latest),
or the direct link below:

**➡️ [BoloBill-v1.0.0.apk](https://github.com/hanova-dev/BoloBill/releases/download/v1.0.0/BoloBill-v1.0.0.apk)** (Android 8.0 / API 26+)

You'll need to allow "install from unknown sources" for your browser or file
manager, since this isn't distributed through the Play Store.

## Features

- **Voice or manual billing** — speak an item, quantity, and price, or type
  it manually; a domain-aware grammar layer understands fractions ("adha
  kilo"), compound numbers, and Roman Urdu numerals, with a confidence gate
  that asks for confirmation whenever it's unsure.
- **Jama Karain read-back** — the total is always read aloud (text-to-speech)
  before a bill is confirmed, so a bill is never saved on a misheard number.
- **Khata (credit ledger)** — customers with photos, running balances, partial
  and overpayments handled as a simple append-only ledger, sorted by balance
  or recency.
- **Offline-first** — the entire app works with zero connectivity; local data
  is stored in a SQLCipher-encrypted (AES-256) SQLite database.
- **Cloud sync** — once signed in, bills and khata entries sync to Firebase/
  Firestore in the background, with a clear synced/offline status indicator
  and a manual "Sync Now".
- **Receipts** — on-device receipt rendering, WhatsApp share, and Bluetooth
  ESC/POS thermal printer support.
- **Overdue reminders** — a local notification nudges the shopkeeper about
  customers who haven't paid down their khata in a while.
- **Full localization** — English, Urdu, and Roman Urdu, with correct
  right-to-left layout for Urdu script (and correctly *not* RTL for Roman
  Urdu, despite sharing a language code).

## Tech stack

| | |
|---|---|
| Framework | Flutter / Dart |
| State management | Riverpod |
| Local storage | `sqflite_sqlcipher` (encrypted SQLite) |
| Cloud | Firebase Auth, Cloud Firestore |
| Voice | Android `SpeechRecognizer` (via `speech_to_text`) + `flutter_tts` |
| Printing | Bluetooth ESC/POS (`print_bluetooth_thermal`, `esc_pos_utils_plus`) |
| Notifications | `flutter_local_notifications` |

## Getting started

```bash
flutter pub get
flutter run
```

The app targets Android only (minSdk 26). To build a release APK yourself:

```bash
flutter build apk --release
```

Firebase is required for sign-in and sync — you'll need your own
`android/app/google-services.json` from a Firebase project with Phone,
Google, and Firestore enabled if you're building from source rather than
using the release APK above.

## Project structure

```
lib/
  app/            # MaterialApp, theming + locale wiring
  core/           # theme, localization, database, sync, utils
  domain/         # entities, repository interfaces, usecases
  data/           # repository implementations, local DB, Firebase
  features/       # one folder per screen group (onboarding, billing,
                   # khata, receipts, reports, settings, notifications, voice)
  shared_widgets/ # widgets reused across features
```

## Known limitation

Phone-number sign-in (OTP) requires a real device or an emulator with full
Google Play Services — it will not complete on a bare "Google APIs" AVD
image. Google Sign-In is the recommended path for testing on an emulator.
