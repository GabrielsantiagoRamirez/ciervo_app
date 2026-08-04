import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../loyalty/data/loyalty_repository.dart';
import '../../../memberships/presentation/cubit/membership_cubit.dart';
import '../../../qr_wallet/presentation/pages/qr_wallet_page.dart';
import '../../data/cashback_repository.dart';

class CashbackPage extends StatefulWidget {
  const CashbackPage({super.key});

  @override
  State<CashbackPage> createState() => _CashbackPageState();
}

class _CashbackPageState extends State<CashbackPage> {
  late Future<_CashbackState> _state;
  bool _redeeming = false;

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
    final loyalty = getIt<LoyaltyRepository>();

    final results = await Future.wait([
      loyalty.summary(),
      cashback.pointsBalance(),
      cashback.pointsHistory(),
    ]);

    final errors = <String>[];

    final summary = (results[0] as Result<LoyaltySummary>).when(
      success: (value) => value,
      failure: (error) {
        errors.add('Resumen: ${UserErrorMessage.from(error)}');
        return null;
      },
    );

    final balance = (results[1] as Result<PointsBalance>).when(
      success: (value) => value,
      failure: (error) {
        errors.add('Balance: ${UserErrorMessage.from(error)}');
        return null;
      },
    );

    final history = (results[2] as Result<List<Map<String, dynamic>>>).when(
      success: (value) => value,
      failure: (_) => const <Map<String, dynamic>>[],
    );

    return _CashbackState(
      summary: summary,
      balance: balance,
      history: history,
      errors: errors,
    );
  }

  Future<void> _redeem(int maxPoints) async {
    final controller = TextEditingController();
    final noteController = TextEditingController();
    final points = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Canjear puntos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Disponibles: $maxPoints puntos'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Puntos a canjear',
                hintText: 'Ej. 500',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value <= 0) return;
              if (value > maxPoints) return;
              Navigator.pop(context, value);
            },
            child: const Text('Canjear'),
          ),
        ],
      ),
    );
    final noteText = noteController.text.trim();
    controller.dispose();
    noteController.dispose();
    if (points == null || !mounted) return;

    setState(() => _redeeming = true);
    final result = await getIt<CashbackRepository>().redeemPoints(
      points: points,
      note: noteText.isEmpty ? null : noteText,
    );
    if (!mounted) return;
    setState(() => _redeeming = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Canjeaste $points puntos.')),
        );
        setState(_load);
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
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
        final redeemable =
            state.summary?.pointsAvailable ?? state.balance?.balance ?? 0;
        return RefreshIndicator(
          onRefresh: () async => setState(_load),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _LoyaltySummaryCard(summary: state.summary),
              const SizedBox(height: AppSpacing.md),
              _PointsBalanceCard(balance: state.balance),
              const SizedBox(height: AppSpacing.md),
              if (redeemable > 0) ...[
                CiervoButton(
                  label: 'Canjear puntos',
                  icon: Icons.redeem_outlined,
                  state: _redeeming
                      ? CiervoButtonState.loading
                      : CiervoButtonState.normal,
                  onPressed: _redeeming ? null : () => _redeem(redeemable),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const _PlanBenefitSummary(),
              const SizedBox(height: AppSpacing.md),
              _HistoryList(history: state.history),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const QrWalletPage()),
                ),
                icon: const Icon(Icons.card_giftcard_outlined),
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

class _LoyaltySummaryCard extends StatelessWidget {
  const _LoyaltySummaryCard({required this.summary});

  final LoyaltySummary? summary;

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return const CiervoEmptyState(
        title: 'Resumen no disponible',
        description: 'No pudimos cargar tu nivel de lealtad.',
        icon: Icons.stars_outlined,
      );
    }
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tu nivel', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            summary!.level,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Cashback',
                  value: '${summary!.cashbackAvailable}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricTile(
                  label: 'Puntos',
                  value: '${summary!.pointsAvailable}',
                ),
              ),
            ],
          ),
          if (summary!.progressPercent > 0) ...[
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              value: (summary!.progressPercent / 100).clamp(0.0, 1.0),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Progreso al siguiente nivel: ${summary!.progressPercent}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _PointsBalanceCard extends StatelessWidget {
  const _PointsBalanceCard({required this.balance});

  final PointsBalance? balance;

  @override
  Widget build(BuildContext context) {
    if (balance == null) {
      return const SizedBox.shrink();
    }
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Balance de puntos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${balance!.balance}',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Ganados',
                  value: '${balance!.earned}',
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: 'Gastados',
                  value: '${balance!.spent}',
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: 'Revertidos',
                  value: '${balance!.reversed}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

class _PlanBenefitSummary extends StatelessWidget {
  const _PlanBenefitSummary();

  @override
  Widget build(BuildContext context) {
    final membership = context.watch<MembershipCubit>().state;
    final planName = membership.isLoaded ? membership.planName : 'tu plan';
    final pointsLimit = membership.limits['points.multiplier'];
    final cashbackLimit = membership.limits['cashback.multiplier'] ??
        membership.limits['cashbackPercent'];
    final multiplier = pointsLimit?.multiplier ?? cashbackLimit?.multiplier;
    final percentOrFactor = pointsLimit?.limitValue ?? cashbackLimit?.limitValue;

    String benefitLine;
    if (multiplier != null && multiplier > 0) {
      benefitLine =
          'Con $planName acumulas puntos con multiplicador ${multiplier}x.';
    } else if (percentOrFactor != null && percentOrFactor > 0) {
      benefitLine =
          'Con $planName tu beneficio de puntos/cashback es ${percentOrFactor}x.';
    } else {
      benefitLine =
          'Ganas puntos y cashback al pagar con CIERVO en comercios participantes. '
          'Tu plan $planName define el beneficio.';
    }

    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu beneficio',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(benefitLine),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Los movimientos aparecen abajo cuando acumules puntos.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.history});

  final List<Map<String, dynamic>> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
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
          ...history
              .take(20)
              .map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${item['description'] ?? item['type'] ?? 'Movimiento'}',
                  ),
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
    required this.summary,
    required this.balance,
    required this.history,
    required this.errors,
  });

  factory _CashbackState.empty() => const _CashbackState(
    summary: null,
    balance: null,
    history: [],
    errors: [],
  );

  final LoyaltySummary? summary;
  final PointsBalance? balance;
  final List<Map<String, dynamic>> history;
  final List<String> errors;
}
