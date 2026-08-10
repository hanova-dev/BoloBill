import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../encryption_key_provider.dart';
import 'db_schema.dart';

/// Owns the single encrypted SQLite (SQLCipher, AES-256) database connection
/// that is the source of truth for all shop/bill/khata data (SRS §5.2 "Local
/// Database" component). Every DAO is handed the same [Database] instance.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static Future<AppDatabase> open({
    EncryptionKeyProvider? keyProvider,
    String? testDirectoryPath,
  }) async {
    final passphrase = await (keyProvider ?? EncryptionKeyProvider()).getOrCreatePassphrase();
    final dbDir = testDirectoryPath ?? (await getApplicationDocumentsDirectory()).path;
    final dbPath = p.join(dbDir, 'bolobill.db');

    final db = await openDatabase(
      dbPath,
      password: passphrase,
      version: kDatabaseVersion,
      onConfigure: (db) async {
        // Required every time the connection opens — SQLite does not persist
        // this pragma in the database file itself.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        for (final statement in kCreateTableStatementsV1) {
          await db.execute(statement);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          for (final statement in kMigrationV1ToV2) {
            await db.execute(statement);
          }
        }
        if (oldVersion < 3) {
          for (final statement in kMigrationV2ToV3) {
            await db.execute(statement);
          }
        }
      },
    );
    return AppDatabase._(db);
  }

  Future<void> close() => db.close();
}
