import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/notifications/notifications_sync.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._repository) : super(const ChatState());
  final ChatRepository _repository;
  static const _pageSize = 50;

  Future<void> loadConversations() async {
    emit(state.copyWith(status: ChatStatus.loading, clearError: true));
    final result = await _repository.conversations();
    result.when(
      success: (items) => emit(
        state.copyWith(
          status: items.isEmpty ? ChatStatus.empty : ChatStatus.loaded,
          conversations: items,
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          status: ChatStatus.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> open(String id) async {
    emit(state.copyWith(status: ChatStatus.loading, clearError: true));
    final detail = await _repository.conversation(id);
    final buttons = await _repository.buttons();
    final messages = await _repository.messages(
      id,
      page: 1,
      pageSize: _pageSize,
    );
    final chatButtons = buttons.when(
      success: (items) => items,
      failure: (_) => state.chatButtons,
    );
    detail.when(
      success: (conversation) => messages.when(
        success: (items) {
          emit(
            state.copyWith(
              status: ChatStatus.loaded,
              conversation: conversation,
              messages: items,
              page: 1,
              hasMore: items.length == _pageSize,
              chatButtons: chatButtons,
            ),
          );
          _repository.markAsRead(id);
        },
        failure: (error) => emit(
          state.copyWith(
            status: ChatStatus.failure,
            conversation: conversation,
            errorMessage: UserErrorMessage.from(error),
          ),
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          status: ChatStatus.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    final conversation = state.conversation;
    if (conversation == null || !state.hasMore || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    final nextPage = state.page + 1;
    final result = await _repository.messages(
      conversation.id,
      page: nextPage,
      pageSize: _pageSize,
    );
    result.when(
      success: (items) => emit(
        state.copyWith(
          messages: [...state.messages, ...items],
          page: nextPage,
          hasMore: items.length == _pageSize,
          isLoadingMore: false,
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<bool> send(String body) async {
    final conversation = state.conversation;
    if (conversation == null || body.trim().isEmpty || state.isSending) {
      return false;
    }
    emit(state.copyWith(isSending: true, clearError: true));
    final result = await _repository.sendText(conversation.id, body.trim());
    return result.when(
      success: (message) {
        emit(
          state.copyWith(
            messages: [message, ...state.messages],
            isSending: false,
          ),
        );
        if (getIt.isRegistered<NotificationsSync>()) {
          getIt<NotificationsSync>().notifyInboxMayHaveChanged();
        }
        return true;
      },
      failure: (error) {
        emit(
          state.copyWith(
            isSending: false,
            errorMessage: UserErrorMessage.from(error),
          ),
        );
        return false;
      },
    );
  }

  Future<bool> sendMedia(String path, String fileName) async {
    final conversation = state.conversation;
    if (conversation == null || state.isSending) return false;
    emit(state.copyWith(isSending: true, clearError: true));
    final result = await _repository.sendMedia(conversation.id, path, fileName);
    return result.when(
      success: (message) {
        emit(
          state.copyWith(
            messages: [message, ...state.messages],
            isSending: false,
          ),
        );
        return true;
      },
      failure: (error) {
        emit(
          state.copyWith(
            isSending: false,
            errorMessage: UserErrorMessage.from(error),
          ),
        );
        return false;
      },
    );
  }

  Future<bool> sendLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final conversation = state.conversation;
    if (conversation == null || state.isSending) return false;
    emit(state.copyWith(isSending: true, clearError: true));
    final metadata = '{"latitude":$latitude,"longitude":$longitude'
        '${label != null ? ',"label":"${label.replaceAll('"', r'\"')}"' : ''}'
        '}';
    final result = await _repository.sendTypedMessage(
      conversation.id,
      messageType: 'Location',
      body: label ?? 'Ubicacion compartida',
      metadataJson: metadata,
    );
    return result.when(
      success: (message) {
        emit(
          state.copyWith(
            messages: [message, ...state.messages],
            isSending: false,
          ),
        );
        return true;
      },
      failure: (error) {
        emit(
          state.copyWith(
            isSending: false,
            errorMessage: UserErrorMessage.from(error),
          ),
        );
        return false;
      },
    );
  }
}
