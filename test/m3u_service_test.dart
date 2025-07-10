import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_iptv_player/src/services/m3u_service.dart';

void main() {
  test('parses m3u file', () async {
    final file = File('${Directory.systemTemp.path}/sample.m3u');
    await file.writeAsString(
      '#EXTM3U\n'
      '#EXTINF:-1 tvg-logo="http://logo.png",Channel 1\n'
      'http://example.com/1',
    );
    final service = const M3uService();
    final result = await service.loadFile(file.path);
    expect(result.length, 1);
    expect(result.first.name, 'Channel 1');
    expect(result.first.url, 'http://example.com/1');
    expect(result.first.logo, 'http://logo.png');
    await file.delete();
  });

  test('searchFile limits results and filters by name', () async {
    final file = File('${Directory.systemTemp.path}/sample_search.m3u');
    await file.writeAsString(
      '#EXTM3U\n'
      '#EXTINF:-1 tvg-logo="1.png",Channel 1\nhttp://example.com/1\n'
      '#EXTINF:-1 tvg-logo="2.png",Another\nhttp://example.com/2\n'
      '#EXTINF:-1 tvg-logo="3.png",Channel 3\nhttp://example.com/3',
    );
    final service = const M3uService();
    final result = await service.searchFile(
      file.path,
      query: 'channel',
      limit: 1,
    );
    expect(result.length, 1);
    expect(result.first.name.contains('Channel'), isTrue);
    await file.delete();
  });

  test('searchFile uses default limit of 150', () async {
    final file = File('${Directory.systemTemp.path}/sample_limit.m3u');
    final buffer = StringBuffer('#EXTM3U\n');
    for (var i = 0; i < 200; i++) {
      buffer.writeln('#EXTINF:-1 tvg-logo="$i.png",Channel $i');
      buffer.writeln('http://example.com/$i');
    }
    await file.writeAsString(buffer.toString());
    final service = const M3uService();
    final result = await service.searchFile(file.path);
    expect(result.length, 150);
    await file.delete();
  });
}
