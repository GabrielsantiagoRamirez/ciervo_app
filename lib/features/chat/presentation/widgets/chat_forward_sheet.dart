import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../data/chat_inbox_repository.dart';
import '../../domain/entities/chat_inbox_item.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

Future<bool> showChatForwardSheet(
  BuildContext context, {
  required ChatMessage message,
  required String sourceConversationId,
}) async {
  final inboxResult = await getIt<ChatInboxRepository>().loadInbox();
  if (!context.mounted) return false;

  final targets = inboxResult.when(
    success: (items) => items
        .where((item) => item.id != sourceConversationId)
        .where((item) => item.source != ChatInboxSource.vakupli)
        .toList(),
    failure: (_) => <ChatInboxItem>[],
  );

  if (targets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No hay otros chats disponibles para reenviar.')),
    );
    return false;
  }

  final selected = await showModalBottomSheet<ChatInboxItem>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text('Reenviar a...'),
            subtitle: Text('Elige la conversacion destino'),
          ),
          for (final item in targets)
            ListTile(
              leading: Icon(_iconForSource(item)),
              title: Text(item.conversation.title),
              subtitle: Text(item.kindLabel),
              onTap: () => Navigator.pop(context, item),
            ),
        ],
      ),
    ),
  );

  if (selected == null || !context.mounted) return false;

  final commentController = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reenviar mensaje'),
      content: TextField(
        controller: commentController,
        decoration: const InputDecoration(
          hintText: 'Comentario opcional',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Reenviar'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) {
    commentController.dispose();
    return false;
  }

  final result = await getIt<ChatRepository>().forwardMessage(
    sourceConversationId: sourceConversationId,
    messageId: message.id,
    targetConversationId: selected.id,
    comment: commentController.text.trim(),
  );
  commentController.dispose();
  if (!context.mounted) return false;

  return result.when(
    success: (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensaje reenviado.')),
      );
      return true;
    },
    failure: (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      );
      return false;
    },
  );
}

IconData _iconForSource(ChatInboxItem item) => switch (item.source) {
  ChatInboxSource.family => Icons.family_restroom_outlined,
  ChatInboxSource.vakupli => Icons.groups_outlined,
  _ => Icons.chat_bubble_outline,
};
