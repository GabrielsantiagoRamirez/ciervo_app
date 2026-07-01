import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/family_payment_card.dart';
import '../../domain/entities/kid_parental_rules.dart';
import '../../domain/repositories/family_payments_repository.dart';

class KidPaymentSourcePage extends StatefulWidget {
  const KidPaymentSourcePage({
    required this.kidId,
    required this.kidName,
    super.key,
  });

  final String kidId;
  final String kidName;

  @override
  State<KidPaymentSourcePage> createState() => _KidPaymentSourcePageState();
}

class _KidPaymentSourcePageState extends State<KidPaymentSourcePage> {
  final _repository = getIt<FamilyPaymentsRepository>();
  List<FamilyPaymentCard> _cards = const [];
  KidPaymentSource? _source;
  bool _loading = true;
  bool _saving = false;
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
    final cards = await _repository.listCards();
    final source = await _repository.kidPaymentSource(widget.kidId);
    if (!mounted) return;
    String? error;
    cards.when(
      success: (value) => _cards = value.where((c) => c.isActive).toList(),
      failure: (e) => error = UserErrorMessage.from(e),
    );
    source.when(
      success: (value) => _source = value,
      failure: (e) => error ??= UserErrorMessage.from(e),
    );
    setState(() {
      _loading = false;
      _error = error;
      _source ??= const KidPaymentSource();
    });
  }

  Future<void> _save() async {
    final current = _source;
    if (current == null) return;
    setState(() => _saving = true);
    final result = await _repository.saveKidPaymentSource(
      kidId: widget.kidId,
      source: current,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fuente de pago actualizada.')),
      ),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fuente de pago')),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CiervoLoadingState(itemCount: 3),
            )
          : _error != null
              ? Padding(
                  padding: pagePaddingOf(context),
                  child: CiervoErrorState(
                    title: 'No pudimos cargar la fuente de pago',
                    description: _error!,
                    onRetry: _load,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: pagePaddingOf(context),
                    children: [
                      Text(
                        'Si ${widget.kidName} no tiene saldo, CIERVO puede usar tu tarjeta registrada.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SwitchListTile(
                        title: const Text('Usar tarjeta principal'),
                        subtitle: const Text(
                          'Prioriza la tarjeta marcada como principal.',
                        ),
                        value: _source?.usePrimaryCard ?? true,
                        onChanged: (value) => setState(
                          () => _source = KidPaymentSource(
                            cardId: value ? null : _source?.cardId,
                            mode: _source?.mode ??
                                KidPaymentApprovalMode.autoApproval,
                            usePrimaryCard: value,
                          ),
                        ),
                      ),
                      if (_source?.usePrimaryCard != true) ...[
                        const SizedBox(height: AppSpacing.sm),
                        ..._cards.map(
                          (card) => RadioListTile<String>(
                            value: card.id,
                            groupValue: _source?.cardId,
                            onChanged: (value) => setState(
                              () => _source = KidPaymentSource(
                                cardId: value,
                                mode: _source?.mode ??
                                    KidPaymentApprovalMode.autoApproval,
                                usePrimaryCard: false,
                              ),
                            ),
                            title: Text(
                              card.alias.isNotEmpty
                                  ? card.alias
                                  : card.maskedNumber,
                            ),
                            subtitle:
                                Text('${card.brand} · ${card.maskedNumber}'),
                          ),
                        ),
                      ],
                      const Divider(height: 32),
                      Text('Modo', style: Theme.of(context).textTheme.titleMedium),
                      RadioListTile<KidPaymentApprovalMode>(
                        value: KidPaymentApprovalMode.autoApproval,
                        groupValue: _source?.mode,
                        onChanged: (value) => setState(
                          () => _source = KidPaymentSource(
                            cardId: _source?.cardId,
                            mode: value!,
                            usePrimaryCard: _source?.usePrimaryCard ?? true,
                          ),
                        ),
                        title: const Text('Aprobación automática'),
                      ),
                      RadioListTile<KidPaymentApprovalMode>(
                        value: KidPaymentApprovalMode.manualApproval,
                        groupValue: _source?.mode,
                        onChanged: (value) => setState(
                          () => _source = KidPaymentSource(
                            cardId: _source?.cardId,
                            mode: value!,
                            usePrimaryCard: _source?.usePrimaryCard ?? true,
                          ),
                        ),
                        title: const Text('Requiere aprobación del tutor'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CiervoButton(
                        label: _saving ? 'Guardando...' : 'Guardar',
                        icon: Icons.save_outlined,
                        state: _saving
                            ? CiervoButtonState.loading
                            : CiervoButtonState.normal,
                        onPressed: _saving ? null : _save,
                      ),
                    ],
                  ),
                ),
    );
  }
}
