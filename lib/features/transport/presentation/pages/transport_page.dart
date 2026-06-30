import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_labels.dart';
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
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _state = _load());
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
    appBar: AppBar(title: const Text('Transporte')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _creating ? null : _createCard,
      icon: _creating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_card_outlined),
      label: Text(_creating ? 'Creando…' : 'Nueva tarjeta'),
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
              onRetry: _reload,
            ),
          );
        }
        final state = snapshot.data ?? const _TransportState();
        final moduleStatus = state.cards
            .map((card) => card.moduleStatus)
            .whereType<String>()
            .firstOrNull;
        final isPilot = moduleStatus?.toLowerCase() == 'pilot';
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (isPilot)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: CiervoCard(
                    child: Row(
                      children: [
                        Icon(
                          Icons.science_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            DisplayLabels.moduleStatusLabel(moduleStatus),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              CiervoCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_bus_filled,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Administra tus tarjetas de transporte y consulta descuentos disponibles en tu ciudad.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Mis tarjetas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.cards.isEmpty)
                const CiervoEmptyState(
                  title: 'Sin tarjetas',
                  description:
                      'Crea una tarjeta para validar tu acceso al transporte y ver descuentos.',
                  icon: Icons.credit_card,
                )
              else
                ...state.cards.map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _CardTile(
                      card: card,
                      onValidate: () => _validate(card.id),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text('Descuentos', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              if (state.discounts.isEmpty)
                const CiervoEmptyState(
                  title: 'Sin descuentos',
                  description:
                      'Aún no hay descuentos de transporte configurados en tu zona.',
                  icon: Icons.local_offer_outlined,
                )
              else
                ...state.discounts.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: CiervoCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.percent,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          '${item['name'] ?? item['title'] ?? 'Descuento'}',
                        ),
                        subtitle: Text(
                          DisplayLabels.sanitizeDiscountDescription(
                            '${item['description'] ?? ''}',
                          ),
                        ),
                      ),
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
    setState(() => _creating = true);
    final result = await getIt<TransportRepository>().createCard();
    if (!mounted) return;
    setState(() => _creating = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarjeta creada correctamente.')),
        );
        _reload();
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  Future<void> _validate(String cardId) async {
    final result = await getIt<TransportRepository>().validate(cardId);
    if (!mounted) return;
    result.when(
      success: (value) => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.verified_outlined),
          title: const Text('Validación exitosa'),
          content: Text(
            '${value['msg'] ?? value['message'] ?? 'Tu tarjeta fue validada correctamente.'}',
          ),
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
  Widget build(BuildContext context) {
    final status = DisplayLabels.transportCardStatus(card.status);
    final statusColor = card.status.toLowerCase() == 'active'
        ? Colors.green
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return CiervoCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_bus_outlined),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.publicCode ?? card.cardNumber ?? 'Tarjeta ${card.id}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                ),
                if (card.balance != null)
                  Text(
                    'Saldo: ${card.balance} ${card.currency ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: onValidate,
            child: const Text('Validar'),
          ),
        ],
      ),
    );
  }
}

class _TransportState {
  const _TransportState({
    this.cards = const [],
    this.discounts = const [],
  });

  final List<TransportCard> cards;
  final List<Map<String, dynamic>> discounts;
}
