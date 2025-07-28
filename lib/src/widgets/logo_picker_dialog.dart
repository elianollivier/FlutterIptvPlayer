import 'dart:io';

import 'package:flutter/material.dart';

import '../services/logo_service.dart';

class LogoPickerDialog extends StatefulWidget {
  const LogoPickerDialog({super.key});

  @override
  State<LogoPickerDialog> createState() => _LogoPickerDialogState();
}

class _LogoPickerDialogState extends State<LogoPickerDialog> {
  final LogoService _service = LogoService();
  List<String> _logos = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _service.listLogos();
    if (!mounted) return;
    setState(() => _logos = list);
  }

  Future<void> _import() async {
    final path = await _service.importLogo();
    if (path != null) {
      await _load();
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text('Sélectionner un logo', textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final count =
                    (constraints.maxWidth / 100).round().clamp(3, 8).toInt();
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1,
                  ),
                  itemCount: _logos.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _AddLogoTile(onAdd: _import);
                    }
                    final path = _logos[index - 1];
                    return _LogoTile(
                      path: path,
                      onDelete: () async {
                        await _service.deleteLogo(path);
                        await _load();
                      },
                      onSelect: () => Navigator.pop(context, path),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoTile extends StatefulWidget {
  const _LogoTile({required this.path, required this.onDelete, required this.onSelect});

  final String path;
  final VoidCallback onDelete;
  final VoidCallback onSelect;

  @override
  State<_LogoTile> createState() => _LogoTileState();
}

class _LogoTileState extends State<_LogoTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: Platform.isAndroid || Platform.isIOS
                ? () {
                    if (_hovered) {
                      widget.onSelect();
                      setState(() => _hovered = false);
                    } else {
                      setState(() => _hovered = true);
                    }
                  }
                : widget.onSelect,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(File(widget.path), fit: BoxFit.contain),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _hovered ? 0.2 : 0,
                  child: Container(color: Colors.black),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _hovered ? 1 : 0,
              child: IconButton(
                iconSize: 24,
                splashRadius: 20,
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddLogoTile extends StatelessWidget {
  const _AddLogoTile({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAdd,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
