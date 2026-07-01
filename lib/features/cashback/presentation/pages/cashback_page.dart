import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../qr_wallet/data/qr_wallet_repository.dart';
import '../../../qr_wallet/presentation/pages/qr_wallet_page.dart';
import '../../data/cashback_repository.dart';
import '../../domain/entities/cashback_rule.dart';

class CashbackPage extends StatefulWidget {
  const CashbackPage({super.key});

  @override
  State<CashbackPage> createState() => _CashbackPageState();
}

class _CashbackPageState extends State<CashbackPage> {
  late Future<_CashbackState> _state;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _state = _fetch();
  }

  Future<_CashbackState> _fetch() async {
    final cashback = getIt<CashbackRepository>();
    final rulesResult = await cashback.rules();
    final pointsResult = await getIt<QrWalletRepository>().rewardPoints();
    final futureBalanceResult = await cashback.rewardBalance();
    final futureTransactionsResult = await cashback.rewardTransactions();
    final errors = <String>[];
    final rules = rulesResult.when(
      success: (value) => value,
      failure: (error) {
        errors.add('Cashback: ${UserErrorMessage.from(error)}');
        return const <CashbackRule>[];
      },
    );
    final points = pointsResult.when(
      success: (value) => value,
      failure: (error) {
        errors.add('Puntos: ${UserErrorMessage.from(error)}');
        return null;
      },
    );
    final futureBalance = futureBalanceResult.when(
      success: (value) => value,
      failure: (_) => null,
    );
    final transactions = futureTransactionsResult.when(
      success: (value) => value,
      failure: (_) => const <Map<String, dynamic>>[],
    );
    return _CashbackState(
      rules: rules,
      points: futureBalance ?? points,
      transactions: transactions,
      errors: errors,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cashback y puntos')),
        body: FutureBuilder<_CashbackState>(
          future: _state,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const CiervoLoadingState(itemCount: 4);
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: CiervoErrorState(
                  title: 'No pudimos cargar cashback',
                  description: UserErrorMessage.from(snapshot.error!),
                  onRetry: () => setState(_load),
                ),
              );
            }
            final state = snapshot.data ?? _CashbackState.empty();
            return RefreshIndicator(
              onRefresh: () async => setState(_load),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _PointsSummary(state: state),
                  const SizedBox(height: AppSpacing.md),
                  _HowToEarn(rules: state.rules),
                  const SizedBox(height: AppSpacing.md),
                  _Transactions(transactions: state.transactions),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const QrWalletPage(),
                      ),
                    ),
                    icon: const Icon(Icons.redeem_outlined),
                    label: const Text('Ver beneficios disponibles'),
                  ),
                  if (state.errors.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    CiervoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: state.errors.map(Text.new).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      );
}

class _PointsSummary extends StatelessWidget {
  const _PointsSummary({required this.state});

  final _CashbackState state;

  @override
  Widget build(BuildContext context) => CiervoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.points == null ? 'Puntos no disponibles' : '${state.points} puntos',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Cashback acumulado y multiplicador se calculan segun tu membresia.'),
          ],
        ),
      );
}

class _HowToEarn extends StatelessWidget {
  const _HowToEarn({required this.rules});

  final List<CashbackRule> rules;

  @override
  Widget build(BuildContext context) {
    if (rules.isEmpty) {
      return const CiervoEmptyState(
        title: 'Sin reglas visibles',
        description:
            'Aún no hay reglas de cashback configuradas para tu plan. Revisa más tarde.',
        icon: Icons.savings_outlined,
      );
    }
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Como ganar puntos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          ...rules.where((rule) => rule.isActive).map(
                (rule) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.savings_outlined),
                    title: Text(rule.name.isEmpty ? 'Cashback' : rule.name),
                    subtitle: Text(
                      [
                        if (rule.description.isNotEmpty) rule.description,
                        if (rule.membershipTier.isNotEmpty) rule.membershipTier,
                      ].join(' - '),
                    ),
                    trailing: Text(
                      rule.percentage > 0
                          ? '${rule.percentage.toStringAsFixed(1)}%'
                          : '${rule.pointsMultiplier.toStringAsFixed(2)}x',
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _Transactions extends StatelessWidget {
  const _Transactions({required this.transactions});

  final List<Map<String, dynamic>> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const CiervoEmptyState(
        title: 'Sin historial de puntos',
        description:
            'Cuando uses Ciervo y acumules puntos, tus movimientos aparecerán aquí.',
        icon: Icons.timeline_outlined,
      );
    }
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historial', style: Theme.of(context).textTheme.titleLarge),
          ...transactions.take(20).map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${item['description'] ?? item['type'] ?? 'Movimiento'}'),
                  subtitle: Text('${item['createdAt'] ?? item['date'] ?? ''}'),
                  trailing: Text('${item['points'] ?? item['amount'] ?? ''}'),
                ),
              ),
        ],
      ),
    );
  }
}

class _CashbackState {
  const _CashbackState({
    required this.rules,
    required this.points,
    required this.transactions,
    required this.errors,
  });

  factory _CashbackState.empty() => const _CashbackState(
        rules: [],
        points: null,
        transactions: [],
        errors: [],
      );

  final List<CashbackRule> rules;
  final int? points;
  final List<Map<String, dynamic>> transactions;
  final List<String> errors;
}
