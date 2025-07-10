import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../models/iptv_models.dart';
import '../models/m3u_playlist.dart';
import '../services/m3u_service.dart';
import '../services/settings_service.dart';
import '../services/download_service.dart';

class PlaylistViewScreen extends StatefulWidget {
  const PlaylistViewScreen({super.key, required this.playlist});

  final M3uPlaylist playlist;

  @override
  State<PlaylistViewScreen> createState() => _PlaylistViewScreenState();
}

class _PlaylistViewScreenState extends State<PlaylistViewScreen> {
  final M3uService _service = const M3uService();
  final Logger _logger = Logger();
  final TextEditingController _queryCtrl = TextEditingController();

  List<ChannelLink> _links = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.searchFile(
      widget.playlist.path,
      query: _query,
    );
    if (!mounted) return;
    setState(() {
      _links = list;
      _loading = false;
    });
  }

  Future<void> _openLink(String url) async {
    final exePath = await SettingsService().getVlcPath();
    try {
      await Process.start(exePath, [url], runInShell: true);
    } catch (e) {
      _logger.e('Could not open VLC', error: e);
    }
  }

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
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _queryCtrl,
              decoration: const InputDecoration(labelText: 'Rechercher'),
              onChanged: (v) {
                setState(() => _query = v);
                if (v.isEmpty || v.length >= 3) {
                  _load();
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
                return ListTile(
                  minVerticalPadding: 8,
                  leading: link.logo.isNotEmpty
                      ? Image.network(
                          link.logo,
                          width: 64,
                          height: 64,
                          errorBuilder: (_, __, ___) =>
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
                    ],
                  ),
                  title: Text(link.name),
                  subtitle: Text(link.url),
                  onTap: () => _openLink(link.url),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
