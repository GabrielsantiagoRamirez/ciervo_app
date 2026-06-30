import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../chat/domain/entities/chat_conversation.dart';
import '../../../kids/data/dtos/child_profile_dto.dart';
import '../../data/family_chat_repository.dart';
import '../../domain/entities/family_member.dart';
import 'family_conversation_page.dart';

class FamilyChatPage extends StatefulWidget {
  const FamilyChatPage({this.childId, super.key});
  final String? childId;

  @override
  State<FamilyChatPage> createState() => _FamilyChatPageState();
}

class _FamilyChatPageState extends State<FamilyChatPage> {
  final _repository = getIt<FamilyChatRepository>();
  List<ChatConversation> _items = const [];
  String? _error;
  bool _loading = true;

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
    final result = await _repository.conversations();
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

  Future<void> _create() async {
    final membersResult = await _repository.members();
    final childrenResult = await _repository.children();
    if (!mounted) return;

    final members = membersResult.when(
      success: (value) => value,
      failure: (_) => const <FamilyMember>[],
    );
    final children = childrenResult.when(
      success: (value) => value,
      failure: (_) => const <ChildProfileDto>[],
    );

    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No encontramos familiares disponibles para iniciar un chat.',
          ),
        ),
      );
      return;
    }

    final selection = await showModalBottomSheet<_FamilyChatSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _FamilyChatPickerSheet(
        members: members,
        children: children,
        initialChildId: widget.childId,
      ),
    );
    if (selection == null || !mounted) return;

    final result = await _repository.create(
      childId: selection.childId,
      participantUserId: selection.member.userId,
    );
    if (!mounted) return;
    result.when(
      success: (conversation) async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FamilyConversationPage(conversation: conversation),
          ),
        );
        await _load();
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chat familiar')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _create,
      icon: const Icon(Icons.add_comment_outlined),
      label: const Text('Nueva conversación'),
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? ListView(children: const [CiervoLoadingState(itemCount: 4)])
          : _error != null
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                CiervoErrorState(
                  title: 'No pudimos cargar el chat familiar',
                  description: _error!,
                  onRetry: _load,
                ),
              ],
            )
          : _items.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: const [
                CiervoEmptyState(
                  title: 'Sin conversaciones familiares',
                  description:
                      'Inicia una conversación entre tutores para coordinar el cuidado de tus menores.',
                  icon: Icons.family_restroom,
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.family_restroom),
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                    item.lastMessage ?? 'Conversación entre tutores',
                  ),
                  trailing: item.unreadCount > 0
                      ? Badge(label: Text('${item.unreadCount}'))
                      : const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            FamilyConversationPage(conversation: item),
                      ),
                    );
                    await _load();
                  },
                );
              },
            ),
    ),
  );
}

class _FamilyChatSelection {
  const _FamilyChatSelection({
    required this.childId,
    required this.member,
  });

  final String childId;
  final FamilyMember member;
}

class _FamilyChatPickerSheet extends StatefulWidget {
  const _FamilyChatPickerSheet({
    required this.members,
    required this.children,
    this.initialChildId,
  });

  final List<FamilyMember> members;
  final List<ChildProfileDto> children;
  final String? initialChildId;

  @override
  State<_FamilyChatPickerSheet> createState() => _FamilyChatPickerSheetState();
}

class _FamilyChatPickerSheetState extends State<_FamilyChatPickerSheet> {
  String? _childId;
  FamilyMember? _member;

  @override
  void initState() {
    super.initState();
    _childId = widget.initialChildId ??
        (widget.children.length == 1 ? widget.children.first.id : null);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nueva conversación familiar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (widget.children.isNotEmpty) ...[
            Text('Menor', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            ...widget.children.map(
              (child) => RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: child.id,
                groupValue: _childId,
                title: Text('${child.firstName} ${child.lastName}'.trim()),
                onChanged: (value) => setState(() => _childId = value),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ] else
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                'No tienes menores vinculados. La conversación se creará sin menor asociado.',
              ),
            ),
          Text('Familiar', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          ...widget.members.map(
            (member) => RadioListTile<FamilyMember>(
              contentPadding: EdgeInsets.zero,
              value: member,
              groupValue: _member,
              title: Text(member.fullName),
              subtitle: Text(
                [
                  if (member.city != null) member.city!,
                  if (member.country != null) member.country!,
                ].join(' · '),
              ),
              onChanged: (value) => setState(() => _member = value),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _member == null
                ? null
                : () => Navigator.pop(
                    context,
                    _FamilyChatSelection(
                      childId: _childId ?? '',
                      member: _member!,
                    ),
                  ),
            child: const Text('Iniciar conversación'),
          ),
        ],
      ),
    );
  }
}
