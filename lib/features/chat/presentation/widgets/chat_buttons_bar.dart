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
    this.familyKidMode = false,
    this.onActionCompleted,
    super.key,
  });

  final List<ChatButton> buttons;
  final String conversationId;
  final bool enabled;
  final int? businessId;
  final String? businessName;
  final bool familyKidMode;
  final Future<void> Function()? onActionCompleted;

  @override
  Widget build(BuildContext context) {
    final visible = buttons.visibleOnMobile();
    final effective = visible.isNotEmpty ? visible : _fallbackButtons();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          for (final button in effective) ...[
            ActionChip(
              avatar: Icon(
                iconForChatButton(button.code),
                size: 18,
              ),
              label: Text(button.label),
              onPressed: !enabled
                  ? null
                  : () async {
                      await handleChatButtonTap(
                        context,
                        button: button,
                        conversationId: conversationId,
                        businessId: businessId,
                        businessName: businessName,
                        familyKidMode: familyKidMode,
                      );
                      await onActionCompleted?.call();
                    },
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

  List<ChatButton> _fallbackButtons() => const [
        ChatButton(
          code: 'pay',
          label: 'Pagar',
          visibility: ChatButtonVisibility.productionReady,
        ),
        ChatButton(
          code: 'pay_for_me',
          label: 'Paga por mí',
          visibility: ChatButtonVisibility.productionReady,
        ),
        ChatButton(
          code: 'gift',
          label: 'Regalo',
          visibility: ChatButtonVisibility.productionReady,
        ),
      ];
}
