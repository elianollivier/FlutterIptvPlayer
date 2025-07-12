import 'dart:io';

import 'package:flutter/material.dart';

import 'link_label.dart';
import '../models/iptv_models.dart';
import '../services/download_service.dart';

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
  int? _hoveredIndex;

  void _open() {
    if (widget.item.type == IptvItemType.folder) {
      widget.onOpenFolder?.call();
    } else if (widget.item.links.isNotEmpty) {
      final link = widget.item.links[_selectedIndex];
      widget.onOpenLink?.call(link);
    }
  }

  void _toggleExpanded() {
    if (widget.item.type == IptvItemType.media) {
      setState(() => _expanded = !_expanded);
    }
  }

  bool _isDownloadable(ChannelLink link) {
    final url = link.url.toLowerCase();
    return url.endsWith('.mp4') || url.endsWith('.mkv');
  }

  Future<void> _downloadFile(ChannelLink link) async {
    final uri = Uri.parse(link.url);
    final name = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last.split('?').first
        : link.name;
    await DownloadService.instance.download(link.url, name);
  }

  @override
  Widget build(BuildContext context) {
    final ChannelLink? selected =
        widget.item.links.isNotEmpty ? widget.item.links[_selectedIndex] : null;

    final previewWidget = selected != null
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
                  child: Center(
                    child: LinkLabel(link: selected, dark: true),
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
            if (widget.item.type == IptvItemType.folder)
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
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Text(
                            widget.item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: IconButton(
                            iconSize: 18,
                            padding: EdgeInsets.zero,
                            splashRadius: 20,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            icon: const Icon(Icons.edit),
                            onPressed: widget.onEdit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Positioned(
                top: 4,
                right: 4,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _hovered ? 1 : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      splashRadius: 20,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      icon: const Icon(Icons.edit),
                      onPressed: widget.onEdit,
                    ),
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
      child: _expanded && widget.item.type == IptvItemType.media
          ? Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.item.links.length,
                  itemBuilder: (context, i) {
                    final link = widget.item.links[i];
                    return InkWell(
                      onHover: (hover) => setState(() => _hoveredIndex = hover ? i : null),
                      onTap: () => setState(() {
                        _selectedIndex = i;
                        _expanded = false;
                      }),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: i == _selectedIndex
                              ? Colors.grey.shade600
                              : _hoveredIndex == i
                                  ? Colors.grey.shade300
                                  : Colors.transparent,
                          borderRadius: BorderRadius.vertical(
                            top: i == 0 ? const Radius.circular(12) : Radius.zero,
                            bottom: i == widget.item.links.length - 1
                                ? const Radius.circular(12)
                                : Radius.zero,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: LinkLabel(
                                link: link,
                                dark: i == _selectedIndex,
                              ),
                            ),
                            if (_isDownloadable(link))
                              IconButton(
                                icon: const Icon(Icons.download),
                                padding: EdgeInsets.zero,
                                color: i == _selectedIndex ? Colors.white : null,
                                onPressed: () => _downloadFile(link),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
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
