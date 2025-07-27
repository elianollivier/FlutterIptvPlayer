import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:flutter_iptv_player/src/services/logo_service.dart';

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

  test('listLogos reads local directory when present', () async {
    final service = LogoService();
    final dir = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/logos');
    await dir.create(recursive: true);
    final file = File('${dir.path}/logo.png');
    await file.writeAsString('test');

    final logos = await service.listLogos();

    expect(logos, contains(file.path));
  });
}
