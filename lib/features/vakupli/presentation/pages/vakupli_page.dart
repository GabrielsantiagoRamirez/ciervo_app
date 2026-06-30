import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_labels.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../chat/presentation/cubit/chat_cubit.dart';
import '../../../chat/presentation/cubit/chat_state.dart';
import '../../../chat/presentation/pages/chat_conversation_page.dart';
import '../../../users/presentation/pages/user_search_page.dart';

class VakupliPage extends StatelessWidget {
  const VakupliPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ChatCubit(getIt<ChatRepository>())..loadConversations(),
    child: const _ChatList(),
  );
}

class _ChatList extends StatelessWidget {
  const _ChatList();
  @override
  Widget build(BuildContext context) => BlocBuilder<ChatCubit, ChatState>(
    builder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const UserSearchPage()),
        ),
        icon: const Icon(Icons.person_search_outlined),
        label: const Text('Buscar'),
      ),
      body: RefreshIndicator(
        onRefresh: context.read<ChatCubit>().loadConversations,
        child: switch (state.status) {
          ChatStatus.initial || ChatStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          ChatStatus.failure => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              CiervoErrorState(
                title: 'No pudimos cargar tus chats',
                description: state.errorMessage ?? 'Intenta nuevamente.',
                onRetry: context.read<ChatCubit>().loadConversations,
              ),
            ],
          ),
          ChatStatus.empty => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: const [
              CiervoEmptyState(
                title: 'Aun no tienes conversaciones',
                description: 'Contacta un negocio para iniciar un chat.',
                icon: Icons.forum_outlined,
              ),
            ],
          ),
          _ => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: state.conversations.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation = state.conversations[index];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.storefront_outlined),
                ),
                title: Text(conversation.title),
                subtitle: conversation.lastMessage == null
                    ? Text(DisplayLabels.conversationType(conversation.type))
                    : Text(
                        conversation.lastMessage!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: conversation.unreadCount > 0
                    ? Badge(label: Text('${conversation.unreadCount}'))
                    : const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatConversationPage(
                        conversationId: conversation.id,
                        title: conversation.title,
                      ),
                    ),
                  );
                  if (context.mounted) {
                    context.read<ChatCubit>().loadConversations();
                  }
                },
              );
            },
          ),
        },
      ),
    ),
  );
}
