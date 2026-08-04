import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/notifications/notifications_sync.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/membership_upgrade_dialog.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../../shared/widgets/ciervo_logo_mark.dart';
import '../../../media/presentation/authenticated_media_image.dart';
import '../../../memberships/presentation/cubit/membership_cubit.dart';
import '../../../notifications/presentation/cubit/notification_badges_cubit.dart';
import '../../../users/presentation/pages/user_search_page.dart';
import '../../../vakupli/data/vakupli_repository.dart';
import '../../../vakupli/presentation/pages/vakupli_page.dart';
import '../../data/chat_empty_dismiss_store.dart';
import '../../data/chat_inbox_repository.dart';
import '../../domain/entities/chat_inbox_item.dart';
import 'chat_conversation_page.dart';

enum _ChatInboxFilter { all, personal, business, vaku }

class ChatInboxPage extends StatefulWidget {
  const ChatInboxPage({super.key});

  @override
  State<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends State<ChatInboxPage> {
  final _repository = getIt<ChatInboxRepository>();
  final _dismissStore = getIt<ChatEmptyDismissStore>();
  List<ChatInboxItem> _items = const [];
  Set<String> _dismissedEmptyIds = {};
  bool _loading = true;
  String? _error;
  _ChatInboxFilter _filter = _ChatInboxFilter.all;
  StreamSubscription<void>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _load();
    _syncSubscription = getIt<NotificationsSync>().onRefresh.listen((_) {
      if (!mounted) return;
      _load(silent: true);
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final dismissed = await _dismissStore.load();
    final result = await _repository.loadInbox();
    if (!mounted) return;
    result.when(
      success: (items) {
        setState(() {
          _dismissedEmptyIds = dismissed;
          _items = items;
          _loading = false;
        });
        if (mounted) {
          final withMessages = items
              .where((i) => i.hasMessages && !dismissed.contains(i.id))
              .toList();
          context.read<NotificationBadgesCubit>().setLocalChatUnread(
            _repository.totalUnread(withMessages),
          );
        }
      },
      failure: (error) {
        if (silent) return;
        setState(() {
          _error = UserErrorMessage.from(error);
          _loading = false;
        });
      },
    );
  }

  bool _matchesFilter(ChatInboxItem item) {
    final isVaku = item.source == ChatInboxSource.vakupli;
    final isBusiness = item.conversation.isBusiness && !isVaku;
    return switch (_filter) {
      _ChatInboxFilter.all => true,
      _ChatInboxFilter.personal => !isBusiness && !isVaku,
      _ChatInboxFilter.business => isBusiness,
      _ChatInboxFilter.vaku => isVaku,
    };
  }

  List<ChatInboxItem> get _visibleItems {
    return _items
        .where(
          (item) =>
              item.hasMessages &&
              !_dismissedEmptyIds.contains(item.id) &&
              _matchesFilter(item),
        )
        .toList();
  }

  List<ChatInboxItem> get _emptyItems {
    return _items
        .where(
          (item) =>
              !item.hasMessages &&
              !_dismissedEmptyIds.contains(item.id) &&
              _matchesFilter(item),
        )
        .toList();
  }

  Future<void> _dismissAllEmpty() async {
    final empty = _emptyItems;
    if (empty.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar chats vacíos'),
        content: Text(
          'Se ocultarán ${empty.length} chat${empty.length == 1 ? '' : 's'} '
          'sin mensajes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ids = empty.map((e) => e.id);
    await _dismissStore.dismissMany(ids);
    if (!mounted) return;
    setState(() {
      _dismissedEmptyIds = {..._dismissedEmptyIds, ...ids};
    });
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
      final conversation = item.conversation;
      final title = DisplayFormatters.chatTitle(
        rawTitle: conversation.title,
        username: conversation.peerUsername,
        displayName: conversation.peerDisplayName,
        conversationType: conversation.type,
        businessName: conversation.businessName,
        participantCount: conversation.participantCount,
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatConversationPage(
            conversationId: item.id,
            title: title,
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
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const UserSearchPage()));
    if (mounted) _load();
  }

  Future<void> _pickFilter() async {
    final emptyCount = _emptyItems.length;
    final selected = await showModalBottomSheet<_ChatInboxFilter>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inbox_outlined),
              title: const Text('Todos los chats'),
              trailing: _filter == _ChatInboxFilter.all
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(context, _ChatInboxFilter.all),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Solo personales'),
              trailing: _filter == _ChatInboxFilter.personal
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(context, _ChatInboxFilter.personal),
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Solo negocios'),
              trailing: _filter == _ChatInboxFilter.business
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(context, _ChatInboxFilter.business),
            ),
            ListTile(
              leading: const CiervoLogoMark(size: 22),
              title: const Text('Planes Vaku'),
              trailing: _filter == _ChatInboxFilter.vaku
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(context, _ChatInboxFilter.vaku),
            ),
            if (emptyCount > 0) ...[
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text('Eliminar chats sin mensajes ($emptyCount)'),
                onTap: () {
                  Navigator.pop(context);
                  _dismissAllEmpty();
                },
              ),
            ],
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _filter = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPrivateChat = context
        .watch<MembershipCubit>()
        .state
        .canUsePrivateChat();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            tooltip: 'Filtrar chats',
            icon: Icon(
              _filter == _ChatInboxFilter.all
                  ? Icons.filter_list_outlined
                  : Icons.filter_list,
            ),
            onPressed: _pickFilter,
          ),
          IconButton(
            tooltip: canPrivateChat
                ? 'Buscar personas'
                : 'Chat privado no incluido en tu plan',
            icon: const Icon(Icons.person_search_outlined),
            onPressed: _openUserSearch,
          ),
          IconButton(
            tooltip: 'Planes Vaku',
            icon: const CiervoLogoMark(size: 24),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const VakupliPage()),
              );
              if (!mounted) return;
              await _load();
              if (!mounted) return;
              final hasVaku = _items.any(
                (item) => item.source == ChatInboxSource.vakupli,
              );
              if (hasVaku) {
                setState(() => _filter = _ChatInboxFilter.vaku);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUserSearch,
        icon: Icon(
          canPrivateChat ? Icons.add_comment_outlined : Icons.lock_outline,
        ),
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
            'Busca personas, escribe a un negocio o crea un plan Vaku.',
        icon: Icons.chat_bubble_outline,
        actionLabel: canPrivateChat ? 'Buscar personas' : 'Ver planes',
        onAction: _openUserSearch,
      );
    }

    final visible = _visibleItems;
    final empty = _emptyItems;
    if (visible.isEmpty) {
      if (empty.isNotEmpty) {
        return CiervoEmptyState(
          title: 'Sin chats con mensajes',
          description:
              'Tienes ${empty.length} chat${empty.length == 1 ? '' : 's'} '
              'sin mensajes. Puedes eliminarlos.',
          icon: Icons.chat_bubble_outline,
          actionLabel: 'Eliminar vacíos',
          onAction: _dismissAllEmpty,
        );
      }
      return CiervoEmptyState(
        title: 'Sin chats en este filtro',
        description: 'Prueba otro filtro o escribe a un negocio / persona.',
        icon: Icons.filter_list_off_outlined,
        actionLabel: 'Ver todos',
        onAction: () => setState(() => _filter = _ChatInboxFilter.all),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        itemCount: visible.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          indent: 72,
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
        itemBuilder: (context, index) => _buildConversationTile(visible[index]),
      ),
    );
  }

  Widget _buildConversationTile(ChatInboxItem item) {
    final conversation = item.conversation;
    final lastPreview = conversation.lastMessage?.trim();
    final subtitle = (lastPreview != null && lastPreview.isNotEmpty)
        ? lastPreview
        : item.kindLabel;
    final updated = conversation.updatedAt;
    final timeLabel = updated == null ? null : _formatTime(updated);
    final hasUnread = conversation.unreadCount > 0;
    final title = DisplayFormatters.chatTitle(
      rawTitle: conversation.title,
      username: conversation.peerUsername,
      displayName: conversation.peerDisplayName,
      conversationType: conversation.type,
      businessName: conversation.businessName,
      participantCount: conversation.participantCount,
    );
    final unreadStyle = hasUnread
        ? Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
        : Theme.of(context).textTheme.bodyMedium;
    final unreadSubtitleStyle = hasUnread
        ? Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          )
        : Theme.of(context).textTheme.bodySmall;
    final logo = conversation.circleImageUrl;

    return ListTile(
      tileColor: hasUnread
          ? Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.12)
          : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: _ChatAvatar(
          logo: logo,
          fallbackIcon: item.source == ChatInboxSource.vakupli
              ? Icons.groups_outlined
              : _iconForKind(conversation.type),
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: hasUnread
            ? Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              )
            : null,
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: lastPreview != null && lastPreview.isNotEmpty
            ? unreadSubtitleStyle
            : unreadStyle,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (timeLabel != null)
            Text(
              timeLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                color: hasUnread
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            Badge(label: Text('${conversation.unreadCount}')),
          ],
        ],
      ),
      onTap: () => _openConversation(item),
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

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.logo, required this.fallbackIcon});

  final String? logo;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final ref = logo?.trim() ?? '';
    if (ref.isEmpty) return Icon(fallbackIcon);

    if (ref.startsWith('http://') || ref.startsWith('https://')) {
      return ClipOval(
        child: Image.network(
          ref,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Icon(fallbackIcon),
        ),
      );
    }

    return ClipOval(
      child: AuthenticatedMediaImage(
        mediaId: ref,
        thumbnail: true,
        fit: BoxFit.cover,
        width: 40,
        height: 40,
        errorWidget: Icon(fallbackIcon),
      ),
    );
  }
}
