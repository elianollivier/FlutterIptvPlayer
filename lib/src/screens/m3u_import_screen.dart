import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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

  bool _isDownloadable(ChannelLink link) {
    final url = link.url.toLowerCase();
    return url.endsWith('.mp4') || url.endsWith('.mkv');
  }

  Future<void> _downloadFile(ChannelLink link) async {
    final dir = await getDownloadsDirectory();
    if (dir == null) return;
    final uri = Uri.parse(link.url);
    final name = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last.split('?').first
        : link.name;
    final file = File('${dir.path}/$name');

    double received = 0;
    int total = 0;
    var started = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (!started) {
              started = true;
              () async {
                try {
                  final response =
                      await http.Client().send(http.Request('GET', uri));
                  total = response.contentLength ?? 0;
                  final sink = file.openWrite();
                  await for (final chunk in response.stream) {
                    received += chunk.length;
                    sink.add(chunk);
                    setState(() {});
                  }
                  await sink.close();
                } catch (e) {
                  _logger.e('Download failed', error: e);
                } finally {
                  Navigator.pop(context);
                }
              }();
            }

            final progress = total > 0 ? received / total : null;
            final text = total > 0
                ? '${(received / (1024 * 1024)).toStringAsFixed(2)} MB / '
                    '${(total / (1024 * 1024)).toStringAsFixed(2)} MB'
                : '${(received / (1024 * 1024)).toStringAsFixed(2)} MB';

            return AlertDialog(
              title: Text('Downloading ${link.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text(text),
                ],
              ),
            );
          },
        );
      },
    );
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
                  leading: link.logo.isNotEmpty
                      ? Image.network(
                          link.logo,
                          width: 48,
                          height: 48,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image_not_supported),
                        )
                      : const Icon(Icons.image_not_supported),
                  trailing: isExisting
                      ? const Icon(Icons.check, color: Colors.grey)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isDownloadable(link))
                              IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: () => _downloadFile(link),
                              ),
                            Checkbox(
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
