import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/repositories/delivery_repository.dart';

class DeliveryChatPage extends StatefulWidget {
  const DeliveryChatPage({required this.conversationId, this.title, super.key});
  final String conversationId;
  final String? title;
  @override
  State<DeliveryChatPage> createState() => _DeliveryChatPageState();
}

class _DeliveryChatPageState extends State<DeliveryChatPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = const [];
  int _page = 1;
  bool _loading = true;
  bool _more = true;
  bool _sending = false;
  @override
  void initState() {
    super.initState();
    _load(1);
    getIt<DeliveryRepository>().markRead(widget.conversationId);
    _scroll.addListener(() {
      if (_scroll.hasClients &&
          _scroll.position.pixels > _scroll.position.maxScrollExtent - 150) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load(int page) async {
    final result = await getIt<DeliveryRepository>().messages(
      widget.conversationId,
      page: page,
    );
    if (!mounted) return;
    result.when(
      success: (items) {
        final mapped = items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
            .reversed
            .toList();
        setState(() {
          _messages = page == 1 ? mapped : [..._messages, ...mapped];
          _page = page;
          _more = items.length == 50;
          _loading = false;
        });
      },
      failure: (e) {
        setState(() => _loading = false);
        _error(e);
      },
    );
  }

  Future<void> _loadMore() async {
    if (_loading || !_more) return;
    setState(() => _loading = true);
    await _load(_page + 1);
  }

  Future<void> _send() async {
    if (_sending || _text.text.trim().isEmpty) return;
    setState(() => _sending = true);
    final result = await getIt<DeliveryRepository>().sendMessage(
      widget.conversationId,
      _text.text.trim(),
    );
    if (!mounted) return;
    result.when(
      success: (message) {
        _text.clear();
        setState(() {
          _messages = [message, ..._messages];
          _sending = false;
        });
      },
      failure: (e) {
        setState(() => _sending = false);
        _error(e);
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title ?? 'Chat de entregas')),
    body: Column(
      children: [
        Expanded(
          child: _loading && _messages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final m = _messages[index];
                    final own = m['isOwnMessage'] == true;
                    return Align(
                      alignment: own
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * .78,
                        ),
                        decoration: BoxDecoration(
                          color: own
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (m['senderRole'] != null)
                              Text(
                                '${m['senderRole']}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            Text('${m['body'] ?? ''}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    enabled: !_sending,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  void _error(Object e) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(e))));
}
