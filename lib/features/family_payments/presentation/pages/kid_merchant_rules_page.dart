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

class KidMerchantRulesPage extends StatefulWidget {
  const KidMerchantRulesPage({required this.kidId, super.key});
  final String kidId;

  @override
  State<KidMerchantRulesPage> createState() => _KidMerchantRulesPageState();
}

class _KidMerchantRulesPageState extends State<KidMerchantRulesPage> {
  final _familyRepo = getIt<FamilyPaymentsRepository>();
  final _kidsRepo = getIt<KidsRepository>();
  final _searchController = TextEditingController();
  KidMerchantRules _rules = const KidMerchantRules();
  List<Map<String, dynamic>> _categories = const [];
  List<Map<String, dynamic>> _businesses = const [];
  List<Map<String, dynamic>> _searchResults = const [];
  bool _loading = true;
  bool _saving = false;
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
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
    final rules = await _familyRepo.kidMerchantRules(widget.kidId);
    final categories = await _kidsRepo.allowedCategories(widget.kidId);
    final businesses = await _kidsRepo.allowedBusinesses(widget.kidId);
    if (!mounted) return;
    String? error;
    rules.when(
      success: (value) => _rules = value,
      failure: (e) => error = UserErrorMessage.from(e),
    );
    categories.when(
      success: (items) => _categories = _mapList(items),
      failure: (e) => error ??= UserErrorMessage.from(e),
    );
    businesses.when(
      success: (items) => _businesses = _mapList(items),
      failure: (e) => error ??= UserErrorMessage.from(e),
    );
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  List<Map<String, dynamic>> _mapList(List<dynamic> items) => items
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  Future<void> _searchBusinesses() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _searching = true);
    final result = await _kidsRepo.businessCandidates(
      widget.kidId,
      query: query,
    );
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _searchResults = _mapList(items);
        _searching = false;
      }),
      failure: (error) {
        setState(() => _searching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await _familyRepo.saveKidMerchantRules(
      kidId: widget.kidId,
      rules: _rules,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reglas de comercios guardadas.')),
      ),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  int _categoryId(Map<String, dynamic> item) =>
      int.tryParse('${item['categoryId'] ?? item['id']}') ?? 0;

  String _categoryName(Map<String, dynamic> item) =>
      '${item['name'] ?? item['displayName'] ?? 'Categoría'}';

  String _businessId(Map<String, dynamic> item) =>
      '${item['businessId'] ?? item['id']}';

  String _businessName(Map<String, dynamic> item) =>
      '${item['name'] ?? item['displayName'] ?? 'Comercio'}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comercios')),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CiervoLoadingState(itemCount: 4),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Categorías permitidas',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          ..._categories.map(
                            (item) {
                              final id = _categoryId(item);
                              final allowed =
                                  _rules.allowedCategoryIds.contains(id);
                              final blocked =
                                  _rules.blockedCategoryIds.contains(id);
                              return CheckboxListTile(
                                value: allowed,
                                secondary: blocked
                                    ? const Icon(Icons.block, color: Colors.red)
                                    : null,
                                title: Text(_categoryName(item)),
                                subtitle: blocked
                                    ? const Text('Bloqueada')
                                    : allowed
                                        ? const Text('Permitida')
                                        : null,
                                onChanged: (value) => setState(() {
                                  final allowedIds =
                                      List<int>.from(_rules.allowedCategoryIds);
                                  final blockedIds =
                                      List<int>.from(_rules.blockedCategoryIds);
                                  blockedIds.remove(id);
                                  if (value == true) {
                                    if (!allowedIds.contains(id)) {
                                      allowedIds.add(id);
                                    }
                                  } else {
                                    allowedIds.remove(id);
                                  }
                                  _rules = KidMerchantRules(
                                    allowedCategoryIds: allowedIds,
                                    blockedCategoryIds: blockedIds,
                                    allowedBusinessIds:
                                        _rules.allowedBusinessIds,
                                    blockedBusinessIds:
                                        _rules.blockedBusinessIds,
                                  );
                                }),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CiervoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Buscar comercio',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    hintText: 'Nombre del comercio',
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _searching ? null : _searchBusinesses,
                                icon: _searching
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.search),
                              ),
                            ],
                          ),
                          ..._searchResults.map(
                            (item) {
                              final id = _businessId(item);
                              final allowed =
                                  _rules.allowedBusinessIds.contains(id);
                              final blocked =
                                  _rules.blockedBusinessIds.contains(id);
                              return ListTile(
                                title: Text(_businessName(item)),
                                subtitle: Text(
                                  blocked
                                      ? 'Bloqueado'
                                      : allowed
                                          ? 'Permitido'
                                          : 'Sin regla',
                                ),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      tooltip: 'Permitir',
                                      onPressed: () => setState(() {
                                        final allowedIds = List<String>.from(
                                          _rules.allowedBusinessIds,
                                        );
                                        final blockedIds = List<String>.from(
                                          _rules.blockedBusinessIds,
                                        );
                                        blockedIds.remove(id);
                                        if (!allowedIds.contains(id)) {
                                          allowedIds.add(id);
                                        }
                                        _rules = KidMerchantRules(
                                          allowedCategoryIds:
                                              _rules.allowedCategoryIds,
                                          blockedCategoryIds:
                                              _rules.blockedCategoryIds,
                                          allowedBusinessIds: allowedIds,
                                          blockedBusinessIds: blockedIds,
                                        );
                                      }),
                                      icon: const Icon(Icons.check_circle_outline),
                                    ),
                                    IconButton(
                                      tooltip: 'Bloquear',
                                      onPressed: () => setState(() {
                                        final allowedIds = List<String>.from(
                                          _rules.allowedBusinessIds,
                                        );
                                        final blockedIds = List<String>.from(
                                          _rules.blockedBusinessIds,
                                        );
                                        allowedIds.remove(id);
                                        if (!blockedIds.contains(id)) {
                                          blockedIds.add(id);
                                        }
                                        _rules = KidMerchantRules(
                                          allowedCategoryIds:
                                              _rules.allowedCategoryIds,
                                          blockedCategoryIds:
                                              _rules.blockedCategoryIds,
                                          allowedBusinessIds: allowedIds,
                                          blockedBusinessIds: blockedIds,
                                        );
                                      }),
                                      icon: const Icon(Icons.block),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
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
