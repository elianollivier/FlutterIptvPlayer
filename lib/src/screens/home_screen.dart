import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:android_intent_plus/android_intent.dart';

import '../models/iptv_models.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../services/supabase_service.dart';
import '../services/logo_service.dart';
import '../widgets/item_card.dart';
import 'item_form_screen.dart';
import 'playlist_list_screen.dart';
import 'package:reorderables/reorderables.dart';

class _Crumb {
  final String? id;
  final String name;
  const _Crumb(this.id, this.name);
}

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
  String? _draggingId;

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
    if (widget.parentId == null && SupabaseService.instance.isLoggedIn) {
      _syncLogos();
    }
    _load();
  }

  Future<void> _syncLogos() async {
    await LogoService().syncWithSupabase();
  }

  Future<void> _load() async {
    final data = await _storage.loadItems();
    setState(() {
      _allItems = data;
    });
  }

  void _updatePositions() {
    final Map<String?, int> counters = {};
    _allItems = _allItems.map((item) {
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

  List<IptvItem> get _items {
    List<IptvItem> items =
        _allItems.where((e) => e.parentId == widget.parentId).toList();
    items.sort((a, b) => a.position.compareTo(b.position));
    return items;
  }

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
      _updatePositions();
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
      _updatePositions();
      await _storage.saveItems(_allItems);
      if (SupabaseService.instance.isLoggedIn) {
        await SupabaseService.instance.deleteItems([item.id]);
      }
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
      _updatePositions();
      await _storage.saveItems(_allItems);
    } else if (result is IptvItem) {
      final index = _allItems.indexWhere((e) => e.id == result.id);
      setState(() {
        if (index >= 0) {
          _allItems[index] = result;
        }
      });
      _updatePositions();
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
    final childItems = _allItems
        .where((e) => e.parentId == widget.parentId)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
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
      _draggingId = null;
    });
    _updatePositions();
    await _storage.saveItems(_allItems);
  }

  IptvItem? _findItem(String id) {
    for (final item in _allItems) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<_Crumb> _breadcrumb() {
    final List<_Crumb> res = [const _Crumb(null, 'Dossier Central')];
    String? current = widget.parentId;
    final List<_Crumb> stack = [];
    while (current != null) {
      final item = _findItem(current);
      if (item == null) break;
      stack.add(_Crumb(item.id, item.name));
      current = item.parentId;
    }
    res.addAll(stack.reversed);
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final crumbs = _breadcrumb();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            if (widget.parentId != null)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  final parent = _findItem(widget.parentId!)?.parentId;
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => HomeScreen(parentId: parent),
                      transitionsBuilder: (_, __, ___, child) => child,
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
              )
            else
              const SizedBox(width: kMinInteractiveDimension),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < crumbs.length; i++) ...[
                      InkWell(
                        onTap: i == crumbs.length - 1
                            ? null
                            : () {
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) =>
                                        HomeScreen(parentId: crumbs[i].id),
                                    transitionsBuilder: (_, __, ___, child) =>
                                        child,
                                    transitionDuration: Duration.zero,
                                    reverseTransitionDuration: Duration.zero,
                                  ),
                                );
                              },
                        child: Text(
                          crumbs[i].name,
                          style: TextStyle(
                            color: i == crumbs.length - 1
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      if (i < crumbs.length - 1) const Text(' / '),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
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
              onNoReorder: (index) {
                setState(() {
                  _draggingId = null;
                });
              },
              onReorderStarted: (index) {
                setState(() {
                  _draggingId = _items[index].id;
                });
              },
              needsLongPressDraggable: Platform.isAndroid,
              textDirection: TextDirection.ltr,
              verticalDirection: VerticalDirection.down,
              reorderAnimationDuration: const Duration(milliseconds: 400),
              scrollAnimationDuration: const Duration(milliseconds: 400),
              buildDraggableFeedback: (context, constraints, child) => Material(
                color: Colors.transparent,
                child: Transform.scale(
                  scale: 1.1,
                  child: child,
                ),
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
                      dragging: _draggingId == item.id,
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
