import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../models/iptv_models.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../widgets/item_card.dart';
import 'item_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.parentId});

  final String? parentId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final Logger _logger = Logger();
  List<IptvItem> _allItems = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _storage.loadItems();
    setState(() {
      _allItems = data;
    });
  }

  List<IptvItem> get _items =>
      _allItems.where((e) => e.parentId == widget.parentId).toList();

  Future<void> _addItem() async {
    final result = await Navigator.push<IptvItem>(
      context,
      MaterialPageRoute(
        builder: (c) => ItemFormScreen(parentId: widget.parentId),
      ),
    );
    if (result != null) {
      setState(() {
        _allItems.add(result);
      });
      await _storage.saveItems(_allItems);
    }
  }

  Future<void> _editItem(IptvItem item) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (c) => ItemFormScreen(item: item),
      ),
    );
    if (result is Map && result['delete'] == true) {
      setState(() {
        _allItems.removeWhere((e) => e.id == item.id);
      });
      await _storage.saveItems(_allItems);
    } else if (result is IptvItem) {
      final index = _allItems.indexWhere((e) => e.id == result.id);
      setState(() {
        if (index >= 0) {
          _allItems[index] = result;
        }
      });
      await _storage.saveItems(_allItems);
    }
  }

  Future<void> _openFolder(IptvItem folder) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => HomeScreen(parentId: folder.id),
      ),
    );
    await _load();
  }

  Future<void> _openChannel(IptvItem channel) async {
    if (channel.links.isEmpty) return;
    final link = channel.links.first.url;
    final exePath = await SettingsService().getVlcPath();
    try {
      await Process.start(exePath, [link], runInShell: true);
    } catch (e) {
      _logger.e('Could not open VLC', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.parentId == null
        ? 'Dossier Central'
        : _allItems.firstWhere((e) => e.id == widget.parentId!).name;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final count =
              (constraints.maxWidth / 160).floor().clamp(1, 6).toInt();
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: count,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return ItemCard(
                item: item,
                onTap: () {
                  if (item.type == IptvItemType.folder) {
                    _openFolder(item);
                  } else {
                    _openChannel(item);
                  }
                },
                onEdit: () => _editItem(item),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}
