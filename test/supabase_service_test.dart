import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart';

import 'package:flutter_iptv_player/src/services/supabase_service.dart';

class _FakeAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _map = {};

  @override
  Future<String?> getItem({required String key}) async => _map[key];

  @override
  Future<void> removeItem({required String key}) async {
    _map.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _map[key] = value;
  }
}

void main() {
  group('SupabaseService.uploadLogo', () {
    final requests = <Uri>[];

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final client = MockClient((Request request) async {
        requests.add(request.url);
        return Response(jsonEncode({'Key': 'public/test'}), 200);
      });
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        anonKey: 'key',
        httpClient: client,
        debug: false,
        authOptions: FlutterAuthClientOptions(
          localStorage: const EmptyLocalStorage(),
          pkceAsyncStorage: _FakeAsyncStorage(),
        ),
      );
    });

    tearDown(() async {
      requests.clear();
      await Supabase.instance.dispose();
    });

    test('uploads logo using generated name', () async {
      final file = File('${Directory.systemTemp.path}/Mon logo épatant.png');
      await file.writeAsString('dummy');

      final url = await SupabaseService.instance.uploadLogo(file);

      expect(url, contains('/logos/public/'));
      expect(url, endsWith('.png'));
      expect(requests.single.toString(), contains('/logos/public/'));

      await file.delete();
    });
  });
}
