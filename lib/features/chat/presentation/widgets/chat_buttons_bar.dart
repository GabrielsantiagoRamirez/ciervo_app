import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/chat_button.dart';
import 'chat_button_handler.dart';

class ChatButtonsBar extends StatelessWidget {
  const ChatButtonsBar({
    required this.buttons,
    required this.conversationId,
    this.enabled = true,
    this.businessId,
    this.businessName,
    super.key,
  });

  final List<ChatButton> buttons;
  final String conversationId;
  final bool enabled;
  final int? businessId;
  final String? businessName;

  @override
  Widget build(BuildContext context) {
    final visible = buttons.where((b) => b.visibility.isVisible).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          for (final button in visible) ...[
            ActionChip(
              avatar: Icon(
                iconForChatButton(button.code),
                size: 18,
              ),
              label: Text(button.label),
              onPressed: !enabled
                  ? null
                  : () => handleChatButtonTap(
                      context,
                      button: button,
                      conversationId: conversationId,
                      businessId: businessId,
                      businessName: businessName,
                    ),
              backgroundColor: button.visibility.isEnabled
                  ? null
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
