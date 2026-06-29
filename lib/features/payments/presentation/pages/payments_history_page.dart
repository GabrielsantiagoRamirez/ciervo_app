import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/payment_history_item.dart';
import '../../domain/repositories/payments_repository.dart';

class PaymentsHistoryPage extends StatefulWidget {
  const PaymentsHistoryPage({super.key});

  @override
  State<PaymentsHistoryPage> createState() => _PaymentsHistoryPageState();
}

class _PaymentsHistoryPageState extends State<PaymentsHistoryPage> {
  final _repository = getIt<PaymentsRepository>();
  List<PaymentHistoryItem> _items = const [];
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
    final result = await _repository.myPayments();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de pagos')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: const [CiervoLoadingState(itemCount: 4)],
              )
            : _error != null
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  CiervoErrorState(
                    title: 'No pudimos cargar pagos',
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
                    title: 'Sin pagos registrados',
                    description: 'Tus pagos con Mercado Pago apareceran aqui.',
                    icon: Icons.payments_outlined,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return CiervoCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${item.type} · ${item.statusLabel}'),
                      subtitle: Text(item.createdAt ?? ''),
                      trailing: Text(
                        '${item.currency} ${item.amount.toStringAsFixed(0)}',
                      ),
                      onTap: item.receiptUrl == null
                          ? null
                          : () => launchUrl(
                              Uri.parse(item.receiptUrl!),
                              mode: LaunchMode.externalApplication,
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
