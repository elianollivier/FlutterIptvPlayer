import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_iptv_player/src/services/m3u_service.dart';

void main() {
  test('parses m3u file', () async {
    final file = File('${Directory.systemTemp.path}/sample.m3u');
    await file.writeAsString('#EXTM3U\n#EXTINF:-1,Channel 1\nhttp://example.com/1');
    final service = const M3uService();
    final result = await service.loadFile(file.path);
    expect(result.length, 1);
    expect(result.first.name, 'Channel 1');
    expect(result.first.url, 'http://example.com/1');
    await file.delete();
  });
}
