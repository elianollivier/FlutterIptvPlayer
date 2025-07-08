import 'package:flutter/material.dart';

import '../models/iptv_models.dart';
import '../services/m3u_service.dart';

class M3uImportScreen extends StatefulWidget {
  const M3uImportScreen({super.key, required this.path});

  final String path;

  @override
  State<M3uImportScreen> createState() => _M3uImportScreenState();
}

class _M3uImportScreenState extends State<M3uImportScreen> {
  final M3uService _service = const M3uService();
  List<ChannelLink> _allLinks = [];
  final Set<ChannelLink> _selected = {};
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _service.loadFile(widget.path);
    setState(() {
      _allLinks = list;
      _loading = false;
    });
  }

  List<ChannelLink> get _filtered => _query.isEmpty
      ? _allLinks
      : _allLinks
          .where((e) => e.name.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select channels'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Search'),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final link = _filtered[index];
                      final selected = _selected.contains(link);
                      return CheckboxListTile(
                        value: selected,
                        title: Text(link.name),
                        subtitle: Text(link.url),
                        onChanged: (_) {
                          setState(() {
                            if (selected) {
                              _selected.remove(link);
                            } else {
                              _selected.add(link);
                            }
                          });
                        },
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
