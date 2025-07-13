import 'dart:convert';
import 'dart:io';

import '../models/iptv_models.dart';
import '../models/m3u_series.dart';

class M3uService {
  const M3uService();

  Future<List<ChannelLink>> loadFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return [];
    final lines =
        file.openRead().transform(utf8.decoder).transform(const LineSplitter());
    String? name;
    String? logo;
    final List<ChannelLink> result = [];
    await for (final line in lines) {
      if (line.startsWith('#EXTINF')) {
        final comma = line.indexOf(',');
        if (comma >= 0 && comma + 1 < line.length) {
          name = line.substring(comma + 1).trim();
        } else {
          name = null;
        }
        final match =
            RegExp('tvg-logo="([^"]*)"', caseSensitive: false).firstMatch(line);
        logo = match != null ? match.group(1) : '';
      } else if (line.trim().isNotEmpty && !line.startsWith('#')) {
        if (name != null) {
          result.add(ChannelLink(
            name: name,
            url: line.trim(),
            logo: logo ?? '',
            resolution: '',
            fps: '',
            notes: '',
          ));
          name = null;
          logo = null;
        }
      }
    }
    return result;
  }

  Future<List<ChannelLink>> searchFile(
    String path, {
    String query = '',
    int limit = 150,
  }) async {
    final file = File(path);
    if (!await file.exists()) return [];
    final lines =
        file.openRead().transform(utf8.decoder).transform(const LineSplitter());
    String? name;
    String? logo;
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
        final match =
            RegExp('tvg-logo="([^"]*)"', caseSensitive: false).firstMatch(line);
        logo = match != null ? match.group(1) : '';
      } else if (line.trim().isNotEmpty && !line.startsWith('#')) {
        if (name != null) {
          final link = ChannelLink(
            name: name,
            url: line.trim(),
            logo: logo ?? '',
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
          logo = null;
        }
      }
    }
    return result;
  }

  Future<List<M3uSeries>> loadSeries(
    String path, {
    String query = '',
  }) async {
    final file = File(path);
    if (!await file.exists()) return [];
    final lines =
        file.openRead().transform(utf8.decoder).transform(const LineSplitter());
    String? name;
    String? logo;
    final Map<String, M3uSeries> map = {};
    final lowerQuery = query.toLowerCase();
    final reg =
        RegExp(r'(.+?)S(\d{1,2})[^\d]?E(\d{1,2})', caseSensitive: false);
    await for (final line in lines) {
      if (line.startsWith('#EXTINF')) {
        final comma = line.indexOf(',');
        if (comma >= 0 && comma + 1 < line.length) {
          name = line.substring(comma + 1).trim();
        } else {
          name = null;
        }
        final match =
            RegExp('tvg-logo="([^"]*)"', caseSensitive: false).firstMatch(line);
        logo = match != null ? match.group(1) : '';
      } else if (line.trim().isNotEmpty && !line.startsWith('#')) {
        if (name != null) {
          final url = line.trim();
          final m = reg.firstMatch(name!);
          if (m != null) {
            final serieName = m.group(1)!.trim();
            final season = int.tryParse(m.group(2) ?? '1') ?? 1;
            final episode = int.tryParse(m.group(3) ?? '1') ?? 1;
            if (lowerQuery.isEmpty ||
                serieName.toLowerCase().contains(lowerQuery)) {
              final ep = M3uEpisode(
                name: name!,
                url: url,
                season: season,
                episode: episode,
                logo: logo ?? '',
              );
              map.putIfAbsent(
                serieName,
                () =>
                    M3uSeries(name: serieName, logo: logo ?? '', episodes: []),
              );
              map[serieName]!.episodes.add(ep);
            }
          }
          name = null;
          logo = null;
        }
      }
    }
    return map.values.toList();
  }
}
