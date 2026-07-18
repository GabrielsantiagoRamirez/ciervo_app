import 'package:flutter/material.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../../../core/utils/idempotency_key.dart';
import '../../../kids_v2/data/repositories/kids_v2_repositories.dart';
import '../../../kids_v2/domain/models/kids_v2_models.dart';
import '../../data/repositories/master_kids_repository.dart';
import '../../domain/models/master_kids_models.dart';

class MasterPaymentRequestsPage extends StatefulWidget {
  const MasterPaymentRequestsPage({
    required this.masterRepository,
    required this.kidsRepository,
    super.key,
  });

  final MasterKidsRepository masterRepository;
  final KidsRepository kidsRepository;

  @override
  State<MasterPaymentRequestsPage> createState() =>
      _MasterPaymentRequestsPageState();
}

class _MasterPaymentRequestsPageState extends State<MasterPaymentRequestsPage> {
  List<PaymentRequest> _items = const [];
  bool _loading = true;
  int? _actingId;
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
    final result = await widget.masterRepository.pendingPaymentRequests();
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

  Future<void> _approve(PaymentRequest request) async {
    setState(() => _actingId = request.id);
    try {
      final businessId = request.businessId;
      if (businessId != null) {
        final policyResult = await widget.kidsRepository.reservationPolicy(
          businessId,
        );
        ReservationPolicy? policy;
        Object? policyError;
        policyResult.when(
          success: (value) => policy = value,
          failure: (error) => policyError = error,
        );
        if (policyError != null) throw policyError!;
        if (policy?.acceptanceRequired == true) {
          final accepted = await _confirmPolicy(policy!);
          if (accepted != true) return;
          final acceptance = await widget.masterRepository
              .acceptReservationPolicy(
                AcceptReservationPolicyCommand(
                  paymentRequestId: request.id,
                  commerceId: businessId,
                  policyVersion: policy!.version,
                  idempotencyKey: IdempotencyKey.generate('policy'),
                ),
              );
          Object? acceptanceError;
          acceptance.when(
            success: (_) {},
            failure: (error) => acceptanceError = error,
          );
          if (acceptanceError != null) throw acceptanceError!;
        }
      }

      final result = await widget.masterRepository.approvePaymentRequest(
        request.id,
      );
      if (!mounted) return;
      Object? approvalError;
      PaymentTokenIssued? issued;
      result.when(
        success: (value) => issued = value,
        failure: (error) => approvalError = error,
      );
      if (approvalError != null) throw approvalError!;
      if (issued != null) await _showIssuedSecret(issued!);
      await _load();
    } catch (error) {
      if (mounted) {
        setState(() => _error = UserErrorMessage.from(error));
      }
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  Future<bool?> _confirmPolicy(ReservationPolicy policy) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Política del comercio · v${policy.version}'),
        content: SingleChildScrollView(child: Text(policy.terms)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Aceptar y continuar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showIssuedSecret(PaymentTokenIssued issued) {
    if (!issued.secretShown ||
        issued.token?.isNotEmpty != true ||
        issued.pin?.isNotEmpty != true) {
      return showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Solicitud aprobada'),
          content: const Text(
            'La credencial ya había sido emitida y no puede recuperarse.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.key_outlined),
        title: const Text('Credencial de un solo uso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Muéstrala ahora. No se guardará ni podrá recuperarse.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'PIN: ${issued.pin}',
              style: Theme.of(dialogContext).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              issued.token!,
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text('Expira: ${issued.expiresAt.toLocal()}'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Ocultar definitivamente'),
          ),
        ],
      ),
    );
  }

  Future<void> _reject(PaymentRequest request) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Rechazar solicitud'),
          content: TextField(
            controller: controller,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Motivo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );
    if (reason == null || !mounted) return;
    setState(() => _actingId = request.id);
    final result = await widget.masterRepository.rejectPaymentRequest(
      request.id,
      reason: reason,
    );
    if (!mounted) return;
    result.when(
      success: (_) => _load(),
      failure: (error) => setState(() => _error = UserErrorMessage.from(error)),
    );
    if (mounted) setState(() => _actingId = null);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Solicitudes Pinduck')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? ListView(
              children: const [
                SizedBox(height: 240),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  MaterialBanner(
                    content: Text(_error!),
                    actions: [
                      TextButton(
                        onPressed: () => setState(() => _error = null),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                if (_items.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.inbox_outlined),
                    title: Text('No hay solicitudes pendientes'),
                  ),
                for (final item in _items)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.requesterName ?? 'Cuenta Kids',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${item.currency} ${item.amount.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (item.description?.isNotEmpty == true)
                            Text(item.description!),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: _actingId == null
                                      ? () => _approve(item)
                                      : null,
                                  child: const Text('Aprobar'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _actingId == null
                                      ? () => _reject(item)
                                      : null,
                                  child: const Text('Rechazar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    ),
  );
}
