import 'package:uuid/uuid.dart';

/// Generates client-side UUIDs for every record's primary key (SRS §8.3):
/// "All primary keys are client-generated UUIDs ... specifically to support
/// safe offline record creation across multiple devices without ID
/// collisions on sync."
abstract final class IdGenerator {
  static const _uuid = Uuid();

  static String newId() => _uuid.v4();
}
