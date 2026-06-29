import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../data/transport_repository.dart';

class TransportPage extends StatefulWidget {
  const TransportPage({super.key});

  @override
  State<TransportPage> createState() => _TransportPageState();
}

class _TransportPageState extends State<TransportPage> {
  late Future<_TransportState> _state;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _state = _load();
  }

  Future<_TransportState> _load() async {
    final repository = getIt<TransportRepository>();
    final cards = await repository.cards();
    final discounts = await repository.discounts();
    return _TransportState(
      cards: cards.when(success: (v) => v, failure: (_) => const []),
      discounts: discounts.when(success: (v) => v, failure: (_) => const []),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Transporte de prueba')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _createCard,
      icon: const Icon(Icons.add_card_outlined),
      label: const Text('Crear tarjeta'),
    ),
    body: FutureBuilder<_TransportState>(
      future: _state,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CiervoLoadingState();
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: CiervoErrorState(
              title: 'No pudimos cargar transporte',
              description: UserErrorMessage.from(snapshot.error!),
              onRetry: () => setState(_reload),
            ),
          );
        }
        final state = snapshot.data ?? const _TransportState();
        return RefreshIndicator(
          onRefresh: () async => setState(_reload),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const CiervoCard(
                child: Text(
                  'Modulo de prueba/futuro: permite validar una tarjeta de transporte de prueba y revisar descuentos simulados.',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state.cards.isEmpty)
                const CiervoEmptyState(
                  title: 'Sin tarjetas',
                  description: 'Crea una tarjeta de prueba para probar validacion.',
                  icon: Icons.credit_card,
                )
              else
                ...state.cards.map((card) => _CardTile(
                      card: card,
                      onValidate: () => _validate(card.id),
                    )),
              const SizedBox(height: AppSpacing.lg),
              Text('Descuentos', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              if (state.discounts.isEmpty)
                const Text('Sin descuentos configurados.')
              else
                ...state.discounts.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text('${item['name'] ?? item['title'] ?? 'Descuento'}'),
                      subtitle: Text('${item['description'] ?? ''}'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _createCard() async {
    final result = await getIt<TransportRepository>().createCard();
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarjeta de prueba creada.')),
        );
        setState(_reload);
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  Future<void> _validate(String cardId) async {
    final result = await getIt<TransportRepository>().validateMock(cardId);
    if (!mounted) return;
    result.when(
      success: (value) => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Validacion de prueba'),
          content: Text('${value['msg'] ?? value['message'] ?? value}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.onValidate});

  final TransportCard card;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.directions_bus_outlined),
      title: Text(card.cardNumber ?? 'Tarjeta ${card.id}'),
      subtitle: Text(
        '${card.status} - ${card.balance ?? 0} ${card.currency ?? ''}',
      ),
      trailing: TextButton(
        onPressed: onValidate,
        child: const Text('Validar'),
      ),
    ),
  );
}

class _TransportState {
  const _TransportState({
    this.cards = const [],
    this.discounts = const [],
  });

  final List<TransportCard> cards;
  final List<Map<String, dynamic>> discounts;
}
