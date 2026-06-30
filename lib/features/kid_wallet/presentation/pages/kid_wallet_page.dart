import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../kid_me/data/kid_me_repository.dart';

class KidWalletPage extends StatefulWidget {
  const KidWalletPage({super.key});

  @override
  State<KidWalletPage> createState() => _KidWalletPageState();
}

class _KidWalletPageState extends State<KidWalletPage> {
  final _repository = getIt<KidMeRepository>();
  Map<String, dynamic>? _wallet;
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
    final result = await _repository.wallet();
    if (!mounted) return;
    result.when(
      success: (data) => setState(() {
        _wallet = data;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  double _num(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  @override
  Widget build(BuildContext context) {
    final movements = _wallet?['lastMovements'];
    final items = movements is List ? movements : const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Mi wallet')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                padding: pagePaddingOf(context),
                children: const [CiervoLoadingState(itemCount: 3)],
              )
            : _error != null
            ? ListView(
                padding: pagePaddingOf(context),
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
              )
            : ListView(
                padding: pagePaddingOf(context),
                children: [
                  CiervoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'COP ${_num(_wallet?['balance']).toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        if (_num(_wallet?['heldBalance']) > 0)
                          Text(
                            'Retenido: COP ${_num(_wallet?['heldBalance']).toStringAsFixed(0)}',
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Movimientos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (items.isEmpty)
                    const CiervoEmptyState(
                      title: 'Sin movimientos',
                      description: 'Aún no hay transacciones en tu wallet.',
                      icon: Icons.receipt_long_outlined,
                    )
                  else
                    ...items.map((item) {
                      if (item is! Map) return const SizedBox.shrink();
                      final map = Map<String, dynamic>.from(item);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: CiervoCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${map['description'] ?? map['type'] ?? 'Movimiento'}',
                            ),
                            subtitle: Text('${map['createdAt'] ?? ''}'),
                            trailing: Text(
                              'COP ${_num(map['amount']).toStringAsFixed(0)}',
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}
