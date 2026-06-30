import 'package:flutter/material.dart';

import '../../../media/presentation/authenticated_media_image.dart';

class ProfilePhotoImage extends StatelessWidget {
  const ProfilePhotoImage({
    required this.photoRef,
    this.width = 68,
    this.height = 68,
    this.fallback,
    super.key,
  });

  final String? photoRef;
  final double width;
  final double height;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final ref = photoRef?.trim();
    if (ref == null || ref.isEmpty) {
      return fallback ?? const SizedBox.shrink();
    }
    if (ref.startsWith('http')) {
      return Image.network(
        ref,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            fallback ?? const Icon(Icons.broken_image_outlined),
      );
    }
    return AuthenticatedMediaImage(
      mediaId: ref,
      thumbnail: true,
      width: width,
      height: height,
      errorWidget: fallback,
    );
  }
}
