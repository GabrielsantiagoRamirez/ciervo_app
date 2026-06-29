import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../domain/repositories/delivery_repository.dart';
import 'delivery_chat_page.dart';

class DeliveryChatListPage extends StatefulWidget {
  const DeliveryChatListPage({super.key});
  @override
  State<DeliveryChatListPage> createState() => _DeliveryChatListPageState();
}

class _DeliveryChatListPageState extends State<DeliveryChatListPage> {
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<DeliveryRepository>().conversations();
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _items = items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      }),
      failure: (e) => setState(() {
        _error = UserErrorMessage.from(e);
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chat de entregas')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      if (_error != null) Text(_error!),
                      const CiervoEmptyState(
                        title: 'Sin conversaciones de entregas',
                        description: 'Los chats de pedidos apareceran aqui.',
                        icon: Icons.forum_outlined,
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final id =
                          '${item['id'] ?? item['conversationId'] ?? ''}';
                      final participants = item['participants'] is List
                          ? (item['participants'] as List)
                                .map((e) => e is Map ? e['role'] : e)
                                .join(', ')
                          : 'Cliente, negocio y domiciliario';
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.forum_outlined),
                        ),
                        title: Text(
                          '${item['title'] ?? 'Pedido ${item['orderId'] ?? ''}'}',
                        ),
                        subtitle: Text(participants),
                        trailing:
                            (int.tryParse('${item['unreadCount'] ?? 0}') ?? 0) >
                                0
                            ? Badge(label: Text('${item['unreadCount']}'))
                            : const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DeliveryChatPage(
                                conversationId: id,
                                title: item['title']?.toString(),
                              ),
                            ),
                          );
                          _load();
                        },
                      );
                    },
                  ),
          ),
  );
}
