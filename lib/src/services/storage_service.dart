import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../models/iptv_models.dart';
import 'supabase_service.dart';

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
        final items = SupabaseService.instance.isLoggedIn
            ? await SupabaseService.instance.fetchItems()
            : <IptvItem>[];
        return _sort(items);
      }
      final data = await file.readAsString();
      final jsonList = jsonDecode(data) as List<dynamic>;
      var items = jsonList
          .map((e) => IptvItem.fromJson(e as Map<String, dynamic>))
          .toList();
      if (SupabaseService.instance.isLoggedIn) {
        try {
          items = await SupabaseService.instance.fetchItems();
          await saveItems(items);
        } catch (e) {
          _logger.e('Remote load failed', error: e);
        }
      }
      return _sort(items);
    } catch (e) {
      _logger.e('Load failed', error: e);
      return [];
    }
  }

  Future<void> saveItems(List<IptvItem> items) async {
    try {
      items = _applyPositions(items);
      final file = await _getFile();
      await file.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
      if (SupabaseService.instance.isLoggedIn) {
        await SupabaseService.instance.saveItems(items);
      }
    } catch (e) {
      _logger.e('Save failed', error: e);
    }
  }

  List<IptvItem> _sort(List<IptvItem> items) {
    items.sort((a, b) {
      final pComp = (a.parentId ?? '').compareTo(b.parentId ?? '');
      if (pComp != 0) return pComp;
      return a.position.compareTo(b.position);
    });
    return items;
  }

  List<IptvItem> _applyPositions(List<IptvItem> items) {
    final Map<String?, int> counters = {};
    return items.map((item) {
      final index = counters[item.parentId] ?? 0;
      counters[item.parentId] = index + 1;
      return IptvItem(
        id: item.id,
        type: item.type,
        name: item.name,
        logoPath: item.logoPath,
        logoUrl: item.logoUrl,
        links: item.links,
        parentId: item.parentId,
        viewed: item.viewed,
        position: index,
      );
    }).toList();
  }
}
