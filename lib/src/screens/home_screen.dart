import 'dart:io';

import 'package:flutter/material.dart';

import '../models/iptv_models.dart';
import '../services/storage_service.dart';
import 'item_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  List<IptvItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _storage.loadItems();
    setState(() {
      _items = data;
    });
  }

  Future<void> _addItem() async {
    final result = await Navigator.push<IptvItem>(
      context,
      MaterialPageRoute(builder: (c) => const ItemFormScreen()),
    );
    if (result != null) {
      setState(() {
        _items.add(result);
      });
      await _storage.saveItems(_items);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IPTV Player')),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            leading: item.logoPath != null
                ? Image.file(
                    File(item.logoPath!),
                    width: 40,
                    height: 40,
                  )
                : Icon(item.type == IptvItemType.folder
                    ? Icons.folder
                    : Icons.tv),
            title: Text(item.name),
            subtitle: Text(item.type.name),
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
