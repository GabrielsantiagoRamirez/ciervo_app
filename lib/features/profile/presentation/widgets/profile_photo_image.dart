import 'package:flutter/material.dart';

import '../../../media/presentation/authenticated_media_image.dart';
import '../../../../shared/widgets/versioned_network_image.dart';

class ProfilePhotoImage extends StatelessWidget {
  const ProfilePhotoImage({
    required this.photoRef,
    this.imageUrl,
    this.storagePath,
    this.photoUpdatedAt,
    this.width = 68,
    this.height = 68,
    this.fallback,
    super.key,
  });

  final String? photoRef;
  final String? imageUrl;
  final String? storagePath;
  final DateTime? photoUpdatedAt;
  final double width;
  final double height;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final httpUrl = _httpUrl(imageUrl) ?? _httpUrl(photoRef);
    if (httpUrl != null) {
      return VersionedNetworkImage(
        imageUrl: httpUrl,
        storagePath: storagePath,
        updatedAt: photoUpdatedAt,
        width: width,
        height: height,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(width),
        errorWidget: fallback ?? const Icon(Icons.broken_image_outlined),
      );
    }

    final ref = photoRef?.trim();
    if (ref == null || ref.isEmpty) {
      return fallback ?? const SizedBox.shrink();
    }
    return AuthenticatedMediaImage(
      key: ValueKey(ref),
      mediaId: ref,
      thumbnail: true,
      width: width,
      height: height,
      errorWidget: fallback,
    );
  }

  String? _httpUrl(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    if (text.startsWith('http')) return text;
    return null;
  }
}
