import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../domain/entities/delivery_models.dart';
import '../../domain/repositories/delivery_repository.dart';

class DeliverySettlementsPage extends StatefulWidget {
  const DeliverySettlementsPage({super.key});

  @override
  State<DeliverySettlementsPage> createState() =>
      _DeliverySettlementsPageState();
}

class _DeliverySettlementsPageState extends State<DeliverySettlementsPage> {
  List<DeliverySettlement> _items = const [];
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
    final result = await getIt<DeliveryRepository>().settlements();
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mis liquidaciones')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      CiervoEmptyState(
                        title: 'Sin liquidaciones',
                        description:
                            _error ?? 'Tus ganancias apareceran aqui.',
                        icon: Icons.payments_outlined,
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return CiervoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.currency ?? 'COP'} ${(item.amount ?? 0).toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text('Estado: ${item.status}'),
                            if (item.orderId.isNotEmpty)
                              Text('Pedido: #${item.orderId}'),
                            if (item.createdAt != null)
                              Text(
                                'Fecha: ${item.createdAt!.toLocal().toIso8601String().substring(0, 10)}',
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
  );
}
