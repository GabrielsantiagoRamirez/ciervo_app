import '../../../core/result/result.dart';
import '../../family_chat/data/family_chat_repository.dart';
import '../../vakupli/data/vakupli_repository.dart';
import '../../vakupli/domain/entities/vakupli_plan.dart';
import '../domain/entities/chat_inbox_item.dart';
import '../domain/entities/chat_conversation.dart';
import '../domain/repositories/chat_repository.dart';

class ChatInboxRepository {
  const ChatInboxRepository(
    this._chatRepository,
    this._familyChatRepository,
    this._vakupliRepository,
  );

  final ChatRepository _chatRepository;
  final FamilyChatRepository _familyChatRepository;
  final VakupliRepository _vakupliRepository;

  Future<Result<List<ChatInboxItem>>> loadInbox() async {
    final internalResult = await _chatRepository.conversations();
    final familyResult = await _familyChatRepository.conversations();
    final vakupliResult = await _vakupliRepository.listGroups();

    return internalResult.when(
      failure: Failure.new,
      success: (internalConversations) {
        final internalItems = internalConversations
            .map(
              (conversation) => ChatInboxItem(
                conversation: conversation,
                source: ChatInboxSource.internal,
              ),
            )
            .toList();
        final internalIds = internalItems.map((item) => item.id).toSet();
        final chatIds = internalConversations
            .map((c) => c.id)
            .toSet();
        final merged = List<ChatInboxItem>.from(internalItems);

        familyResult.when(
          success: (conversations) {
            for (final conversation in conversations) {
              if (internalIds.contains(conversation.id)) continue;
              merged.add(
                ChatInboxItem(
                  conversation: conversation,
                  source: ChatInboxSource.family,
                ),
              );
            }
          },
          failure: (_) {},
        );

        vakupliResult.when(
          success: (page) {
            for (final group in page.items) {
              final chatId = group.chatId?.toString();
              if (chatId != null && chatIds.contains(chatId)) continue;
              merged.add(_vakupliInboxItem(group));
            }
          },
          failure: (_) {},
        );

        merged.sort((a, b) {
          final aDate = a.conversation.updatedAt;
          final bDate = b.conversation.updatedAt;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });

        return Success(merged);
      },
    );
  }

  ChatInboxItem _vakupliInboxItem(VakupliPlan group) {
    final groupId = group.id;
    return ChatInboxItem(
      source: ChatInboxSource.vakupli,
      vakupliPlan: group,
      conversation: ChatConversation(
        id: group.chatId?.toString() ?? 'vakupli:$groupId',
        title: group.title,
        type: 'Vakupli',
        unreadCount: 0,
        status: 'Open',
        lastMessage: group.paymentProgressLabel,
        updatedAt: group.createdAt,
      ),
    );
  }

  int totalUnread(List<ChatInboxItem> items) =>
      items.fold(0, (sum, item) => sum + item.conversation.unreadCount);
}
