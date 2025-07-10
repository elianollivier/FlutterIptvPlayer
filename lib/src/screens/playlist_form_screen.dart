import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/m3u_playlist.dart';
import '../services/m3u_playlist_service.dart';
import '../widgets/logo_picker_dialog.dart';

class PlaylistFormScreen extends StatefulWidget {
  const PlaylistFormScreen({super.key, this.playlist});

  final M3uPlaylist? playlist;

  @override
  State<PlaylistFormScreen> createState() => _PlaylistFormScreenState();
}

class _PlaylistFormScreenState extends State<PlaylistFormScreen> {
  final M3uPlaylistService _service = const M3uPlaylistService();
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String? _path;
  String? _logo;
  DateTime? _lastDownload;
  double _progress = 0;
  bool _downloading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final pl = widget.playlist;
    if (pl != null) {
      _nameCtrl.text = pl.name;
      _urlCtrl.text = pl.url ?? '';
      _path = pl.path;
      _logo = pl.logoPath;
      _lastDownload = pl.lastDownload;
    }
  }

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
    final url = _urlCtrl.text;
    if (url.isEmpty) return;
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
      if (path != null) {
        _path = path;
        _lastDownload = DateTime.now();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.playlist != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Playlist' : 'New Playlist'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlCtrl,
                decoration: const InputDecoration(labelText: 'URL'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _logo == null ? const Text('No logo') : Text(_logo!),
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: _pickLogo,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _path == null ? const Text('No file') : Text(_path!),
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
              if (_lastDownload != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Last download: '
                    '${DateFormat.yMd().add_Hm().format(_lastDownload!)}',
                  ),
                ),
              if (_downloading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(value: _progress),
                ),
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
                    onPressed: _path == null
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              Navigator.pop(
                                context,
                                M3uPlaylist(
                                  id: widget.playlist?.id ?? const Uuid().v4(),
                                  name: _nameCtrl.text,
                                  path: _path!,
                                  logoPath: _logo,
                                  url: _urlCtrl.text.isNotEmpty
                                      ? _urlCtrl.text
                                      : null,
                                  lastDownload: _lastDownload,
                                ),
                              );
                            }
                          },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
