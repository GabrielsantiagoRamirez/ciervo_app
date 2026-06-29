import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../chat/domain/entities/chat_conversation.dart';
import '../../../chat/domain/entities/chat_message.dart';
import '../../data/family_chat_repository.dart';

class FamilyConversationPage extends StatefulWidget {
  const FamilyConversationPage({required this.conversation, super.key});
  final ChatConversation conversation;
  @override
  State<FamilyConversationPage> createState() => _FamilyConversationPageState();
}

class _FamilyConversationPageState extends State<FamilyConversationPage> {
  final _repository = getIt<FamilyChatRepository>();
  final _controller = TextEditingController();
  List<ChatMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() { super.initState(); _open(); }

  Future<void> _open() async {
    await _repository.markRead(widget.conversation.id);
    final result = await _repository.messages(widget.conversation.id);
    if (!mounted) return;
    result.when(
      success: (messages) => setState(() { _messages = messages; _loading = false; }),
      failure: (error) => setState(() { _error = UserErrorMessage.from(error); _loading = false; }),
    );
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final result = await _repository.send(widget.conversation.id, body);
    if (!mounted) return;
    result.when(
      success: (message) => setState(() { _messages = [message, ..._messages]; _controller.clear(); _sending = false; }),
      failure: (error) { setState(() => _sending = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error)))); },
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.conversation.title)),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!))
            : Column(children: [
                Expanded(child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return Align(
                      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: message.isMine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(message.body),
                      ),
                    );
                  },
                )),
                SafeArea(top: false, child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(children: [
                    Expanded(child: TextField(controller: _controller, enabled: !_sending, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'Escribe un mensaje'))),
                    IconButton.filled(onPressed: _sending ? null : _send, icon: const Icon(Icons.send_rounded)),
                  ]),
                )),
              ]),
  );
}
