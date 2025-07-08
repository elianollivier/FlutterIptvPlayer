import 'dart:convert';
import 'dart:io';

import '../models/iptv_models.dart';

class M3uService {
  const M3uService();

  Future<List<ChannelLink>> loadFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return [];
    final lines = file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    String? name;
    final List<ChannelLink> result = [];
    await for (final line in lines) {
      if (line.startsWith('#EXTINF')) {
        final comma = line.indexOf(',');
        if (comma >= 0 && comma + 1 < line.length) {
          name = line.substring(comma + 1).trim();
        } else {
          name = null;
        }
      } else if (line.trim().isNotEmpty && !line.startsWith('#')) {
        if (name != null) {
          result.add(ChannelLink(
            name: name,
            url: line.trim(),
            resolution: '',
            fps: '',
            notes: '',
          ));
          name = null;
        }
      }
    }
    return result;
  }

  Future<List<ChannelLink>> searchFile(
    String path, {
    String query = '',
    int limit = 100,
  }) async {
    final file = File(path);
    if (!await file.exists()) return [];
    final lines = file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    String? name;
    final lowerQuery = query.toLowerCase();
    final List<ChannelLink> result = [];
    await for (final line in lines) {
      if (line.startsWith('#EXTINF')) {
        final comma = line.indexOf(',');
        if (comma >= 0 && comma + 1 < line.length) {
          name = line.substring(comma + 1).trim();
        } else {
          name = null;
        }
      } else if (line.trim().isNotEmpty && !line.startsWith('#')) {
        if (name != null) {
          final link = ChannelLink(
            name: name,
            url: line.trim(),
            resolution: '',
            fps: '',
            notes: '',
          );
          if (lowerQuery.isEmpty ||
              link.name.toLowerCase().contains(lowerQuery)) {
            result.add(link);
            if (result.length >= limit) break;
          }
          name = null;
        }
      }
    }
    return result;
  }
}
