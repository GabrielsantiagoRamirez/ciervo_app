import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../features/media/presentation/authenticated_media_image.dart';

class CiervoImageViewerPage extends StatefulWidget {
  const CiervoImageViewerPage({
    required this.images,
    this.initialIndex = 0,
    super.key,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<CiervoImageViewerPage> createState() => _CiervoImageViewerPageState();
}

class _CiervoImageViewerPageState extends State<CiervoImageViewerPage> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.images.length > 1
              ? 'Imagen ${_index + 1} de ${widget.images.length}'
              : 'Imagen',
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (value) => setState(() => _index = value),
        itemBuilder: (context, index) => InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AuthenticatedMediaImage(
                mediaId: widget.images[index],
                fit: BoxFit.contain,
                errorWidget: const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void openCiervoImageViewer(
  BuildContext context, {
  required List<String> images,
  int initialIndex = 0,
}) {
  final filtered = images.where((item) => item.trim().isNotEmpty).toList();
  if (filtered.isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CiervoImageViewerPage(
        images: filtered,
        initialIndex: initialIndex,
      ),
    ),
  );
}
