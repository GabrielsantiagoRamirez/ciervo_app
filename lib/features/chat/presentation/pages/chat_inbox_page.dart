import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/membership_upgrade_dialog.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../memberships/presentation/cubit/membership_cubit.dart';
import '../../../users/presentation/pages/user_search_page.dart';
import '../../../vakupli/data/vakupli_repository.dart';
import '../../../vakupli/presentation/pages/vakupli_page.dart';
import '../../data/chat_inbox_repository.dart';
import '../../domain/entities/chat_inbox_item.dart';
import 'chat_conversation_page.dart';

class ChatInboxPage extends StatefulWidget {
  const ChatInboxPage({super.key});

  @override
  State<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends State<ChatInboxPage> {
  final _repository = getIt<ChatInboxRepository>();
  List<ChatInboxItem> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.loadInbox();
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _items = items;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  Future<void> _openConversation(ChatInboxItem item) async {
    if (item.source == ChatInboxSource.vakupli && item.vakupliPlan != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VakupliPlanDetailPage(
            plan: item.vakupliPlan!,
            repository: getIt<VakupliRepository>(),
          ),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatConversationPage(
            conversationId: item.id,
            title: item.conversation.title,
          ),
        ),
      );
    }
    if (mounted) _load();
  }

  Future<void> _openUserSearch() async {
    final membership = context.read<MembershipCubit>().state;
    if (!membership.canUsePrivateChat()) {
      await showMembershipUpgradeDialog(
        context,
        featureLabel: 'chat privado con cualquier usuario CIERVO',
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const UserSearchPage()),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final canPrivateChat = context.watch<MembershipCubit>().state.canUsePrivateChat();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            tooltip: canPrivateChat
                ? 'Buscar personas'
                : 'Chat privado no incluido en tu plan',
            icon: const Icon(Icons.person_search_outlined),
            onPressed: canPrivateChat ? _openUserSearch : _openUserSearch,
          ),
          IconButton(
            tooltip: 'Planes Vakupli',
            icon: const Icon(Icons.groups_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const VakupliPage()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUserSearch,
        icon: Icon(canPrivateChat ? Icons.add_comment_outlined : Icons.lock_outline),
        label: Text(canPrivateChat ? 'Nuevo' : 'Mejorar plan'),
      ),
      body: _buildBody(canPrivateChat),
    );
  }

  Widget _buildBody(bool canPrivateChat) {
    if (_loading) {
      return const CiervoLoadingState(message: 'Cargando conversaciones');
    }
    if (_error != null) {
      return CiervoErrorState(
        title: 'No pudimos cargar tus chats',
        description: _error!,
        onRetry: _load,
      );
    }
    if (_items.isEmpty) {
      return CiervoEmptyState(
        title: 'Sin conversaciones',
        description:
            'Busca personas, escribe a un negocio o crea un plan Vakupli.',
        icon: Icons.chat_bubble_outline,
        actionLabel: canPrivateChat ? 'Buscar personas' : 'Ver planes',
        onAction: _openUserSearch,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _items[index];
          final conversation = item.conversation;
          final subtitle = conversation.lastMessage?.trim();
          final updated = conversation.updatedAt;
          final timeLabel = updated == null ? null : _formatTime(updated);

          return ListTile(
            leading: CircleAvatar(
              child: Icon(
                item.source == ChatInboxSource.vakupli
                    ? Icons.groups_outlined
                    : _iconForKind(conversation.type),
              ),
            ),
            title: Text(conversation.title),
            subtitle: subtitle != null && subtitle.isNotEmpty
                ? Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Text(item.kindLabel),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (timeLabel != null)
                  Text(
                    timeLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (conversation.unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Badge(label: Text('${conversation.unreadCount}')),
                ],
              ],
            ),
            onTap: () => _openConversation(item),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month} $h:$m';
  }

  IconData _iconForKind(String type) => switch (type.toLowerCase()) {
    'business' => Icons.storefront_outlined,
    'family' => Icons.family_restroom_outlined,
    'delivery' => Icons.delivery_dining_outlined,
    'support' => Icons.support_agent_outlined,
    'vakupli' => Icons.groups_outlined,
    'direct' => Icons.person_outline,
    _ => Icons.chat_bubble_outline,
  };
}
