import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class Settings {
  Settings({this.vlcPath});

  final String? vlcPath;

  factory Settings.fromJson(Map<String, dynamic> json) =>
      Settings(vlcPath: json['vlcPath'] as String?);

  Map<String, dynamic> toJson() => {
        'vlcPath': vlcPath,
      };
}

class SettingsService {
  final Logger _logger = Logger();

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/settings.json');
  }

  Future<Settings> load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return Settings();
      final data = await file.readAsString();
      return Settings.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (e) {
      _logger.e('Load settings failed', error: e);
      return Settings();
    }
  }

  Future<void> save(Settings settings) async {
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(settings.toJson()));
    } catch (e) {
      _logger.e('Save settings failed', error: e);
    }
  }

  Future<String> getVlcPath() async {
    final settings = await load();
    final stored = settings.vlcPath;
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    return defaultVlcPath();
  }

  static String defaultVlcPath([String? operatingSystem]) {
    final os = (operatingSystem ?? Platform.operatingSystem).toLowerCase();
    if (os == 'windows') {
      return r'C:\Program Files\VideoLAN\VLC\vlc.exe';
    } else if (os == 'macos') {
      return '/Applications/VLC.app/Contents/MacOS/VLC';
    } else {
      return '/usr/bin/vlc';
    }
  }
}
