import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_spacing.dart';
import '../../features/chat/domain/entities/chat_message.dart';

class ChatLocationCard extends StatelessWidget {
  const ChatLocationCard({required this.payload, super.key});

  final ChatLocationPayload payload;

  Future<void> _openMaps() async {
    final url = payload.mapsUrl?.trim();
    final uri = url != null && url.isNotEmpty
        ? Uri.parse(url)
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${payload.latitude},${payload.longitude}',
          );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
        color: colors.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              gradient: LinearGradient(
                colors: [
                  colors.primary.withValues(alpha: 0.35),
                  colors.primaryContainer.withValues(alpha: 0.5),
                ],
              ),
            ),
            child: const Center(
              child: Icon(Icons.location_on, size: 40, color: Colors.redAccent),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ubicación compartida',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if (payload.label != null && payload.label!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(payload.label!),
                ],
                const SizedBox(height: AppSpacing.sm),
                FilledButton.tonalIcon(
                  onPressed: _openMaps,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Abrir en Google Maps'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
