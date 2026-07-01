import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_labels.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/pending_parent_payment.dart';
import '../../domain/repositories/family_payments_repository.dart';

class ParentPaymentApprovalPage extends StatefulWidget {
  const ParentPaymentApprovalPage({required this.paymentId, super.key});

  final String paymentId;

  @override
  State<ParentPaymentApprovalPage> createState() =>
      _ParentPaymentApprovalPageState();
}

class _ParentPaymentApprovalPageState extends State<ParentPaymentApprovalPage> {
  final _repository = getIt<FamilyPaymentsRepository>();
  PendingParentPayment? _payment;
  bool _loading = true;
  bool _acting = false;
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
    final result = await _repository.pendingParentPayment(widget.paymentId);
    if (!mounted) return;
    result.when(
      success: (payment) => setState(() {
        _payment = payment;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _loading = false;
        _error = UserErrorMessage.from(error);
      }),
    );
  }

  Future<void> _approve() async {
    setState(() => _acting = true);
    final result = await _repository.approvePayment(widget.paymentId);
    if (!mounted) return;
    setState(() => _acting = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago aprobado.')),
        );
        Navigator.of(context).pop(true);
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Rechazar pago'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Motivo (opcional)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );
    if (reason == null) return;
    setState(() => _acting = true);
    final result = await _repository.rejectPayment(
      widget.paymentId,
      reason: reason.trim().isEmpty ? null : reason.trim(),
    );
    if (!mounted) return;
    setState(() => _acting = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago rechazado.')),
        );
        Navigator.of(context).pop(true);
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payment = _payment;
    return Scaffold(
      appBar: AppBar(title: const Text('Aprobar pago')),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CiervoLoadingState(itemCount: 4),
            )
          : _error != null
              ? Padding(
                  padding: pagePaddingOf(context),
                  child: CiervoErrorState(
                    title: 'No pudimos cargar la solicitud',
                    description: _error!,
                    onRetry: _load,
                  ),
                )
              : payment == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: pagePaddingOf(context),
                      child: Column(
                        children: [
                          Expanded(
                            child: CiervoCard(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 42,
                                    backgroundImage: payment.kidPhotoUrl != null
                                        ? CachedNetworkImageProvider(
                                            payment.kidPhotoUrl!,
                                          )
                                        : null,
                                    child: payment.kidPhotoUrl == null
                                        ? const Icon(Icons.child_care, size: 36)
                                        : null,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    payment.kidName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  _infoRow('Comercio', payment.merchantName),
                                  if (payment.city != null)
                                    _infoRow('Ciudad', payment.city!),
                                  _infoRow(
                                    'Monto',
                                    '${payment.currency} ${payment.amount.toStringAsFixed(0)}',
                                  ),
                                  if (payment.requestedAt != null)
                                    _infoRow('Hora', payment.requestedAt.toString()),
                                  _infoRow(
                                    'Fuente',
                                    DisplayLabels.familyFundingSource(
                                      payment.fundingSource,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          CiervoButton(
                            label: _acting ? 'Procesando...' : 'Aprobar',
                            icon: Icons.check_circle_outline,
                            state: _acting
                                ? CiervoButtonState.loading
                                : CiervoButtonState.normal,
                            onPressed: _acting ? null : _approve,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          CiervoButton(
                            label: 'Rechazar',
                            icon: Icons.cancel_outlined,
                            variant: CiervoButtonVariant.danger,
                            onPressed: _acting ? null : _reject,
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
