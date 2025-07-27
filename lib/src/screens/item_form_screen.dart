import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import 'm3u_import_screen.dart';
import 'playlist_list_screen.dart';
import '../models/m3u_playlist.dart';
import 'series_list_screen.dart';

import '../widgets/link_label.dart';
import '../widgets/logo_picker_dialog.dart';
import '../models/iptv_models.dart';
import '../services/download_service.dart';
import '../services/settings_service.dart';
import '../models/m3u_series.dart';

class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key, this.item, this.parentId});

  final IptvItem? item;
  final String? parentId;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Logger _logger = Logger();
  late IptvItemType _type;
  late TextEditingController _nameCtrl;
  String? _logoPath;
  String? _logoUrl;
  List<ChannelLink> _links = [];
  M3uSeries? _series;
  bool _viewed = false;

  String get _logoLabel {
    final path = _logoPath ?? _logoUrl;
    return path != null ? path.split('/').last : 'Aucun logo sélectionné';
  }

  bool _onlyFileLinks(List<ChannelLink> links) {
    if (links.isEmpty) return false;
    return links.every((l) {
      final url = l.url.toLowerCase();
      return url.endsWith('.mp4') || url.endsWith('.mkv');
    });
  }

  bool get _canBeViewed =>
      _type == IptvItemType.media && _onlyFileLinks(_links);

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

  Future<void> _openLink(String url) async {
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'action_view',
        data: Uri.encodeFull(url),
        package: 'org.videolan.vlc',
        type: 'video/*',
      );
      try {
        await intent.launch();
      } catch (e) {
        _logger.e('Could not open VLC', error: e);
      }
    } else {
      final exePath = await SettingsService().getVlcPath();
      try {
        await Process.start(exePath, [url], runInShell: true);
      } catch (e) {
        _logger.e('Could not open VLC', error: e);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _type = widget.item?.type ?? IptvItemType.folder;
    _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    _logoPath = widget.item?.logoPath;
    _logoUrl = widget.item?.logoUrl;
    _links = List.of(widget.item?.links ?? []);
    _viewed = widget.item?.viewed ?? false;
  }

  IptvItem _buildItem() {
    return IptvItem(
      id: widget.item?.id ?? const Uuid().v4(),
      type: _type,
      name: _nameCtrl.text,
      logoPath: _logoPath,
      logoUrl: _logoUrl,
      links: _links,
      parentId: widget.parentId ?? widget.item?.parentId,
      viewed: _canBeViewed ? _viewed : false,
      position: widget.item?.position ?? 0,
    );
  }

  List<IptvItem> _buildSeriesItems(String parentId) {
    if (_series == null) return [];
    final List<IptvItem> items = [];
    final Map<int, List<M3uEpisode>> bySeason = {};
    for (final ep in _series!.episodes) {
      bySeason.putIfAbsent(ep.season, () => []).add(ep);
    }
    for (final season in bySeason.keys) {
      final seasonId = const Uuid().v4();
      items.add(IptvItem(
        id: seasonId,
        type: IptvItemType.folder,
        name: 'Saison $season',
        logoUrl: _series!.logo,
        parentId: parentId,
      ));
      for (final ep in bySeason[season]!) {
        final epLabel =
            'S${ep.season.toString().padLeft(2, '0')} E${ep.episode.toString().padLeft(2, '0')}';
        items.add(IptvItem(
          id: const Uuid().v4(),
          type: IptvItemType.media,
          name: epLabel,
          logoUrl: ep.logo,
          links: [
            ChannelLink(
              name: epLabel,
              url: ep.url,
              logo: ep.logo,
              resolution: '',
              fps: '',
              notes: const [],
            ),
          ],
          parentId: seasonId,
          viewed: false,
        ));
      }
    }
    return items;
  }

  Future<void> _pickLogo() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const LogoPickerDialog(),
    );
    if (result != null) {
      setState(() {
        _logoPath = null;
        _logoUrl = result;
      });
    }
  }

  Future<void> _editLink({ChannelLink? link, int? index}) async {
    final nameCtrl = TextEditingController(text: link?.name ?? '');
    final urlCtrl = TextEditingController(text: link?.url ?? '');
    final resCtrl = TextEditingController(text: link?.resolution ?? '');
    final fpsValue = int.tryParse(link?.fps ?? '');
    final fpsCtrl = TextEditingController(
      text: fpsValue != null ? '$fpsValue' : '',
    );
    final List<Map<String, Object>> notesData =
        (link?.notes ?? [])
            .map((n) => <String, Object>{
                  'ctrl': TextEditingController(text: n.text),
                  'date': n.date,
                })
            .toList();

    const resolutions = [
      '4K',
      'FHD',
      'HD',
      '540p',
      '480p',
      '240p',
    ];

    final result = await showDialog<ChannelLink>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Lien'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(labelText: 'URL'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: resolutions.contains(resCtrl.text) ? resCtrl.text : null,
                  items: resolutions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  decoration: InputDecoration(
                    labelText: 'Résolution',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  isExpanded: true,
                  onChanged: (v) => resCtrl.text = v ?? '',
                  dropdownColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fpsCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'FPS'),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < notesData.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: notesData[i]['ctrl'] as TextEditingController,
                                decoration:
                                    const InputDecoration(labelText: 'Note'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  locale: const Locale('fr', 'FR'),
                                  initialDate: notesData[i]['date'] as DateTime,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() => notesData[i]['date'] = picked);
                                }
                              },
                              child: Text(
                                DateFormat.yMd('fr_FR')
                                    .format(notesData[i]['date'] as DateTime),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  setState(() => notesData.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          notesData.add(<String, Object>{
                            'ctrl': TextEditingController(),
                            'date': DateTime.now(),
                          });
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter une note'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  ChannelLink(
                    name: nameCtrl.text,
                    url: urlCtrl.text,
                    resolution: resCtrl.text,
                    fps: fpsCtrl.text,
                    notes: notesData
                        .map((e) => Note(
                              text: (e['ctrl'] as TextEditingController).text,
                              date: e['date'] as DateTime,
                            ))
                        .toList(),
                  ),
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (index == null) {
          _links.add(result);
        } else {
          _links[index] = result;
        }
        if (!_canBeViewed) _viewed = false;
      });
    }
  }

  Future<void> _importM3u() async {
    final playlist = await Navigator.push<M3uPlaylist>(
      context,
      MaterialPageRoute(
        builder: (_) => const PlaylistListScreen(selectMode: true),
      ),
    );
    if (playlist == null) return;
    final imported = await Navigator.push<List<ChannelLink>>(
      context,
      MaterialPageRoute(
        builder: (_) => M3uImportScreen(
          path: playlist.path,
          existingLinks: _links,
        ),
      ),
    );
    if (imported != null && imported.isNotEmpty) {
      setState(() {
        _links.addAll(imported);
        if (_logoPath == null && _logoUrl == null) {
          final firstLogo = imported.firstWhere(
            (e) => e.logo.isNotEmpty,
            orElse: () => imported.first,
          );
          if (firstLogo.logo.isNotEmpty) _logoUrl = firstLogo.logo;
        }
        if (!_canBeViewed) _viewed = false;
      });
    }
  }

  Future<void> _importSeries() async {
    final playlist = await Navigator.push<M3uPlaylist>(
      context,
      MaterialPageRoute(
        builder: (_) => const PlaylistListScreen(selectMode: true),
      ),
    );
    if (playlist == null) return;
    final serie = await Navigator.push<M3uSeries>(
      context,
      MaterialPageRoute(
        builder: (_) => SeriesListScreen(path: playlist.path),
      ),
    );
    if (serie != null) {
      setState(() {
        _series = serie;
        if (_nameCtrl.text.isEmpty) _nameCtrl.text = serie.name;
        if (_logoPath == null && _logoUrl == null && serie.logo.isNotEmpty) {
          _logoUrl = serie.logo;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.item == null ? 'Nouvel élément' : 'Modifier l\'élément'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SegmentedButton<IptvItemType>(
                      segments: const [
                        ButtonSegment(
                          value: IptvItemType.folder,
                          label: Text('Dossier'),
                        ),
                        ButtonSegment(
                          value: IptvItemType.media,
                          label: Text('Média'),
                        ),
                      ],
                      selected: <IptvItemType>{_type},
                      onSelectionChanged: (vals) =>
                          setState(() => _type = vals.first),
                    ),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Obligatoire' : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: Text(_logoLabel)),
                        IconButton(
                          onPressed: _pickLogo,
                          icon: const Icon(Icons.folder_open),
                        ),
                      ],
                    ),
                    if (_type == IptvItemType.folder)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ElevatedButton.icon(
                          onPressed: _importSeries,
                          icon: const Icon(Icons.playlist_play),
                          label: Text(
                            _series == null
                                ? 'Importer une série'
                                : 'Série : ${_series!.name}',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_type == IptvItemType.media)
              Card(
                margin: const EdgeInsets.only(top: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Liens'),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _editLink(),
                                icon: const Icon(Icons.add),
                              ),
                              IconButton(
                                onPressed: _importM3u,
                                icon: const Icon(Icons.file_upload),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: _links.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _links.removeAt(oldIndex);
                            _links.insert(newIndex, item);
                            if (!_canBeViewed) _viewed = false;
                          });
                        },
                        itemBuilder: (context, index) {
                          final link = _links[index];
                          return ReorderableDragStartListener(
                            key: ValueKey('link_$index'),
                            index: index,
                            child: ListTile(
                              onTap: () => _openLink(link.url),
                              title: LinkLabel(link: link),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(link.url),
                                  ...link.notes.map(
                                    (n) => Text(
                                      '${DateFormat.yMd('fr_FR').format(n.date)} - ${n.text}',
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isDownloadable(link))
                                    IconButton(
                                      icon: const Icon(Icons.download),
                                      onPressed: () => _downloadFile(link),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        _editLink(link: link, index: index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      setState(() {
                                        _links.removeAt(index);
                                        if (!_canBeViewed) _viewed = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            if (_canBeViewed)
              Card(
                margin: const EdgeInsets.only(top: 16),
                child: SwitchListTile.adaptive(
                  title: const Text('Marquer comme vu'),
                  value: _viewed,
                  onChanged: (v) => setState(() => _viewed = v),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.item != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 241, 156, 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, {'delete': true});
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Supprimer'),
                  ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final item = _buildItem();
                      if (_series != null) {
                        final children = _buildSeriesItems(item.id);
                        Navigator.pop(context, {
                          'item': item,
                          'children': children,
                        });
                      } else {
                        Navigator.pop(context, item);
                      }
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
