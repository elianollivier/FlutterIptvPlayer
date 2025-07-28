import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'supabase_service.dart';

class LogoService {
  final Logger _logger = Logger();

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
    files.sort();
    return files;
  }

  Future<String?> localPathFromUrl(String url) async {
    final dir = await _getDir();
    final path = p.join(dir.path, p.basename(url));
    return File(path).existsSync() ? path : null;
  }

  Future<void> syncWithSupabase() async {
    final dir = await _getDir();
    final urls = await SupabaseService.instance.fetchLogos();
    final remoteNames = urls.map((e) => p.basename(e)).toSet();
    final existingFiles = await dir
        .list()
        .where((e) => e is File)
        .cast<File>()
        .toList();

    for (final file in existingFiles) {
      if (!remoteNames.contains(p.basename(file.path))) {
        try {
          await file.delete();
        } catch (e) {
          _logger.e('Delete local logo failed', error: e);
        }
      }
    }

    final existingNames = existingFiles.map((f) => p.basename(f.path)).toSet();
    for (final url in urls) {
      final name = p.basename(url);
      if (!existingNames.contains(name)) {
        try {
          final resp = await http.get(Uri.parse(url));
          if (resp.statusCode == 200) {
            final file = File('${dir.path}/$name');
            await file.writeAsBytes(resp.bodyBytes);
          }
        } catch (e) {
          _logger.e('Download logo failed', error: e);
        }
      }
    }
  }

  Future<String?> importLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final src = File(result.files.single.path!);
      final url = await SupabaseService.instance.uploadLogo(src);
      if (url != null) {
        await syncWithSupabase();
      }
      return url;
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
