import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_labels.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/family_payment_record.dart';
import '../../domain/repositories/family_payments_repository.dart';

class FamilyPaymentDetailPage extends StatefulWidget {
  const FamilyPaymentDetailPage({required this.paymentId, super.key});
  final String paymentId;

  @override
  State<FamilyPaymentDetailPage> createState() =>
      _FamilyPaymentDetailPageState();
}

class _FamilyPaymentDetailPageState extends State<FamilyPaymentDetailPage> {
  final _repository = getIt<FamilyPaymentsRepository>();
  FamilyPaymentDetail? _payment;
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
    final result = await _repository.paymentDetail(widget.paymentId);
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

  @override
  Widget build(BuildContext context) {
    final payment = _payment;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del pago')),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CiervoLoadingState(itemCount: 4),
            )
          : _error != null
              ? Padding(
                  padding: pagePaddingOf(context),
                  child: CiervoErrorState(
                    title: 'No pudimos cargar el pago',
                    description: _error!,
                    onRetry: _load,
                  ),
                )
              : payment == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: pagePaddingOf(context),
                        children: [
                          CiervoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  payment.merchantName,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '${payment.currency} ${payment.amount.toStringAsFixed(0)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Divider(height: 24),
                                _row('Estado',
                                    DisplayLabels.familyPaymentStatus(payment.status)),
                                _row('Fuente',
                                    DisplayLabels.familyFundingSource(payment.fundingSource)),
                                if (payment.kidName != null)
                                  _row('Hijo', payment.kidName!),
                                if (payment.city != null)
                                  _row('Ciudad', payment.city!),
                                if (payment.createdAt != null)
                                  _row('Hora', payment.createdAt.toString()),
                                if (payment.cardAlias != null)
                                  _row('Tarjeta', payment.cardAlias!),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
