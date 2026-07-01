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

class KidFamilyLimitsPage extends StatefulWidget {
  const KidFamilyLimitsPage({required this.kidId, super.key});
  final String kidId;

  @override
  State<KidFamilyLimitsPage> createState() => _KidFamilyLimitsPageState();
}

class _KidFamilyLimitsPageState extends State<KidFamilyLimitsPage> {
  final _repository = getIt<FamilyPaymentsRepository>();
  final _purchaseController = TextEditingController();
  final _dailyController = TextEditingController();
  final _monthlyController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _purchaseController.dispose();
    _dailyController.dispose();
    _monthlyController.dispose();
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
    final result = await _repository.kidLimits(widget.kidId);
    if (!mounted) return;
    result.when(
      success: (limits) {
        _purchaseController.text = _text(limits.perPurchaseLimit);
        _dailyController.text = _text(limits.dailyLimit);
        _monthlyController.text = _text(limits.monthlyLimit);
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
    final result = await _repository.saveKidLimits(
      kidId: widget.kidId,
      limits: KidSpendingLimits(
        perPurchaseLimit: _parse(_purchaseController.text),
        dailyLimit: _parse(_dailyController.text),
        monthlyLimit: _parse(_monthlyController.text),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Límites actualizados.')),
      ),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  double? _parse(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  String _text(double? value) => value?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Límites')),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CiervoLoadingState(itemCount: 3),
            )
          : _error != null
              ? Padding(
                  padding: pagePaddingOf(context),
                  child: CiervoErrorState(
                    title: 'No pudimos cargar los límites',
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
                        _limitField(
                          controller: _purchaseController,
                          label: 'Límite por compra (COP)',
                          icon: Icons.shopping_bag_outlined,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _limitField(
                          controller: _dailyController,
                          label: 'Límite diario (COP)',
                          icon: Icons.today_outlined,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _limitField(
                          controller: _monthlyController,
                          label: 'Límite mensual (COP)',
                          icon: Icons.calendar_month_outlined,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        CiervoButton(
                          label: _saving ? 'Guardando...' : 'Guardar límites',
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

  Widget _limitField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}
