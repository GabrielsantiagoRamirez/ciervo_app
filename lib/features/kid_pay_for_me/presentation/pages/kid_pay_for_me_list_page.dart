import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/pay_for_me_labels.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../kid_me/data/kid_me_repository.dart';

class KidPayForMeListPage extends StatefulWidget {
  const KidPayForMeListPage({super.key});

  @override
  State<KidPayForMeListPage> createState() => _KidPayForMeListPageState();
}

class _KidPayForMeListPageState extends State<KidPayForMeListPage> {
  final _repository = getIt<KidMeRepository>();
  List<Map<String, dynamic>> _items = const [];
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
    final result = await _repository.payForMeRequests();
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

  double _num(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis solicitudes')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                padding: pagePaddingOf(context),
                children: const [CiervoLoadingState(itemCount: 4)],
              )
            : _error != null
            ? ListView(
                padding: pagePaddingOf(context),
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
              )
            : _items.isEmpty
            ? ListView(
                padding: pagePaddingOf(context),
                children: const [
                  CiervoEmptyState(
                    title: 'Sin solicitudes',
                    description:
                        'Cuando pidas dinero a tu familia, aparecerán aquí.',
                    icon: Icons.receipt_long_outlined,
                  ),
                ],
              )
            : ListView.separated(
                padding: pagePaddingOf(context),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final status = '${item['status'] ?? item['requestStatus'] ?? ''}';
                  final color = PayForMeLabels.statusColor(context, status);
                  return CiervoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item['businessName'] ?? item['description'] ?? 'Solicitud'}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: color),
                              ),
                              child: Text(
                                PayForMeLabels.statusLabel(status),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'COP ${_num(item['amount']).toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (item['createdAt'] != null)
                          Text('${item['createdAt']}'),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
