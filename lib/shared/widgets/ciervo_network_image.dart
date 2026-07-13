import 'package:flutter/material.dart';

/// Imagen de red para signed URLs del backend (GCS ~60 min).
/// Si expira, el usuario puede tocar el fallback para reintentar vía [onRetry].
class CiervoNetworkImage extends StatelessWidget {
  const CiervoNetworkImage({
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
    this.onRetry,
    super.key,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      url,
      key: ValueKey(url),
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        final errorWidget =
            fallback ??
            SizedBox(
              width: width,
              height: height,
              child: const Icon(Icons.broken_image_outlined),
            );
        if (onRetry == null) return errorWidget;
        return GestureDetector(onTap: onRetry, child: errorWidget);
      },
    );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
