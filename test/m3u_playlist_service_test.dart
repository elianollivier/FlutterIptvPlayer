import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:flutter_iptv_player/src/models/m3u_playlist.dart';
import 'package:flutter_iptv_player/src/services/m3u_playlist_service.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  Directory? _temp;

  @override
  Future<String?> getApplicationDocumentsPath() async {
    _temp ??= await Directory.systemTemp.createTemp();
    return _temp!.path;
  }
}

void main() {
  setUp(() {
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });

  test('save and load playlists', () async {
    final service = const M3uPlaylistService();
    final items = [
      M3uPlaylist(id: '1', name: 'Test', path: '/tmp/file.m3u', logoPath: null),
    ];
    await service.save(items);
    final loaded = await service.load();
    expect(loaded.length, 1);
    expect(loaded.first.name, 'Test');
  });
}
