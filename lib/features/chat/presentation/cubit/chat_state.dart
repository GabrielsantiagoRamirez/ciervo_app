import '../../domain/entities/chat_button.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';

enum ChatStatus { initial, loading, loaded, empty, failure }

class ChatState {
  const ChatState({
    this.status = ChatStatus.initial,
    this.conversations = const [],
    this.conversation,
    this.messages = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isSending = false,
    this.errorMessage,
    this.chatButtons = const [],
  });
  final ChatStatus status;
  final List<ChatConversation> conversations;
  final ChatConversation? conversation;
  final List<ChatMessage> messages;
  final List<ChatButton> chatButtons;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isSending;
  final String? errorMessage;

  ChatState copyWith({
    ChatStatus? status,
    List<ChatConversation>? conversations,
    ChatConversation? conversation,
    List<ChatMessage>? messages,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isSending,
    String? errorMessage,
    List<ChatButton>? chatButtons,
    bool clearError = false,
  }) => ChatState(
    status: status ?? this.status,
    conversations: conversations ?? this.conversations,
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    chatButtons: chatButtons ?? this.chatButtons,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isSending: isSending ?? this.isSending,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}
