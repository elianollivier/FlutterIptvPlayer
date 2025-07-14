import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:android_intent_plus/android_intent.dart';

import '../models/iptv_models.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../widgets/item_card.dart';
import 'item_form_screen.dart';
import 'playlist_list_screen.dart';
import 'package:reorderables/reorderables.dart';

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

  bool _isViewableMedia(IptvItem item) {
    if (item.type != IptvItemType.media) return false;
    if (item.links.isEmpty) return false;
    return item.links.every((l) {
      final url = l.url.toLowerCase();
      return url.endsWith('.mp4') || url.endsWith('.mkv');
    });
  }

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
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (c) => ItemFormScreen(parentId: widget.parentId),
      ),
    );
    if (result != null) {
      if (result is Map) {
        final item = result['item'] as IptvItem;
        final List<IptvItem> children =
            (result['children'] as List<IptvItem>? ?? []);
        setState(() {
          _allItems.add(item);
          _allItems.addAll(children);
        });
      } else if (result is IptvItem) {
        setState(() {
          _allItems.add(result);
        });
      }
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
    } else if (result is Map) {
      final IptvItem updated = result['item'] as IptvItem;
      final List<IptvItem> children =
          (result['children'] as List<IptvItem>? ?? []);
      final index = _allItems.indexWhere((e) => e.id == updated.id);
      setState(() {
        if (index >= 0) {
          _allItems[index] = updated;
        }
        _allItems.addAll(children);
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

  Future<void> _playMedia(IptvItem item, ChannelLink link) async {
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'action_view',
        data: Uri.encodeFull(link.url),
        package: 'org.videolan.vlc',
        type: 'video/*',
      );
      try {
        await intent.launch();
      } catch (e) {
        _logger.e('Could not open VLC', error: e);
      }
    } else {
      final exePath = await SettingsService().getVlcPath();
      try {
        await Process.start(exePath, [link.url], runInShell: true);
      } catch (e) {
        _logger.e('Could not open VLC', error: e);
      }
    }
    try {
      final index = _allItems.indexWhere((e) => e.id == item.id);
      if (_isViewableMedia(item) && index >= 0 && !_allItems[index].viewed) {
        setState(() {
          _allItems[index] = IptvItem(
            id: item.id,
            type: item.type,
            name: item.name,
            logoPath: item.logoPath,
            logoUrl: item.logoUrl,
            links: item.links,
            parentId: item.parentId,
            viewed: true,
          );
        });
        await _storage.saveItems(_allItems);
      }
    } catch (_) {}
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final childItems =
        _allItems.where((e) => e.parentId == widget.parentId).toList();
    final item = childItems.removeAt(oldIndex);
    childItems.insert(newIndex, item);

    final List<IptvItem> newAll = [];
    int childIndex = 0;
    for (final original in _allItems) {
      if (original.parentId == widget.parentId) {
        newAll.add(childItems[childIndex++]);
      } else {
        newAll.add(original);
      }
    }

    setState(() {
      _allItems = newAll;
    });
    await _storage.saveItems(_allItems);
  }

  @override
  Widget build(BuildContext context) {
    final String title;
    if (widget.parentId == null) {
      title = 'Dossier Central';
    } else {
      final parent = _allItems.any((e) => e.id == widget.parentId)
          ? _allItems.firstWhere((e) => e.id == widget.parentId)
          : null;
      title = parent?.name ?? 'Dossier';
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_play),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PlaylistListScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final count =
              (constraints.maxWidth / 160).round().clamp(1, 6).toInt();
          final itemWidth =
              ((constraints.maxWidth - (count - 1) * 8) - 12) / count;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(5),
            child: ReorderableWrap(
              spacing: 8,
              runSpacing: 8,
              onReorder: _reorder,
              needsLongPressDraggable: false,
              reorderAnimationDuration: const Duration(milliseconds: 250),
              buildDraggableFeedback: (context, constraints, child) => Material(
                color: Colors.transparent,
                child: child,
              ),
              children: [
                for (final item in _items)
                  SizedBox(
                    key: ValueKey(item.id),
                    width: itemWidth,
                    child: ItemCard(
                      item: item,
                      onEdit: () => _editItem(item),
                      onOpenFolder: item.type == IptvItemType.folder
                          ? () => _openFolder(item)
                          : null,
                      onOpenLink: item.type == IptvItemType.media
                          ? (link) => _playMedia(item, link)
                          : null,
                    ),
                  ),
              ],
            ),
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
