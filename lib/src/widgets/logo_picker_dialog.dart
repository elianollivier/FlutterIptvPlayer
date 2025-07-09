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
  List<File> _logos = [];

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
    return AlertDialog(
      title: const Text('Select Logo'),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: _logos.length + 1,
          itemBuilder: (context, index) {
            if (index == _logos.length) {
              return IconButton(
                onPressed: _import,
                icon: const Icon(Icons.add_a_photo),
              );
            }
            final file = _logos[index];
            return GestureDetector(
              onTap: () => Navigator.pop(context, file.path),
              child: Image.file(file, fit: BoxFit.contain),
            );
          },
        ),
      ),
    );
  }
}
