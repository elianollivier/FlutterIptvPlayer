import 'package:flutter/material.dart';

import '../models/m3u_series.dart';
import '../services/m3u_service.dart';

class SeriesListScreen extends StatefulWidget {
  const SeriesListScreen({super.key, required this.path});

  final String path;

  @override
  State<SeriesListScreen> createState() => _SeriesListScreenState();
}

class _SeriesListScreenState extends State<SeriesListScreen> {
  final M3uService _service = const M3uService();
  final TextEditingController _queryCtrl = TextEditingController();
  List<M3uSeries> _series = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.loadSeries(
      widget.path,
      query: _query,
    );
    if (!mounted) return;
    setState(() {
      _series = list;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Séries')),
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
              itemCount: _series.length,
              itemBuilder: (context, index) {
                final serie = _series[index];
                return ListTile(
                  minVerticalPadding: 8,
                  leading: serie.logo.isNotEmpty
                      ? Image.network(
                          serie.logo,
                          width: 64,
                          height: 64,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image_not_supported),
                        )
                      : const Icon(Icons.image_not_supported),
                  title: Text(serie.name),
                  subtitle: Text('${serie.episodes.length} épisodes'),
                  onTap: () => Navigator.pop(context, serie),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
