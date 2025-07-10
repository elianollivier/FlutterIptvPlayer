import 'dart:io';

import 'package:flutter/material.dart';

import '../models/m3u_playlist.dart';

class PlaylistCard extends StatefulWidget {
  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.onSelect,
    required this.onEdit,
  });

  final M3uPlaylist playlist;
  final VoidCallback onSelect;
  final VoidCallback onEdit;

  @override
  State<PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<PlaylistCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Center(
              child: widget.playlist.logoPath != null
                  ? Image.file(
                      File(widget.playlist.logoPath!),
                      fit: BoxFit.contain,
                    )
                  : const Icon(Icons.playlist_play, size: 48),
            ),
            Positioned(
              top: 4,
              left: 4,
              right: 4,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _hovered ? 1 : 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          widget.playlist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                          icon: const Icon(Icons.edit),
                          onPressed: widget.onEdit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onSelect,
        child: card,
      ),
    );
  }
}
