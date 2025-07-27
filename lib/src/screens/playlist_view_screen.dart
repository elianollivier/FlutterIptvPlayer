import 'dart:io';

import 'package:flutter/material.dart';
import '../widgets/logo_image.dart';
import 'package:logger/logger.dart';

import '../models/iptv_models.dart';
import '../models/m3u_playlist.dart';
import '../services/m3u_service.dart';
import '../services/settings_service.dart';

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
    final currentQuery = _query;
    setState(() => _loading = true);
    final list = await _service.searchFile(
      widget.playlist.path,
      query: currentQuery,
    );
    if (!mounted || currentQuery != _query) return;
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
                      ? LogoImage(
                          path: link.logo,
                          width: 64,
                          height: 64,
                          errorWidget:
                              const Icon(Icons.image_not_supported),
                        )
                      : const Icon(Icons.image_not_supported),
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
