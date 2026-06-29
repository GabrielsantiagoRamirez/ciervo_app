import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/repositories/kids_repository.dart';

class ChildSpendingLimitsPage extends StatefulWidget {
  const ChildSpendingLimitsPage({required this.childId, super.key});
  final String childId;

  @override
  State<ChildSpendingLimitsPage> createState() =>
      _ChildSpendingLimitsPageState();
}

class _ChildSpendingLimitsPageState extends State<ChildSpendingLimitsPage> {
  final _repository = getIt<KidsRepository>();
  final _dailyController = TextEditingController();
  final _weeklyController = TextEditingController();
  final _monthlyController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _dailyController.dispose();
    _weeklyController.dispose();
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
    final result = await _repository.spendingLimits(widget.childId);
    if (!mounted) return;
    result.when(
      success: (data) {
        _dailyController.text = _text(data['dailyLimit'] ?? data['daily']);
        _weeklyController.text = _text(data['weeklyLimit'] ?? data['weekly']);
        _monthlyController.text = _text(data['monthlyLimit'] ?? data['monthly']);
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
    final result = await _repository.updateSpendingLimits(widget.childId, {
      'dailyLimit': double.tryParse(_dailyController.text.replaceAll(',', '.')),
      'weeklyLimit': double.tryParse(_weeklyController.text.replaceAll(',', '.')),
      'monthlyLimit': double.tryParse(_monthlyController.text.replaceAll(',', '.')),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Limites actualizados.')),
        );
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  String _text(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Limites de gasto')),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CiervoLoadingState(itemCount: 3),
            )
          : _error != null
          ? Padding(
              padding: pagePaddingOf(context),
              child: CiervoErrorState(
                title: 'No pudimos cargar limites',
                description: _error!,
                onRetry: _load,
              ),
            )
          : SingleChildScrollView(
              padding: pagePaddingOf(context),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidthOf(context)),
                  child: CiervoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Define cuanto puede gastar el menor por periodo.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _dailyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Limite diario (COP)',
                            prefixIcon: Icon(Icons.today_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _weeklyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Limite semanal (COP)',
                            prefixIcon: Icon(Icons.date_range_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _monthlyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Limite mensual (COP)',
                            prefixIcon: Icon(Icons.calendar_month_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        CiervoButton(
                          label: _saving ? 'Guardando' : 'Guardar limites',
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
              ),
            ),
    );
  }
}
