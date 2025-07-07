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

  void _handleTap() {
    if (widget.item.type == IptvItemType.folder) {
      widget.onOpenFolder?.call();
    } else {
      setState(() => _expanded = !_expanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final link = widget.item.links.isNotEmpty ? widget.item.links.first.url : '';
    final preview = link.length > 30 ? '${link.substring(0, 30)}...' : link;

    final previewWidget = _hovered && preview.isNotEmpty
        ? Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(4),
              child: Text(
                preview,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
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
                for (final link in widget.item.links)
                  InkWell(
                    onTap: () => widget.onOpenLink?.call(link),
                    child: Row(
                      children: [
                        Expanded(child: Text(link.name)),
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
          InkWell(onTap: _handleTap, child: card),
          linksList,
        ],
      ),
    );
  }
}
