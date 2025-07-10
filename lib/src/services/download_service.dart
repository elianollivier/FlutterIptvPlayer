import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../models/download_task.dart';

class DownloadService {
  DownloadService._();

  static final DownloadService instance = DownloadService._();

  final Logger _logger = Logger();

  final ValueNotifier<List<DownloadTask>> tasks = ValueNotifier<List<DownloadTask>>([]);

  void _notify() {
    tasks.value = List<DownloadTask>.from(tasks.value);
  }

  Future<DownloadTask?> download(String url, String name) async {
    final dir = await getDownloadsDirectory();
    if (dir == null) return null;
    final file = File('${dir.path}/$name');
    final task = DownloadTask(url: url, file: file, name: name);
    tasks.value = [...tasks.value, task];
    _notify();
    _start(task);
    return task;
  }

  Future<void> _start(DownloadTask task) async {
    try {
      final response = await http.Client().send(http.Request('GET', Uri.parse(task.url)));
      task.total = response.contentLength ?? 0;
      final sink = task.file.openWrite();
      await for (final chunk in response.stream) {
        if (task.cancelled) {
          await sink.close();
          if (await task.file.exists()) await task.file.delete();
          task.status = DownloadStatus.cancelled;
          _notify();
          return;
        }
        task.received += chunk.length;
        sink.add(chunk);
        _notify();
      }
      await sink.close();
      task.status = DownloadStatus.completed;
      _notify();
    } catch (e) {
      _logger.e('Download failed', error: e);
      task.status = DownloadStatus.failed;
      _notify();
    }
  }

  void cancel(DownloadTask task) {
    task.cancelled = true;
    _notify();
  }
}
