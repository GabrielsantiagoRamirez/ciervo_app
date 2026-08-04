import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../data/media_repository.dart';

class AuthenticatedMediaImage extends StatefulWidget {
  const AuthenticatedMediaImage({
    required this.mediaId,
    this.thumbnail = false,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
    super.key,
  });

  final String mediaId;
  final bool thumbnail;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  @override
  State<AuthenticatedMediaImage> createState() =>
      _AuthenticatedMediaImageState();
}

class _AuthenticatedMediaImageState extends State<AuthenticatedMediaImage> {
  late Future<Uint8List?> _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AuthenticatedMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId ||
        oldWidget.thumbnail != widget.thumbnail) {
      _load();
    }
  }

  void _load() {
    _bytes = getIt<MediaRepository>()
        .download(widget.mediaId, thumbnail: widget.thumbnail)
        .then(
          (result) =>
              result.when(success: (value) => value, failure: (_) => null),
        );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _bytes,
    builder: (context, snapshot) {
      final bytes = snapshot.data;
      if (bytes != null && bytes.isNotEmpty) {
        return Image.memory(
          bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          gaplessPlayback: true,
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1712), Color(0xFF0D0D0D)],
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFC9A227),
              ),
            ),
          ),
        );
      }
      return widget.errorWidget ??
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Icon(Icons.broken_image_outlined),
          );
    },
  );
}
