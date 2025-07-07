import 'dart:io';

import 'package:flutter/material.dart';

import '../models/iptv_models.dart';

class ItemCard extends StatefulWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    this.onOpenFolder,
    this.onOpenLink,
  });

  final IptvItem item;
  final VoidCallback onEdit;
  final VoidCallback? onOpenFolder;
  final ValueChanged<ChannelLink>? onOpenLink;

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> with TickerProviderStateMixin {
  bool _hovered = false;
  bool _expanded = false;
  int _selectedIndex = 0;

  void _open() {
    if (widget.item.type == IptvItemType.folder) {
      widget.onOpenFolder?.call();
    } else if (widget.item.links.isNotEmpty) {
      final link = widget.item.links[_selectedIndex];
      widget.onOpenLink?.call(link);
    }
  }

  void _toggleExpanded() {
    if (widget.item.type == IptvItemType.channel) {
      setState(() => _expanded = !_expanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ChannelLink? selected =
        widget.item.links.isNotEmpty ? widget.item.links[_selectedIndex] : null;
    final preview = selected == null
        ? ''
        : [selected.name, selected.resolution, selected.fps]
            .where((e) => e.isNotEmpty)
            .join(' - ');

    final previewWidget = _hovered && preview.isNotEmpty
        ? Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: _toggleExpanded,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(4),
                child: Text(
                  preview,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    final card = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 4,
              right: 32,
              child: Text(
                widget.item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Center(
              child: widget.item.logoPath != null
                  ? Image.file(
                      File(widget.item.logoPath!),
                      fit: BoxFit.contain,
                    )
                  : Icon(
                      widget.item.type == IptvItemType.folder
                          ? Icons.folder
                          : Icons.tv,
                      size: 48,
                    ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: widget.onEdit,
              ),
            ),
            previewWidget,
          ],
        ),
      ),
    );

    final linksList = AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: _expanded && widget.item.type == IptvItemType.channel
          ? Column(
              children: [
                for (int i = 0; i < widget.item.links.length; i++)
                  InkWell(
                    onTap: () => setState(() {
                      _selectedIndex = i;
                      _expanded = false;
                    }),
                    child: Row(
                      children: [
                        Expanded(child: Text(widget.item.links[i].name)),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: widget.onEdit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: widget.onEdit,
                        ),
                      ],
                    ),
                  ),
              ],
            )
          : const SizedBox.shrink(),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(onTap: _open, child: card),
          linksList,
        ],
      ),
    );
  }
}
