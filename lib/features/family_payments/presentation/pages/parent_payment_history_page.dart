import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_labels.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/family_payment_record.dart';
import '../../domain/repositories/family_payments_repository.dart';
import 'family_payment_detail_page.dart';

class ParentPaymentHistoryPage extends StatefulWidget {
  const ParentPaymentHistoryPage({super.key});

  @override
  State<ParentPaymentHistoryPage> createState() =>
      _ParentPaymentHistoryPageState();
}

class _ParentPaymentHistoryPageState extends State<ParentPaymentHistoryPage> {
  final _repository = getIt<FamilyPaymentsRepository>();
  final _merchantController = TextEditingController();
  List<FamilyPaymentRecord> _payments = const [];
  DateTimeRange? _range;
  String? _status;
  String? _kidId;
  String? _cardId;
  bool _loading = true;
  String? _error;

  @override
  void dispose() {
    _merchantController.dispose();
    super.dispose();
  }

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
    final result = await _repository.parentPayments(
      from: _range?.start,
      to: _range?.end,
      kidId: _kidId,
      status: _status,
      merchantQuery: _merchantController.text.trim(),
      cardId: _cardId,
    );
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _payments = items;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _loading = false;
        _error = UserErrorMessage.from(error);
      }),
    );
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _range = picked);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial familiar')),
      body: Column(
        children: [
          Padding(
            padding: pagePaddingOf(context).copyWith(bottom: 0),
            child: CiervoCard(
              child: Column(
                children: [
                  TextField(
                    controller: _merchantController,
                    decoration: InputDecoration(
                      hintText: 'Buscar comercio',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _load,
                      ),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: Text(
                          _range == null
                              ? 'Fecha'
                              : '${_range!.start.day}/${_range!.start.month} - ${_range!.end.day}/${_range!.end.month}',
                        ),
                        onPressed: _pickRange,
                      ),
                      ActionChip(
                        label: Text(_status ?? 'Estado'),
                        onPressed: () async {
                          final value = await showModalBottomSheet<String>(
                            context: context,
                            builder: (context) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: const Text('Todos'),
                                    onTap: () => Navigator.pop(context),
                                  ),
                                  ListTile(
                                    title: const Text('Completados'),
                                    onTap: () =>
                                        Navigator.pop(context, 'completed'),
                                  ),
                                  ListTile(
                                    title: const Text('Pendientes'),
                                    onTap: () =>
                                        Navigator.pop(context, 'pending'),
                                  ),
                                  ListTile(
                                    title: const Text('Rechazados'),
                                    onTap: () =>
                                        Navigator.pop(context, 'rejected'),
                                  ),
                                ],
                              ),
                            ),
                          );
                          setState(() => _status = value);
                          await _load();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CiervoLoadingState(itemCount: 4),
                    )
                  : _error != null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: pagePaddingOf(context),
                              child: CiervoErrorState(
                                title: 'No pudimos cargar el historial',
                                description: _error!,
                                onRetry: _load,
                              ),
                            ),
                          ],
                        )
                      : _payments.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                CiervoEmptyState(
                                  title: 'Sin pagos registrados',
                                  description:
                                      'Los pagos familiares aparecerán aquí.',
                                  icon: Icons.receipt_long_outlined,
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: pagePaddingOf(context),
                              itemCount: _payments.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final payment = _payments[index];
                                return CiervoCard(
                                  child: ListTile(
                                    title: Text(payment.merchantName),
                                    subtitle: Text(
                                      '${payment.kidName ?? 'Menor'} · ${DisplayLabels.familyFundingSource(payment.fundingSource)}',
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${payment.currency} ${payment.amount.toStringAsFixed(0)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        Text(
                                          DisplayLabels.familyPaymentStatus(
                                            payment.status,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => FamilyPaymentDetailPage(
                                          paymentId: payment.id,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class KidPaymentHistoryPage extends StatefulWidget {
  const KidPaymentHistoryPage({required this.kidId, super.key});
  final String kidId;

  @override
  State<KidPaymentHistoryPage> createState() => _KidPaymentHistoryPageState();
}

class _KidPaymentHistoryPageState extends State<KidPaymentHistoryPage> {
  final _repository = getIt<FamilyPaymentsRepository>();
  List<FamilyPaymentRecord> _payments = const [];
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
    final result = await _repository.kidPayments(widget.kidId);
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _payments = items;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de pagos')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CiervoLoadingState(itemCount: 4),
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: pagePaddingOf(context),
                        child: CiervoErrorState(
                          title: 'No pudimos cargar el historial',
                          description: _error!,
                          onRetry: _load,
                        ),
                      ),
                    ],
                  )
                : _payments.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          CiervoEmptyState(
                            title: 'Sin pagos',
                            description: 'Tus pagos aparecerán aquí.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: pagePaddingOf(context),
                        itemCount: _payments.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final payment = _payments[index];
                          return CiervoCard(
                            child: ListTile(
                              title: Text(payment.merchantName),
                              subtitle: Text(
                                DisplayLabels.familyPaymentStatus(
                                  payment.status,
                                ),
                              ),
                              trailing: Text(
                                '${payment.currency} ${payment.amount.toStringAsFixed(0)}',
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FamilyPaymentDetailPage(
                                    paymentId: payment.id,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
