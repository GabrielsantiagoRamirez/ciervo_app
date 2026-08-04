import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../data/vakupli_repository.dart';
import '../../domain/entities/vakupli_plan.dart';

/// Selector de contactos nacionales Ciervo para invitar a Vaku.
class VakupliContactsPickerPage extends StatefulWidget {
  const VakupliContactsPickerPage({super.key});

  @override
  State<VakupliContactsPickerPage> createState() =>
      _VakupliContactsPickerPageState();
}

class _VakupliContactsPickerPageState extends State<VakupliContactsPickerPage> {
  final _search = TextEditingController();
  final _repository = getIt<VakupliRepository>();
  Timer? _debounce;
  late Future<List<VakupliContact>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<List<VakupliContact>> _load({String? query}) async {
    final result = (query == null || query.trim().isEmpty)
        ? await _repository.contacts()
        : await _repository.searchContacts(query: query.trim());
    return result.when(
      success: (value) => value,
      failure: (error) => throw error,
    );
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      setState(() => _future = _load(query: value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitar contacto Ciervo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Buscar',
                hintText: '@usuario, CIERVO-… o nombre',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onQueryChanged,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<VakupliContact>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const CiervoLoadingState(itemCount: 5);
                }
                if (snapshot.hasError) {
                  return CiervoErrorState(
                    title: 'No pudimos cargar contactos',
                    description: UserErrorMessage.from(snapshot.error!),
                    onRetry: () => setState(() => _future = _load(
                          query: _search.text,
                        )),
                  );
                }
                final items = snapshot.data ?? const <VakupliContact>[];
                if (items.isEmpty) {
                  return const CiervoEmptyState(
                    title: 'Sin contactos en tu país',
                    description:
                        'Solo puedes invitar usuarios Ciervo del mismo país. '
                        'Busca por @usuario o CIERVO ID.',
                    icon: Icons.public_off_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final contact = items[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(contact.initials),
                      ),
                      title: Text(contact.displayName),
                      subtitle: Text(
                        contact.subtitle.isEmpty
                            ? 'Usuario Ciervo'
                            : contact.subtitle,
                      ),
                      trailing: contact.isFavorite
                          ? const Icon(Icons.star, size: 18)
                          : const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.of(context).pop('${contact.userId}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
