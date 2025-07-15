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
    String? path;
    try {
      path = await _service.downloadFile(url, (p) {
        setState(() => _progress = p);
      });
      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le téléchargement a échoué')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le téléchargement a échoué')),
      );
    }
    if (!mounted) return;
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
        title: Text(isEdit ? 'Modifier la playlist' : 'Nouvelle playlist'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nom',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlCtrl,
                decoration: InputDecoration(
                  labelText: 'URL',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(_logo ?? 'Aucun logo sélectionné'),
                trailing: IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _pickLogo,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(_path ?? 'Aucun fichier sélectionné'),
                trailing: Wrap(
                  spacing: 12,
                  children: [
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
              ),
              if (_lastDownload != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Dernier téléchargement : '
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isEdit)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 241, 156, 150),
                      ),
                      onPressed: () {
                        Navigator.pop(context, {'delete': true});
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Supprimer'),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _path == null
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  Navigator.pop(
                                    context,
                                    M3uPlaylist(
                                      id: widget.playlist?.id ??
                                          const Uuid().v4(),
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
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Enregistrer'),
                      ),
                    ],
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
