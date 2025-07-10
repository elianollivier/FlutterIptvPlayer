import 'package:flutter/material.dart';
import '../models/m3u_playlist.dart';
import '../services/m3u_playlist_service.dart';
import '../widgets/playlist_card.dart';
import 'playlist_form_screen.dart';
import 'playlist_view_screen.dart';

class PlaylistListScreen extends StatefulWidget {
  const PlaylistListScreen({super.key, this.selectMode = false});

  final bool selectMode;

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
    final result = await Navigator.push<M3uPlaylist>(
      context,
      MaterialPageRoute(builder: (_) => const PlaylistFormScreen()),
    );
    if (result == null) return;
    setState(() => _playlists.add(result));
    await _service.save(_playlists);
  }

  Future<void> _editPlaylist(M3uPlaylist playlist) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (_) => PlaylistFormScreen(playlist: playlist)),
    );
    if (result is Map && result['delete'] == true) {
      await _service.delete(playlist);
      await _load();
    } else if (result is M3uPlaylist) {
      final index = _playlists.indexWhere((e) => e.id == result.id);
      if (index >= 0) {
        setState(() => _playlists[index] = result);
        await _service.save(_playlists);
      }
    }
  }

  void _select(M3uPlaylist pl) {
    if (widget.selectMode) {
      Navigator.pop(context, pl);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistViewScreen(playlist: pl),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final count =
                    (constraints.maxWidth / 160).floor().clamp(1, 6).toInt();
                final itemWidth =
                    (constraints.maxWidth - (count - 1) * 8) / count;
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final item = _playlists[index];
                    return SizedBox(
                      width: itemWidth,
                      child: PlaylistCard(
                        playlist: item,
                        onSelect: () => _select(item),
                        onEdit: () => _editPlaylist(item),
                      ),
                    );
                  },
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
