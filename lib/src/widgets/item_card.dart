import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/iptv_models.dart';

class ItemCard extends StatefulWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEdit,
    this.onAddLink,
    this.onEditLink,
    this.onDeleteLink,
    this.onSelectLink,
  });

  final IptvItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onAddLink;
  final void Function(ChannelLink? link, int? index)? onEditLink;
  final void Function(int index)? onDeleteLink;
  final void Function(int index)? onSelectLink;

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool _hovering = false;
  bool _expanded = false;
  Timer? _hoverTimer;

  void _onEnter(PointerEnterEvent event) {
    if (widget.item.type == IptvItemType.channel) {
      _hoverTimer?.cancel();
      _hoverTimer = Timer(const Duration(seconds: 1), () {
        setState(() => _hovering = true);
      });
    }
  }

  void _onExit(PointerExitEvent event) {
    _hoverTimer?.cancel();
    if (!_expanded) {
      setState(() => _hovering = false);
    }
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
      if (!_expanded) _hovering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final collapsedHeight = _hovering ? 28.0 : 0.0;
    final expandedHeight = 36.0 * (widget.item.links.length + 1);

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
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
                if (widget.item.type == IptvItemType.channel)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleExpanded,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: _expanded ? expandedHeight : collapsedHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _expanded
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (int i = 0; i < widget.item.links.length; i++)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => widget.onSelectLink?.call(i),
                                            child: Text(
                                              widget.item.links[i].name,
                                              style: const TextStyle(color: Colors.white),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                                          onPressed: () => widget.onEditLink?.call(widget.item.links[i], i),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 16, color: Colors.white),
                                          onPressed: () => widget.onDeleteLink?.call(i),
                                        ),
                                      ],
                                    ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      icon: const Icon(Icons.add, color: Colors.white, size: 16),
                                      onPressed: widget.onAddLink,
                                    ),
                                  )
                                ],
                              )
                            : Center(
                                child: Text(
                                  widget.item.links.isNotEmpty
                                      ? widget.item.links.first.name
                                      : '',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
