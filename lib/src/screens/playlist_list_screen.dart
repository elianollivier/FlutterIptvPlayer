import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/m3u_playlist.dart';
import '../services/m3u_playlist_service.dart';
import '../widgets/logo_picker_dialog.dart';

class PlaylistListScreen extends StatefulWidget {
  const PlaylistListScreen({super.key});

  @override
  State<PlaylistListScreen> createState() => _PlaylistListScreenState();
}

class _PlaylistListScreenState extends State<PlaylistListScreen> {
  final M3uPlaylistService _service = const M3uPlaylistService();
  List<M3uPlaylist> _playlists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _service.load();
    if (!mounted) return;
    setState(() {
      _playlists = list;
      _loading = false;
    });
  }

  Future<void> _addPlaylist() async {
    final result = await showDialog<_AddPlaylistResult>(
      context: context,
      builder: (_) => const _AddPlaylistDialog(),
    );
    if (result == null) return;
    final newItem = M3uPlaylist(
      id: const Uuid().v4(),
      name: result.name,
      path: result.path,
      logoPath: result.logo,
    );
    setState(() {
      _playlists.add(newItem);
    });
    await _service.save(_playlists);
  }

  void _select(M3uPlaylist pl) {
    Navigator.pop(context, pl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final item = _playlists[index];
                return ListTile(
                  leading: item.logoPath != null
                      ? Image.file(File(item.logoPath!), width: 32)
                      : const Icon(Icons.list),
                  title: Text(item.name),
                  onTap: () => _select(item),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPlaylist,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddPlaylistResult {
  _AddPlaylistResult({required this.path, required this.name, this.logo});
  final String path;
  final String name;
  final String? logo;
}

class _AddPlaylistDialog extends StatefulWidget {
  const _AddPlaylistDialog();

  @override
  State<_AddPlaylistDialog> createState() => _AddPlaylistDialogState();
}

class _AddPlaylistDialogState extends State<_AddPlaylistDialog> {
  final M3uPlaylistService _service = const M3uPlaylistService();
  final _nameCtrl = TextEditingController();
  String? _path;
  String? _logo;
  double _progress = 0;
  bool _downloading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _pickLogo() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const LogoPickerDialog(),
    );
    if (result != null) setState(() => _logo = result);
  }

  Future<void> _importFile() async {
    final path = await _service.importLocalFile();
    if (path != null) setState(() => _path = path);
  }

  Future<void> _download() async {
    final urlCtrl = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Download Playlist'),
        content: TextField(
          controller: urlCtrl,
          decoration: const InputDecoration(labelText: 'URL'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, urlCtrl.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (url == null || url.isEmpty) return;
    setState(() {
      _downloading = true;
      _progress = 0;
    });
    final path = await _service.downloadFile(url, (p) {
      setState(() => _progress = p);
    });
    setState(() {
      _downloading = false;
      _progress = 0;
      _path = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _logo == null
                        ? const Text('No logo')
                        : Text(_logo!),
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: _pickLogo,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _path == null
                        ? const Text('No file')
                        : Text(_path!),
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    onPressed: _importFile,
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: _download,
                  ),
                ],
              ),
              if (_downloading)
                LinearProgressIndicator(value: _progress),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _path == null || !_formKey.currentState!.validate()
                        ? null
                        : () => Navigator.pop(
                              context,
                              _AddPlaylistResult(
                                path: _path!,
                                name: _nameCtrl.text,
                                logo: _logo,
                              ),
                            ),
                    child: const Text('Add'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
