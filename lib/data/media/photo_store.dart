import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/utils/id_generator.dart';

/// Local storage for customer profile/CNIC photos (FR-3.4.4). Files live
/// under the app's private documents directory — the same OS-sandboxed
/// storage the encrypted SQLCipher database file already relies on for
/// at-rest protection (NFR §10.2 targets the database contents; these are
/// images, not sensitive structured data, so no separate file-level
/// encryption layer is added here).
abstract final class PhotoStore {
  static const _subdir = 'customer_photos';

  /// Copies [file] into permanent app storage under a fresh UUID filename
  /// and returns the saved path. The picker's own temp file is left as-is;
  /// callers only ever persist the returned path.
  static Future<String> save(XFile file) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(docsDir.path, _subdir));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    final extension = p.extension(file.path);
    final targetPath = p.join(targetDir.path, '${IdGenerator.newId()}$extension');
    await File(file.path).copy(targetPath);
    return targetPath;
  }
}
