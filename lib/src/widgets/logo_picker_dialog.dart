import 'package:flutter/material.dart';

import '../services/logo_service.dart';

class LogoPickerDialog extends StatelessWidget {
  const LogoPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final service = LogoService();
    return AlertDialog(
      title: const Text('Importer un logo'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () async {
            final url = await service.importLogo();
            if (url != null && context.mounted) {
              Navigator.pop(context, url);
            }
          },
          child: const Text('Choisir'),
        ),
      ],
    );
  }
}
