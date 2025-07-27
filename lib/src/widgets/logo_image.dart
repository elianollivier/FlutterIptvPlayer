import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LogoImage extends StatelessWidget {
  const LogoImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorWidget,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;

  bool get _isNetwork => path.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final err = errorWidget ?? const Icon(Icons.image_not_supported);
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: path,
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.high,
        errorWidget: (_, __, ___) => err,
      );
    }
    final file = File(path);
    if (!file.existsSync()) return err;
    return Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => err,
    );
  }
}
