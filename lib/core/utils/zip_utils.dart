import 'dart:typed_data';
import 'package:archive/archive.dart';

class ZipUtils {
  ZipUtils._();

  static Uint8List createZip(Map<String, Uint8List> files) {
    final archive = Archive();

    for (final entry in files.entries) {
      archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
    }

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData);
  }

  static Map<String, Uint8List> extractZip(Uint8List zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final files = <String, Uint8List>{};

    for (final file in archive) {
      if (file.isFile) {
        files[file.name] = file.content;
      }
    }

    return files;
  }
}
