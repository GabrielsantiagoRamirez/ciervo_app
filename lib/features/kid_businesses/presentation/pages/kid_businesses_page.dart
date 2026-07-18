import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../kid_pay_for_me/presentation/pages/kid_pay_for_me_request_page.dart';
import '../../../kids_v2/data/repositories/kids_v2_repositories.dart';
import '../../../kids_v2/domain/models/kids_v2_models.dart';

class KidBusinessesPage extends StatefulWidget {
  const KidBusinessesPage({this.repository, super.key});

  final KidsRepository? repository;

  @override
  State<KidBusinessesPage> createState() => _KidBusinessesPageState();
}

class _KidBusinessesPageState extends State<KidBusinessesPage> {
  late final KidsRepository _repository;
  final _search = TextEditingController();
  List<KidsCommerceItem> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? getIt<KidsRepository>();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.searchCommerce(name: _search.text.trim());
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

  Future<void> _readQr() => _resolveCommerce(
    title: 'Leer QR de comercio',
    label: 'Contenido del QR',
    action: (value) => _repository.readCommerceQr(CommerceQrReadRequest(value)),
  );

  Future<void> _validateId() => _resolveCommerce(
    title: 'Validar ID de comercio',
    label: 'ID numérico',
    action: (value) {
      final id = int.tryParse(value);
      if (id == null || id <= 0) {
        throw const FormatException('invalid-commerce-id');
      }
      return _repository.validateCommerceId(CommerceIdValidateRequest(id));
    },
  );

  Future<void> _resolveCommerce({
    required String title,
    required String label,
    required Future<dynamic> Function(String value) action,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Validar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty || !mounted) return;
    try {
      final dynamic result = await action(value);
      if (!mounted) return;
      result.when(
        success: (KidsCommerceItem item) => _openBusinessActions(item),
        failure: (Object error) =>
            setState(() => _error = UserErrorMessage.from(error)),
      );
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = UserErrorMessage.from(error));
    }
  }

  Future<void> _openDetail(KidsCommerceItem item) async {
    final result = await _repository.commerce(item.commerceId);
    if (!mounted) return;
    result.when(
      success: _openBusinessActions,
      failure: (error) => setState(() => _error = UserErrorMessage.from(error)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis comercios')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: pagePaddingOf(context),
          children: [
            TextField(
              controller: _search,
              decoration: InputDecoration(
                labelText: 'Buscar',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _load,
                ),
              ),
              onSubmitted: (_) => _load(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _readQr,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Leer QR'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _validateId,
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Validar ID'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_loading)
              const CiervoLoadingState(itemCount: 4)
            else if (_error != null)
              Text(_error!, textAlign: TextAlign.center)
            else if (_items.isEmpty)
              const CiervoEmptyState(
                title: 'Sin comercios',
                description:
                    'No encontramos comercios CIERVO disponibles con esa búsqueda.',
                icon: Icons.storefront_outlined,
              )
            else
              ..._items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: CiervoCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.storefront_outlined),
                      title: Text(item.name),
                      subtitle: Text(
                        [item.address, item.city]
                            .whereType<String>()
                            .where((value) => value.isNotEmpty)
                            .join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openDetail(item),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBusinessActions(KidsCommerceItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.name,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              if (item.address != null) Text(item.address!),
              Text(
                item.acceptsCiervoPayments
                    ? 'Acepta pagos CIERVO'
                    : 'No acepta pagos CIERVO',
              ),
              if (item.requiresReservation)
                const Text('Este comercio requiere reserva'),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(Icons.family_restroom_outlined),
                title: const Text('Solicitar con Pinduck'),
                subtitle: const Text(
                  'El comercio y las reglas se validan antes de avisar a tu tutor',
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => KidPayForMeRequestPage(
                        businessId: '${item.commerceId}',
                        businessName: item.name,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
