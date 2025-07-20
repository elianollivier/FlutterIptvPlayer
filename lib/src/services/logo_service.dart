import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'supabase_service.dart';

class LogoService {
  Future<List<String>> listLogos() async {
    return SupabaseService.instance.fetchLogos();
  }

  Future<String?> importLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      return SupabaseService.instance.uploadLogo(file);
    }
    return null;
  }

  Future<void> deleteLogo(String url) async {
    await SupabaseService.instance.deleteLogo(url);
  }
}
