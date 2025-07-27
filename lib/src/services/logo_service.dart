import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'supabase_service.dart';

class LogoService {
  Future<Directory> _getDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final logos = Directory('${dir.path}/logos');
    if (!await logos.exists()) {
      await logos.create(recursive: true);
    }
    return logos;
  }

  Future<List<String>> listLogos() async {
    final dir = await _getDir();
    final files = await dir
        .list()
        .where((e) => e is File)
        .map((e) => e.path)
        .toList();
    if (files.isNotEmpty) {
      files.sort();
      return files;
    }

    final urls = await SupabaseService.instance.fetchLogos();
    for (final url in urls) {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final name = p.basename(url);
        final file = File('${dir.path}/$name');
        await file.writeAsBytes(resp.bodyBytes);
        files.add(file.path);
      }
    }
    files.sort();
    return files;
  }

  Future<String?> importLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final src = File(result.files.single.path!);
      final dir = await _getDir();
      final ext = p.extension(src.path);
      final name = '${const Uuid().v4()}$ext';
      final dest = await src.copy('${dir.path}/$name');
      await SupabaseService.instance.uploadLogo(dest);
      return dest.path;
    }
    return null;
  }

  Future<void> deleteLogo(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    final name = p.basename(path);
    final url = SupabaseService.instance.logoUrlFromName(name);
    await SupabaseService.instance.deleteLogo(url);
  }
}
