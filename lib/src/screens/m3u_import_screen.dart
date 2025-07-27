import 'dart:io';

import 'package:flutter/material.dart';
import '../widgets/logo_image.dart';
import 'package:logger/logger.dart';
import '../services/download_service.dart';

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
  final Map<String, ChannelLink> _selected = {};
  late final Set<String> _existingUrls;
  bool _loading = true;
  String _query = '';
  int _searchId = 0;

  bool _isDownloadable(ChannelLink link) {
    final url = link.url.toLowerCase();
    return url.endsWith('.mp4') || url.endsWith('.mkv');
  }

  Future<void> _downloadFile(ChannelLink link) async {
    final uri = Uri.parse(link.url);
    final name = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last.split('?').first
        : link.name;
    await DownloadService.instance.download(link.url, name);
  }

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
    final int current = ++_searchId;
    if (!mounted) return;
    setState(() => _loading = true);
    final list = await _service.searchFile(
      widget.path,
      query: _query,
      limit: 150,
    );
    if (!mounted || current != _searchId) return;
    setState(() {
      _links = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner des chaînes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _queryCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
              onSubmitted: (_) => _search(),
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
                final selected = _selected.containsKey(link.url);
                return ListTile(
                  enabled: !isExisting,
                  minVerticalPadding: 8,
                  leading: link.logo.isNotEmpty
                      ? LogoImage(
                          path: link.logo,
                          width: 64,
                          height: 64,
                          errorWidget:
                              const Icon(Icons.image_not_supported),
                        )
                      : const Icon(Icons.image_not_supported),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isDownloadable(link))
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => _downloadFile(link),
                        ),
                      if (isExisting)
                        const Icon(Icons.check, color: Colors.grey)
                      else
                        Checkbox(
                          value: selected,
                          onChanged: (_) {
                            setState(() {
                              if (selected) {
                                _selected.remove(link.url);
                              } else {
                                _selected[link.url] = link;
                              }
                            });
                          },
                        ),
                    ],
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
                      Navigator.pop(context, _selected.values.toList());
                    },
              child: const Text('Ajouter la sélection'),
            ),
          )
        ],
      ),
    );
  }
}
