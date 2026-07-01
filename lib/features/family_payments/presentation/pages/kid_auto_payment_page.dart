import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/kid_parental_rules.dart';
import '../../domain/repositories/family_payments_repository.dart';

class KidAutoPaymentPage extends StatefulWidget {
  const KidAutoPaymentPage({required this.kidId, super.key});
  final String kidId;

  @override
  State<KidAutoPaymentPage> createState() => _KidAutoPaymentPageState();
}

class _KidAutoPaymentPageState extends State<KidAutoPaymentPage> {
  final _repository = getIt<FamilyPaymentsRepository>();
  final _maxAmountController = TextEditingController();
  bool _enabled = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _maxAmountController.dispose();
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
    final result = await _repository.kidAutoPayment(widget.kidId);
    if (!mounted) return;
    result.when(
      success: (rules) {
        _enabled = rules.enabled;
        _maxAmountController.text =
            rules.maxAutomaticAmount?.toString() ?? '';
        setState(() => _loading = false);
      },
      failure: (error) => setState(() {
        _loading = false;
        _error = UserErrorMessage.from(error);
      }),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await _repository.saveKidAutoPayment(
      kidId: widget.kidId,
      rules: KidAutoPaymentRules(
        enabled: _enabled,
        maxAutomaticAmount: double.tryParse(
          _maxAmountController.text.trim().replaceAll(',', '.'),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago automático actualizado.')),
      ),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago automático')),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CiervoLoadingState(itemCount: 2),
            )
          : _error != null
              ? Padding(
                  padding: pagePaddingOf(context),
                  child: CiervoErrorState(
                    title: 'No pudimos cargar la configuración',
                    description: _error!,
                    onRetry: _load,
                  ),
                )
              : SingleChildScrollView(
                  padding: pagePaddingOf(context),
                  child: CiervoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchListTile(
                          title: const Text('Pago automático'),
                          subtitle: const Text(
                            'Usa tu tarjeta cuando el menor no tenga saldo.',
                          ),
                          value: _enabled,
                          onChanged: (value) => setState(() => _enabled = value),
                        ),
                        TextField(
                          controller: _maxAmountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Monto máximo automático (COP)',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
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
                ),
    );
  }
}
