import 'package:flutter/material.dart';

import '../models/iptv_models.dart';

class LinkLabel extends StatelessWidget {
  const LinkLabel({
    super.key,
    required this.link,
    this.dark = false,
  });

  final ChannelLink link;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      Flexible(
        child: Text(
          link.name,
          overflow: TextOverflow.ellipsis,
          style: dark
              ? Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white)
              : Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ];
    if (link.resolution.isNotEmpty) {
      children.add(const SizedBox(width: 4));
      children.add(_InfoChip(text: link.resolution, dark: dark));
    }
    if (link.fps.isNotEmpty) {
      children.add(const SizedBox(width: 4));
      children.add(_InfoChip(text: '${link.fps} FPS', dark: dark));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.text, required this.dark});

  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = dark ? scheme.secondaryContainer : scheme.primaryContainer;
    final fg = dark ? scheme.onSecondaryContainer : scheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
