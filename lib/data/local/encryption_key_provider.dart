import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Generates and stores the SQLCipher passphrase for the local database.
///
/// The passphrase itself lives in Android Keystore-backed secure storage
/// (never in the database file, never hardcoded), satisfying NFR §10.2's
/// AES-256-at-rest requirement — SQLCipher encrypts the database with this
/// passphrase using AES-256 by default.
class EncryptionKeyProvider {
  EncryptionKeyProvider({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _passphraseKey = 'bolobill_db_passphrase';

  final FlutterSecureStorage _storage;

  /// Returns the existing passphrase, or generates and persists a new
  /// cryptographically random one on first run.
  Future<String> getOrCreatePassphrase() async {
    final existing = await _storage.read(key: _passphraseKey);
    if (existing != null) return existing;

    final generated = _generatePassphrase();
    await _storage.write(key: _passphraseKey, value: generated);
    return generated;
  }

  String _generatePassphrase() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
