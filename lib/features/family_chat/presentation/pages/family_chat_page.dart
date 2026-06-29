import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../chat/domain/entities/chat_conversation.dart';
import '../../data/family_chat_repository.dart';
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
    setState(() { _loading = true; _error = null; });
    final result = await _repository.conversations();
    if (!mounted) return;
    result.when(
      success: (items) => setState(() { _items = items; _loading = false; }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  Future<void> _create() async {
    final childController = TextEditingController(text: widget.childId ?? '');
    final participantController = TextEditingController();
    final values = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva conversación familiar'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: childController, decoration: const InputDecoration(labelText: 'ID del menor')),
          const SizedBox(height: AppSpacing.sm),
          TextField(controller: participantController, decoration: const InputDecoration(labelText: 'ID del otro tutor')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, [childController.text.trim(), participantController.text.trim()]),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    childController.dispose();
    participantController.dispose();
    if (values == null || values.any((value) => value.isEmpty) || !mounted) return;
    final result = await _repository.create(childId: values[0], participantUserId: values[1]);
    if (!mounted) return;
    result.when(
      success: (conversation) async {
        await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => FamilyConversationPage(conversation: conversation),
        ));
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
      label: const Text('Nuevo'),
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? ListView(children: const [CiervoLoadingState(itemCount: 4)])
          : _error != null
              ? ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
                  CiervoErrorState(title: 'No pudimos cargar el chat familiar', description: _error!, onRetry: _load),
                ])
              : _items.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: const [
                        CiervoEmptyState(title: 'Sin conversaciones familiares', description: 'Crea una conversación entre tutores.', icon: Icons.family_restroom),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.family_restroom)),
                          title: Text(item.title),
                          subtitle: Text(item.lastMessage ?? 'Conversación entre tutores'),
                          trailing: item.unreadCount > 0 ? Badge(label: Text('${item.unreadCount}')) : const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) => FamilyConversationPage(conversation: item),
                            ));
                            await _load();
                          },
                        );
                      },
                    ),
    ),
  );
}
