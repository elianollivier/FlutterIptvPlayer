import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../models/iptv_models.dart';

class StorageService {
  StorageService();

  final Logger _logger = Logger();

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/iptv_data.json');
  }

  Future<List<IptvItem>> loadItems() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return [];
      }
      final data = await file.readAsString();
      final jsonList = jsonDecode(data) as List<dynamic>;
      return jsonList
          .map((e) => IptvItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Load failed', error: e);
      return [];
    }
  }

  Future<void> saveItems(List<IptvItem> items) async {
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
    } catch (e) {
      _logger.e('Save failed', error: e);
    }
  }
}
