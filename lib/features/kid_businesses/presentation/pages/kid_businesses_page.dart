import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
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
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
