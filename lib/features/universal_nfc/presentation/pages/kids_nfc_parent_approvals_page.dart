import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/universal_nfc_payment.dart';
import '../../domain/repositories/universal_nfc_repository.dart';
import '../utils/nfc_payment_ui.dart';

class KidsNfcParentApprovalsPage extends StatefulWidget {
  const KidsNfcParentApprovalsPage({super.key});

  @override
  State<KidsNfcParentApprovalsPage> createState() =>
      _KidsNfcParentApprovalsPageState();
}

class _KidsNfcParentApprovalsPageState
    extends State<KidsNfcParentApprovalsPage> {
  final _repository = getIt<UniversalNfcRepository>();
  List<KidsNfcParentApproval> _items = const [];
  bool _loading = true;
  String? _error;
  String? _actionId;

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
    final result = await _repository.kidsApprovals();
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

  Future<void> _approve(KidsNfcParentApproval item) async {
    setState(() => _actionId = item.paymentIntentId);
    final result = await _repository.approveKidsPayment(item.paymentIntentId);
    if (!mounted) return;
    setState(() => _actionId = null);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pago de ${item.kidName} autorizado.')),
        );
        _load();
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  Future<void> _reject(KidsNfcParentApproval item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar pago NFC'),
        content: Text(
          '¿Rechazar el pago de ${item.kidName} en ${item.merchantName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _actionId = item.paymentIntentId);
    final result = await _repository.rejectKidsPayment(item.paymentIntentId);
    if (!mounted) return;
    setState(() => _actionId = null);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago rechazado.')),
        );
        _load();
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.primary : theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Aprobaciones NFC Kids')),
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
                      CiervoErrorState(
                        title: 'No pudimos cargar solicitudes',
                        description: _error!,
                        onRetry: _load,
                      ),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        padding: pagePaddingOf(context),
                        children: const [
                          CiervoEmptyState(
                            title: 'Sin solicitudes pendientes',
                            description:
                                'Cuando tu hijo intente pagar con NFC, aparecerá aquí.',
                            icon: Icons.nfc_outlined,
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: pagePaddingOf(context),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final busy = _actionId == item.paymentIntentId;
                          return Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: maxContentWidthOf(context),
                              ),
                              child: CiervoCard(
                                showGradientOverlay: isDark,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: accent.withValues(
                                            alpha: isDark ? 0.2 : 0.15,
                                          ),
                                          child: Icon(
                                            Icons.nfc,
                                            color: accent,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.kidName,
                                                style: theme.textTheme.titleMedium,
                                              ),
                                              Text(
                                                item.merchantName,
                                                style: theme.textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          NfcPaymentUi.formatMoney(
                                            item.amount,
                                            item.currency,
                                          ),
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CiervoButton(
                                            label: busy ? '...' : 'Autorizar',
                                            icon: Icons.check,
                                            state: busy
                                                ? CiervoButtonState.loading
                                                : CiervoButtonState.normal,
                                            onPressed: busy
                                                ? null
                                                : () => _approve(item),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: CiervoButton(
                                            label: 'Rechazar',
                                            variant: CiervoButtonVariant.secondary,
                                            icon: Icons.close,
                                            onPressed: busy
                                                ? null
                                                : () => _reject(item),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
