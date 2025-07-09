import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'm3u_import_screen.dart';

import '../widgets/link_label.dart';
import '../widgets/logo_picker_dialog.dart';
import '../models/iptv_models.dart';

class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key, this.item, this.parentId});

  final IptvItem? item;
  final String? parentId;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late IptvItemType _type;
  late TextEditingController _nameCtrl;
  String? _logoPath;
  List<ChannelLink> _links = [];

  @override
  void initState() {
    super.initState();
    _type = widget.item?.type ?? IptvItemType.folder;
    _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    _logoPath = widget.item?.logoPath;
    _links = List.of(widget.item?.links ?? []);
  }

  IptvItem _buildItem() {
    return IptvItem(
      id: widget.item?.id ?? const Uuid().v4(),
      type: _type,
      name: _nameCtrl.text,
      logoPath: _logoPath,
      links: _links,
      parentId: widget.parentId ?? widget.item?.parentId,
    );
  }

  Future<void> _pickLogo() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const LogoPickerDialog(),
    );
    if (result != null) {
      setState(() => _logoPath = result);
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
    final notesCtrl = TextEditingController(text: link?.notes ?? '');

    const resolutions = [
      '240p',
      '360p',
      '480p',
      '560p',
      'HD',
      'FHD',
      '4K',
    ];

    final result = await showDialog<ChannelLink>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: resolutions.contains(resCtrl.text) ? resCtrl.text : null,
              items: resolutions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              decoration: InputDecoration(
                labelText: 'Resolution',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              isExpanded: true,
              onChanged: (v) => resCtrl.text = v ?? '',
              dropdownColor: Theme.of(context).colorScheme.surfaceVariant,
            ),
            TextField(
              controller: fpsCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'FPS'),
            ),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
                  notes: notesCtrl.text,
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        if (index == null) {
          _links.add(result);
        } else {
          _links[index] = result;
        }
      });
    }
  }

  Future<void> _importM3u() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['m3u']);
    final path = result?.files.single.path;
    if (path == null) return;

    final imported = await Navigator.push<List<ChannelLink>>(
      context,
      MaterialPageRoute(
        builder: (_) => M3uImportScreen(
          path: path,
          existingLinks: _links,
        ),
      ),
    );
    if (imported != null && imported.isNotEmpty) {
      setState(() => _links.addAll(imported));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'New item' : 'Edit item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SegmentedButton<IptvItemType>(
                segments: const [
                  ButtonSegment(
                    value: IptvItemType.folder,
                    label: Text('Folder'),
                  ),
                  ButtonSegment(
                    value: IptvItemType.channel,
                    label: Text('Channel'),
                  ),
                ],
                selected: <IptvItemType>{_type},
                onSelectionChanged: (vals) =>
                    setState(() => _type = vals.first),
              ),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _logoPath == null
                        ? const Text('No logo selected')
                        : Text(_logoPath!),
                  ),
                  IconButton(
                    onPressed: _pickLogo,
                    icon: const Icon(Icons.folder_open),
                  ),
                ],
              ),
              if (_type == IptvItemType.channel) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Links'),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _importM3u,
                          icon: const Icon(Icons.file_upload),
                        ),
                        IconButton(
                          onPressed: () => _editLink(),
                          icon: const Icon(Icons.add),
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
                    });
                  },
                  itemBuilder: (context, index) {
                    final link = _links[index];
                    return ReorderableDragStartListener(
                      key: ValueKey('link_$index'),
                      index: index,
                      child: ListTile(
                        title: LinkLabel(link: link),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(link.url),
                            if (link.notes.isNotEmpty)
                              Text(
                                link.notes,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.item != null)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () {
                        Navigator.pop(context, {'delete': true});
                      },
                      child: const Text('Delete'),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context, _buildItem());
                      }
                    },
                    child: const Text('Save'),
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
