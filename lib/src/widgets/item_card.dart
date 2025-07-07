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
    final preview = selected == null ? '' : selected.formattedName;

    final previewWidget = preview.isNotEmpty
        ? Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: (_hovered || _expanded) ? 1 : 0,
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
            if (widget.item.type == IptvItemType.folder)
              Positioned(
                top: 4,
                left: 4,
                right: 32,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _hovered ? 1 : 0,
                  child: Text(
                    widget.item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _hovered ? 1 : 0,
                child: IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: widget.onEdit,
                ),
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
          ? Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < widget.item.links.length; i++)
                    InkWell(
                      onTap: () => setState(() {
                        _selectedIndex = i;
                        _expanded = false;
                      }),
                      child: Container(
                        width: double.infinity,
                        color: i == _selectedIndex
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Text(
                          widget.item.links[i].formattedName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(child: InkWell(onTap: _open, child: card)),
              linksList,
            ],
          );
        },
      ),
    );
  }
}
