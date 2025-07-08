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
  List<ChannelLink> _links = [];
  final Set<ChannelLink> _selected = {};
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    final list = await _service.searchFile(
      widget.path,
      query: _query,
      limit: 100,
    );
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Search'),
                    onChanged: (v) {
                      setState(() => _query = v);
                      if (v.isEmpty || v.length >= 3) {
                        _search();
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _links.length,
                    itemBuilder: (context, index) {
                      final link = _links[index];
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
