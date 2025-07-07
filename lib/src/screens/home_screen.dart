import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../models/iptv_models.dart';
import '../services/storage_service.dart';
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

  Future<void> _openChannel(IptvItem channel, {int index = 0}) async {
    if (channel.links.isEmpty) return;
    if (index >= channel.links.length) index = 0;
    final link = channel.links[index].url;
    const exePath = r'C:\Program Files\VideoLAN\VLC\vlc.exe';
    try {
      await Process.start(exePath, [link], runInShell: true);
    } catch (e) {
      _logger.e('Could not open VLC', error: e);
    }
  }

  Future<void> _editLink(IptvItem channel, {ChannelLink? link, int? index}) async {
    final nameCtrl = TextEditingController(text: link?.name ?? '');
    final urlCtrl = TextEditingController(text: link?.url ?? '');
    final resCtrl = TextEditingController(text: link?.resolution ?? '');
    final fpsCtrl = TextEditingController(text: link?.fps ?? '');
    final notesCtrl = TextEditingController(text: link?.notes ?? '');

    final result = await showDialog<ChannelLink>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL')),
            TextField(controller: resCtrl, decoration: const InputDecoration(labelText: 'Resolution')),
            TextField(controller: fpsCtrl, decoration: const InputDecoration(labelText: 'FPS')),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
                ChannelLink(
                  name: nameCtrl.text,
                  url: urlCtrl.text,
                  resolution: resCtrl.text,
                  fps: fpsCtrl.text,
                  notes: notesCtrl.text,
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null) {
      final chIndex = _allItems.indexWhere((e) => e.id == channel.id);
      if (chIndex < 0) return;
      final newLinks = List<ChannelLink>.from(channel.links);
      if (index == null) {
        newLinks.add(result);
      } else {
        newLinks[index] = result;
      }
      setState(() {
        _allItems[chIndex] = channel.copyWith(links: newLinks);
      });
      await _storage.saveItems(_allItems);
    }
  }

  Future<void> _deleteLink(IptvItem channel, int index) async {
    final chIndex = _allItems.indexWhere((e) => e.id == channel.id);
    if (chIndex < 0) return;
    final newLinks = List<ChannelLink>.from(channel.links)..removeAt(index);
    setState(() {
      _allItems[chIndex] = channel.copyWith(links: newLinks);
    });
    await _storage.saveItems(_allItems);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.parentId == null
        ? 'Dossier Central'
        : (() {
            final index = _allItems.indexWhere((e) => e.id == widget.parentId);
            return index >= 0 ? _allItems[index].name : '';
          })();
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
                onAddLink:
                    item.type == IptvItemType.channel ? () => _editLink(item) : null,
                onEditLink: item.type == IptvItemType.channel
                    ? (link, index) => _editLink(item, link: link, index: index)
                    : null,
                onDeleteLink: item.type == IptvItemType.channel
                    ? (index) => _deleteLink(item, index)
                    : null,
                onSelectLink: item.type == IptvItemType.channel
                    ? (index) => _openChannel(item, index: index)
                    : null,
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
