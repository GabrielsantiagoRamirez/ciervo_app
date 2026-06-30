import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../kid_pay_for_me/presentation/pages/kid_pay_for_me_request_page.dart';
import '../../../kid_nfc/presentation/pages/kid_nfc_pay_page.dart';
import '../../../kid_me/data/kid_me_repository.dart';

class KidBusinessesPage extends StatefulWidget {
  const KidBusinessesPage({super.key});

  @override
  State<KidBusinessesPage> createState() => _KidBusinessesPageState();
}

class _KidBusinessesPageState extends State<KidBusinessesPage> {
  final _repository = getIt<KidMeRepository>();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
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
    final result = await _repository.allowedBusinesses(
      query: _search.text.trim(),
    );
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
            const SizedBox(height: AppSpacing.lg),
            if (_loading)
              const CiervoLoadingState(itemCount: 4)
            else if (_error != null)
              Text(_error!, textAlign: TextAlign.center)
            else if (_items.isEmpty)
              const CiervoEmptyState(
                title: 'Sin comercios',
                description:
                    'Tu tutor aún no ha habilitado comercios para ti.',
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
                      title: Text('${item['name'] ?? 'Comercio'}'),
                      subtitle: Text(
                        [
                          item['categoryName'] ?? item['category'],
                          item['city'],
                          item['zone'],
                        ].where((v) => v != null && '$v'.isNotEmpty).join(' · '),
                      ),
                      trailing: item['isOpen'] == false
                          ? const Text('Cerrado')
                          : const Icon(Icons.chevron_right),
                      onTap: () => _openBusinessActions(context, item),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBusinessActions(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final businessId = '${item['id'] ?? item['businessId'] ?? ''}';
    final businessName = '${item['name'] ?? 'Comercio'}';
    if (businessId.isEmpty) return;

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
                businessName,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(Icons.family_restroom_outlined),
                title: const Text('Pedir a mi familia'),
                subtitle: const Text('Tu tutor aprueba el pago'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => KidPayForMeRequestPage(
                        businessId: businessId,
                        businessName: businessName,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.nfc),
                title: const Text('Pagar con NFC / QR'),
                subtitle: const Text('Usa tu saldo en el comercio'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => KidNfcPayPage(
                        businessId: businessId,
                        businessName: businessName,
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
