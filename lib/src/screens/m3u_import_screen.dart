import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../models/iptv_models.dart';
import '../services/m3u_service.dart';
import '../services/settings_service.dart';

class M3uImportScreen extends StatefulWidget {
  const M3uImportScreen({
    super.key,
    required this.path,
    this.existingLinks = const [],
  });

  final String path;
  final List<ChannelLink> existingLinks;

  @override
  State<M3uImportScreen> createState() => _M3uImportScreenState();
}

class _M3uImportScreenState extends State<M3uImportScreen> {
  final M3uService _service = const M3uService();
  final Logger _logger = Logger();
  late TextEditingController _queryCtrl;
  List<ChannelLink> _links = [];
  final Set<ChannelLink> _selected = {};
  late final Set<String> _existingUrls;
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController();
    _existingUrls =
        widget.existingLinks.map((e) => e.url.toLowerCase()).toSet();
    _search();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _openLink(String url) async {
    final exePath = await SettingsService().getVlcPath();
    try {
      await Process.start(exePath, [url], runInShell: true);
    } catch (e) {
      _logger.e('Could not open VLC', error: e);
    }
  }

  Future<void> _search() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final list = await _service.searchFile(
      widget.path,
      query: _query,
      limit: 150,
    );
    if (!mounted) return;
    setState(() {
      _links = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select channels'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _queryCtrl,
              decoration: const InputDecoration(labelText: 'Search'),
              onChanged: (v) {
                setState(() => _query = v);
                if (v.isEmpty || v.length >= 3) {
                  _search();
                }
              },
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _links.length,
              itemBuilder: (context, index) {
                final link = _links[index];
                final isExisting =
                    _existingUrls.contains(link.url.toLowerCase());
                final selected = _selected.contains(link);
                return ListTile(
                  enabled: !isExisting,
                  leading: isExisting
                      ? const Icon(Icons.check, color: Colors.grey)
                      : Checkbox(
                          value: selected,
                          onChanged: (_) {
                            setState(() {
                              if (selected) {
                                _selected.remove(link);
                              } else {
                                _selected.add(link);
                              }
                            });
                          },
                        ),
                  title: Text(
                    link.name,
                    style:
                        isExisting ? const TextStyle(color: Colors.grey) : null,
                  ),
                  subtitle: Text(link.url,
                      style: isExisting
                          ? const TextStyle(color: Colors.grey)
                          : null),
                  onTap: isExisting ? null : () => _openLink(link.url),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context, _selected.toList());
                    },
              child: const Text('Add Selected'),
            ),
          )
        ],
      ),
    );
  }
}
