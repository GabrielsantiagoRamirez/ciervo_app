import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class VersionedNetworkImage extends StatelessWidget {
  const VersionedNetworkImage({
    required this.imageUrl,
    this.storagePath,
    this.updatedAt,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
    super.key,
  });

  final String imageUrl;
  final String? storagePath;
  final DateTime? updatedAt;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;

  String get _cacheKey {
    final version = updatedAt?.millisecondsSinceEpoch ??
        _versionFromUrl(imageUrl) ??
        0;
    return '${storagePath ?? imageUrl}_$version';
  }

  int? _versionFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final v = uri?.queryParameters['v'];
    if (v == null) return null;
    return int.tryParse(v);
  }

  @override
  Widget build(BuildContext context) {
    final child = CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: _cacheKey,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) =>
          errorWidget ??
          SizedBox(
            width: width,
            height: height,
            child: const Icon(Icons.broken_image_outlined),
          ),
    );
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }
}
