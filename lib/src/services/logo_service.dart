import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class LogoService {
  Future<Directory> _getDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final logos = Directory('${dir.path}/logos');
    if (!await logos.exists()) {
      await logos.create(recursive: true);
    }
    return logos;
  }

  Future<List<File>> listLogos() async {
    final dir = await _getDir();
    final files = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  Future<String?> importLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final src = File(result.files.single.path!);
      final dir = await _getDir();
      final ext = src.path.split('.').last;
      final dest = File('${dir.path}/${const Uuid().v4()}.$ext');
      await src.copy(dest.path);
      return dest.path;
    }
    return null;
  }

  Future<void> deleteLogo(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
