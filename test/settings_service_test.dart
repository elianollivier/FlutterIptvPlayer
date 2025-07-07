import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_iptv_player/src/services/settings_service.dart';

void main() {
  group('SettingsService.defaultVlcPath', () {
    test('returns platform specific defaults', () {
      expect(
        SettingsService.defaultVlcPath('windows'),
        r'C:\Program Files\VideoLAN\VLC\vlc.exe',
      );
      expect(SettingsService.defaultVlcPath('linux'), '/usr/bin/vlc');
      expect(
        SettingsService.defaultVlcPath('macos'),
        '/Applications/VLC.app/Contents/MacOS/VLC',
      );
    });
  });
}
