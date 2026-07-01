import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../kids/domain/repositories/kids_repository.dart';
import '../../domain/entities/kid_parental_rules.dart';
import '../../domain/repositories/family_payments_repository.dart';

class KidApprovalRulesPage extends StatefulWidget {
  const KidApprovalRulesPage({required this.kidId, super.key});
  final String kidId;

  @override
  State<KidApprovalRulesPage> createState() => _KidApprovalRulesPageState();
}

class _KidApprovalRulesPageState extends State<KidApprovalRulesPage> {
  final _familyRepo = getIt<FamilyPaymentsRepository>();
  final _kidsRepo = getIt<KidsRepository>();
  final _thresholdController = TextEditingController();
  final Set<int> _alwaysApproved = {};
  final Set<int> _alwaysManual = {};
  List<Map<String, dynamic>> _categories = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _thresholdController.dispose();
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
    final rules = await _familyRepo.kidApprovalRules(widget.kidId);
    final categories = await _kidsRepo.categoryCandidates(widget.kidId);
    if (!mounted) return;
    String? error;
    rules.when(
      success: (value) {
        _thresholdController.text =
            value.requireApprovalFromAmount?.toString() ?? '';
        _alwaysApproved
          ..clear()
          ..addAll(value.alwaysApprovedCategoryIds);
        _alwaysManual
          ..clear()
          ..addAll(value.alwaysManualCategoryIds);
      },
      failure: (e) => error = UserErrorMessage.from(e),
    );
    categories.when(
      success: (items) => _categories = items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      failure: (e) => error ??= UserErrorMessage.from(e),
    );
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  int _categoryId(Map<String, dynamic> item) =>
      int.tryParse('${item['categoryId'] ?? item['id']}') ?? 0;

  String _categoryName(Map<String, dynamic> item) =>
      '${item['name'] ?? item['displayName'] ?? 'Categoría'}';

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await _familyRepo.saveKidApprovalRules(
      kidId: widget.kidId,
      rules: KidApprovalRules(
        requireApprovalFromAmount: double.tryParse(
          _thresholdController.text.trim().replaceAll(',', '.'),
        ),
        alwaysApprovedCategoryIds: _alwaysApproved.toList(),
        alwaysManualCategoryIds: _alwaysManual.toList(),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reglas de aprobación guardadas.')),
      ),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reglas de aprobación')),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CiervoLoadingState(itemCount: 3),
            )
          : _error != null
              ? Padding(
                  padding: pagePaddingOf(context),
                  child: CiervoErrorState(
                    title: 'No pudimos cargar las reglas',
                    description: _error!,
                    onRetry: _load,
                  ),
                )
              : ListView(
                  padding: pagePaddingOf(context),
                  children: [
                    CiervoCard(
                      child: TextField(
                        controller: _thresholdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Requerir aprobación desde (COP)',
                          prefixIcon: Icon(Icons.price_check_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CiervoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Categorías siempre aprobadas',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          ..._categories.map((item) {
                            final id = _categoryId(item);
                            return CheckboxListTile(
                              value: _alwaysApproved.contains(id),
                              onChanged: (value) => setState(() {
                                if (value == true) {
                                  _alwaysApproved.add(id);
                                  _alwaysManual.remove(id);
                                } else {
                                  _alwaysApproved.remove(id);
                                }
                              }),
                              title: Text(_categoryName(item)),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CiervoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Categorías siempre manuales',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          ..._categories.map((item) {
                            final id = _categoryId(item);
                            return CheckboxListTile(
                              value: _alwaysManual.contains(id),
                              onChanged: (value) => setState(() {
                                if (value == true) {
                                  _alwaysManual.add(id);
                                  _alwaysApproved.remove(id);
                                } else {
                                  _alwaysManual.remove(id);
                                }
                              }),
                              title: Text(_categoryName(item)),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CiervoButton(
                      label: _saving ? 'Guardando...' : 'Guardar reglas',
                      icon: Icons.save_outlined,
                      state: _saving
                          ? CiervoButtonState.loading
                          : CiervoButtonState.normal,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
    );
  }
}
