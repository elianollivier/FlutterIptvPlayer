import 'dart:io';

enum DownloadStatus { downloading, completed, cancelled, failed }

class DownloadTask {
  DownloadTask({required this.url, required this.file, required this.name});

  final String url;
  final File file;
  final String name;
  DownloadStatus status = DownloadStatus.downloading;
  int received = 0;
  int total = 0;
  final DateTime start = DateTime.now();
  bool cancelled = false;

  double get progress => total > 0 ? received / total : 0;

  Duration get elapsed => DateTime.now().difference(start);

  Duration? get remaining {
    if (received == 0 || total == 0) return null;
    final int elapsedSeconds = elapsed.inSeconds == 0 ? 1 : elapsed.inSeconds;
    final double speed = received / elapsedSeconds;
    if (speed <= 0) return null;
    final double seconds = (total - received) / speed;
    if (seconds.isNaN || !seconds.isFinite) return null;
    return Duration(seconds: seconds.round());
  }
}
