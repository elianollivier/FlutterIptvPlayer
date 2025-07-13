import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_iptv_player/src/services/m3u_service.dart';

void main() {
  test('loadSeries groups episodes by series', () async {
    final file = File('${Directory.systemTemp.path}/series_test.m3u');
    await file.writeAsString(
      '#EXTM3U\n'
      '#EXTINF:-1 tvg-logo="1.png",Show One S01 E01\n'
      'http://example.com/1\n'
      '#EXTINF:-1 tvg-logo="1.png",Show One S01 E02\n'
      'http://example.com/2\n'
      '#EXTINF:-1 tvg-logo="2.png",Show Two S02 E01\n'
      'http://example.com/3\n',
    );
    final service = const M3uService();
    final result = await service.loadSeries(file.path);
    expect(result.length, 2);
    final one = result.firstWhere((e) => e.name == 'Show One');
    expect(one.episodes.length, 2);
    await file.delete();
  });
}
