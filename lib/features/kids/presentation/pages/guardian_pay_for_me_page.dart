import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/pay_for_me_labels.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/repositories/kids_repository.dart';

class GuardianPayForMePage extends StatefulWidget {
  const GuardianPayForMePage({super.key});

  @override
  State<GuardianPayForMePage> createState() => _GuardianPayForMePageState();
}

class _GuardianPayForMePageState extends State<GuardianPayForMePage> {
  final _repository = getIt<KidsRepository>();
  List<dynamic> _items = const [];
  bool _loading = true;
  String? _error;
  int? _actingOnId;

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

  int _requestId(Map item) {
    final raw = item['requestId'] ?? item['id'];
    if (raw is int) return raw;
    return int.tryParse('$raw') ?? 0;
  }

  bool _isPending(Map item) {
    final status = '${item['status'] ?? item['requestStatus'] ?? ''}'.toLowerCase();
    return status.contains('pending');
  }

  Future<void> _approve(Map item) async {
    final id = _requestId(item);
    if (id <= 0) return;
    setState(() => _actingOnId = id);
    final result = await _repository.approvePayForMeRequest(id);
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud aprobada.')),
        );
        _load();
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
    );
    if (mounted) setState(() => _actingOnId = null);
  }

  Future<void> _reject(Map item) async {
    final id = _requestId(item);
    if (id <= 0) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Rechazar solicitud'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Motivo (opcional)',
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );
    if (reason == null || !mounted) return;
    setState(() => _actingOnId = id);
    final result = await _repository.rejectPayForMeRequest(
      id,
      reason: reason.isEmpty ? null : reason,
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud rechazada.')),
        );
        _load();
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
    );
    if (mounted) setState(() => _actingOnId = null);
  }

  double _num(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes de pago')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  CiervoLoadingState(itemCount: 4),
                ],
              )
            : _error != null
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
              )
            : _items.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  CiervoEmptyState(
                    title: 'Sin solicitudes',
                    description:
                        'Cuando un menor pida dinero, podrás aprobarlo aquí.',
                    icon: Icons.family_restroom_outlined,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final raw = _items[index];
                  if (raw is! Map) return const SizedBox.shrink();
                  final item = Map<String, dynamic>.from(raw);
                  final status = '${item['status'] ?? item['requestStatus'] ?? ''}';
                  final color = PayForMeLabels.statusColor(context, status);
                  final id = _requestId(item);
                  final pending = _isPending(item);
                  final busy = _actingOnId == id;

                  return CiervoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['childName'] ?? 'Menor'} · ${item['businessName'] ?? 'Comercio'}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'COP ${_num(item['amount']).toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (item['description'] != null)
                          Text('${item['description']}'),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            PayForMeLabels.statusLabel(status),
                            style: TextStyle(color: color),
                          ),
                        ),
                        if (pending) ...[
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: CiervoButton(
                                  label: busy ? '...' : 'Aprobar',
                                  icon: Icons.check,
                                  onPressed: busy ? null : () => _approve(item),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: busy ? null : () => _reject(item),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Rechazar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
