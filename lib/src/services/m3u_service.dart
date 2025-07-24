import 'dart:convert';
import 'dart:io';

import '../models/iptv_models.dart';
import '../models/m3u_series.dart';
import 'package:flutter/foundation.dart';

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
          result.add(
            ChannelLink(
              name: name,
              url: line.trim(),
              logo: logo ?? '',
              resolution: '',
              fps: '',
              notes: const [],
            ),
          );
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
    return compute(
      _searchFileSync,
      _SearchArgs(path, query, limit),
    );
  }

  Future<List<M3uSeries>> loadSeries(
    String path, {
    String query = '',
  }) async {
    return compute(
      _loadSeriesSync,
      _SeriesArgs(path, query),
    );
  }
}

class _SearchArgs {
  final String path;
  final String query;
  final int limit;
  const _SearchArgs(this.path, this.query, this.limit);
}

List<ChannelLink> _searchFileSync(_SearchArgs args) {
  final file = File(args.path);
  if (!file.existsSync()) return [];
  final lines = file.readAsLinesSync();
  String? name;
  String? logo;
  final lowerQuery = args.query.toLowerCase();
  final List<ChannelLink> result = [];
  final regLogo = RegExp('tvg-logo="([^"]*)"', caseSensitive: false);
  for (final line in lines) {
    if (line.startsWith('#EXTINF')) {
      final comma = line.indexOf(',');
      if (comma >= 0 && comma + 1 < line.length) {
        name = line.substring(comma + 1).trim();
      } else {
        name = null;
      }
      final match = regLogo.firstMatch(line);
      logo = match != null ? match.group(1) : '';
    } else if (line.trim().isNotEmpty && !line.startsWith('#')) {
      if (name != null) {
        final link = ChannelLink(
          name: name!,
          url: line.trim(),
          logo: logo ?? '',
          resolution: '',
          fps: '',
          notes: const [],
        );
        if (lowerQuery.isEmpty ||
            link.name.toLowerCase().contains(lowerQuery)) {
          result.add(link);
          if (result.length >= args.limit) break;
        }
        name = null;
        logo = null;
      }
    }
  }
  return result;
}

class _SeriesArgs {
  final String path;
  final String query;
  const _SeriesArgs(this.path, this.query);
}

List<M3uSeries> _loadSeriesSync(_SeriesArgs args) {
  final file = File(args.path);
  if (!file.existsSync()) return [];
  final lines = file.readAsLinesSync();
  String? name;
  String? logo;
  final Map<String, M3uSeries> map = {};
  final lowerQuery = args.query.toLowerCase();
  final reg = RegExp(r'(.+?)S(\d{1,2})[^\d]?E(\d{1,2})', caseSensitive: false);
  final regLogo = RegExp('tvg-logo="([^"]*)"', caseSensitive: false);
  for (final line in lines) {
    if (line.startsWith('#EXTINF')) {
      final comma = line.indexOf(',');
      if (comma >= 0 && comma + 1 < line.length) {
        name = line.substring(comma + 1).trim();
      } else {
        name = null;
      }
      final match = regLogo.firstMatch(line);
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
              () => M3uSeries(name: serieName, logo: logo ?? '', episodes: []),
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
