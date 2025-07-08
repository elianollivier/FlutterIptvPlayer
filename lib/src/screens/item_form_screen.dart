import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

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
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _logoPath = result.files.single.path;
      });
    }
  }

  Future<void> _editLink({ChannelLink? link, int? index}) async {
    final nameCtrl = TextEditingController(text: link?.name ?? '');
    final urlCtrl = TextEditingController(text: link?.url ?? '');
    final resCtrl = TextEditingController(text: link?.resolution ?? '');
    final fpsCtrl = TextEditingController(text: link?.fps ?? '');
    final notesCtrl = TextEditingController(text: link?.notes ?? '');

    final result = await showDialog<ChannelLink>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL')),
            TextField(controller: resCtrl, decoration: const InputDecoration(labelText: 'Resolution')),
            TextField(controller: fpsCtrl, decoration: const InputDecoration(labelText: 'FPS')),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
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
              DropdownButtonFormField<IptvItemType>(
                value: _type,
                items: IptvItemType.values
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _type = val!),
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
                    IconButton(
                      onPressed: () => _editLink(),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                    return ListTile(
                      key: ValueKey('link_$index'),
                      title: Text(link.formattedName),
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
                            onPressed: () => _editLink(link: link, index: index),
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
                    );
                  },
                ),
              ],
              const Spacer(),
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
