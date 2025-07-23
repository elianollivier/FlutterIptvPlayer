import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';

import '../models/m3u_playlist.dart';
import 'supabase_service.dart';

class M3uPlaylistService {
  const M3uPlaylistService();

  static final Logger _logger = Logger();

  Future<Directory> _getDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final playlists = Directory('${dir.path}/playlists');
    if (!await playlists.exists()) {
      await playlists.create(recursive: true);
    }
    return playlists;
  }

  Future<File> _getFile() async {
    final dir = await _getDir();
    return File('${dir.path}/playlists.json');
  }

  Future<List<M3uPlaylist>> load() async {
    final file = await _getFile();
    List<M3uPlaylist> list = [];
    if (await file.exists()) {
      final data = await file.readAsString();
      list = (jsonDecode(data) as List<dynamic>)
          .map((e) => M3uPlaylist.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (SupabaseService.instance.isLoggedIn) {
      try {
        list = await SupabaseService.instance.fetchPlaylists();
        await save(list);
      } catch (e) {
        _logger.e('Remote load failed', error: e);
      }
    }
    return list;
  }

  Future<void> save(List<M3uPlaylist> items) async {
    final file = await _getFile();
    await file.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
    if (SupabaseService.instance.isLoggedIn) {
      await SupabaseService.instance.savePlaylists(items);
    }
  }

  Future<String?> importLocalFile() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['m3u']);
    if (result == null || result.files.single.path == null) return null;
    final src = File(result.files.single.path!);
    final dir = await _getDir();
    final dest = File('${dir.path}/${const Uuid().v4()}.m3u');
    await src.copy(dest.path);
    return dest.path;
  }

  Future<String?> downloadFile(
      String url, void Function(double) onProgress) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url))
        ..headers['User-Agent'] = Constants.userAgent;
      final response = await client.send(request);
      final contentLength = response.contentLength ?? 0;
      final dir = await _getDir();
      final file = File('${dir.path}/${const Uuid().v4()}.m3u');
      final sink = file.openWrite();
      int received = 0;
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (contentLength > 0) {
          onProgress(received / contentLength);
        }
      }
      await sink.close();
      return file.path;
    } catch (e) {
      _logger.e('Download playlist failed', error: e);
      return null;
    } finally {
      client.close();
    }
  }

  Future<void> delete(M3uPlaylist playlist) async {
    final file = File(playlist.path);
    if (await file.exists()) {
      await file.delete();
    }
    final items = await load();
    items.removeWhere((e) => e.id == playlist.id);
    await save(items);
    if (SupabaseService.instance.isLoggedIn) {
      await SupabaseService.instance.deletePlaylists([playlist.id]);
    }
  }
}
