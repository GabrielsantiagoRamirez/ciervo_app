import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';
import '../../../media/presentation/authenticated_media_image.dart';
import '../../../../shared/widgets/versioned_network_image.dart';

class ChatMessageImage extends StatelessWidget {
  const ChatMessageImage({
    required this.message,
    this.width = 220,
    this.height = 160,
    super.key,
  });

  final ChatMessage message;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (!message.isImageMessage) {
      return const SizedBox.shrink();
    }

    final displayUrl = message.resolvedImageUrl;
    if (displayUrl != null && displayUrl.startsWith('http')) {
      return VersionedNetworkImage(
        imageUrl: displayUrl,
        storagePath: message.storagePath,
        updatedAt: message.mediaUpdatedAt ?? message.sentAt,
        width: width,
        height: height,
        borderRadius: BorderRadius.circular(12),
      );
    }

    final mediaId = message.attachmentUrl?.trim();
    if (mediaId != null && mediaId.isNotEmpty && !mediaId.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AuthenticatedMediaImage(
          mediaId: mediaId,
          thumbnail: true,
          width: width,
          height: height,
          errorWidget: const Icon(Icons.broken_image_outlined),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}
