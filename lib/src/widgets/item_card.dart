import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'link_label.dart';
import '../models/iptv_models.dart';
import '../services/logo_service.dart';

class ItemCard extends StatefulWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    this.onOpenFolder,
    this.onOpenLink,
    this.dragging = false,
    this.highlight = false,
    this.onHighlightHandled,
  });

  final IptvItem item;
  final VoidCallback onEdit;
  final VoidCallback? onOpenFolder;
  final ValueChanged<ChannelLink>? onOpenLink;
  final bool dragging;
  final bool highlight;
  final VoidCallback? onHighlightHandled;

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> with TickerProviderStateMixin {
  bool _hovered = false;
  bool _expanded = false;
  int _selectedIndex = 0;
  int? _hoveredIndex;
  Timer? _hoverTimer;
  late final ScrollController _scrollCtrl;
  String? _localLogo;
  
  void _handleHighlight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showOverlay();
      widget.onHighlightHandled?.call();
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _loadLogo();
    if (widget.highlight) {
      _handleHighlight();
    }
  }

  @override
  void didUpdateWidget(covariant ItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.logoUrl != widget.item.logoUrl ||
        oldWidget.item.logoPath != widget.item.logoPath) {
      _loadLogo();
    }
    if (widget.highlight && !oldWidget.highlight) {
      _handleHighlight();
    }
  }

  Future<void> _loadLogo() async {
    if (widget.item.logoPath != null) {
      setState(() => _localLogo = widget.item.logoPath);
      return;
    }
    if (widget.item.logoUrl != null) {
      final path = await LogoService().localPathFromUrl(widget.item.logoUrl!);
      if (!mounted) return;
      setState(() => _localLogo = path);
    } else {
      setState(() => _localLogo = null);
    }
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  bool get _shouldShowViewed {
    if (!widget.item.viewed || widget.item.type != IptvItemType.media) {
      return false;
    }
    final files = widget.item.links.every((l) {
      final url = l.url.toLowerCase();
      return url.endsWith('.mp4') || url.endsWith('.mkv');
    });
    return files;
  }

  void _open() {
    _hoverTimer?.cancel();
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

  void showOverlay() {
    setState(() => _hovered = true);
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _hovered = false);
      }
    });
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
              child: FractionallySizedBox(
                widthFactor: 0.95,
                heightFactor: 0.95,
                child: () {
                  final icon = Icon(
                    widget.item.type == IptvItemType.folder
                        ? Icons.folder
                        : Icons.tv,
                    size: 48,
                  );
                  if (_localLogo != null) {
                    return Image.file(
                      File(_localLogo!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => icon,
                    );
                  }
                  if (widget.item.logoUrl != null) {
                    return Image.network(
                      widget.item.logoUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => icon,
                    );
                  }
                  return icon;
                }(),
              ),
            ),
            previewWidget,
            if (_shouldShowViewed)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                  ),
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
                controller: _scrollCtrl,
                thumbVisibility: true,
                interactive: true,
                child: ListView.builder(
                  controller: _scrollCtrl,
                  shrinkWrap: true,
                  itemCount: widget.item.links.length,
                  itemBuilder: (context, i) {
                    final link = widget.item.links[i];
                    return InkWell(
                      onHover: (hover) =>
                          setState(() => _hoveredIndex = hover ? i : null),
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
                            top: i == 0
                                ? const Radius.circular(12)
                                : Radius.zero,
                            bottom: i == widget.item.links.length - 1
                                ? const Radius.circular(12)
                                : Radius.zero,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: LinkLabel(
                                link: link,
                                dark: i == _selectedIndex,
                              ),
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

    final cardContent = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) {
        _hoverTimer?.cancel();
        setState(() => _hovered = false);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boundedHeight = constraints.hasBoundedHeight &&
              constraints.maxHeight != double.infinity;
          final content = InkWell(
            onTap: _open,
            child: AspectRatio(aspectRatio: 0.9, child: card),
          );
          return Column(
            mainAxisSize: boundedHeight ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (boundedHeight) Expanded(child: content) else content,
              Flexible(child: linksList),
            ],
          );
        },
      ),
    );

    return AnimatedScale(
      scale: widget.dragging ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: cardContent,
    );
  }
}
