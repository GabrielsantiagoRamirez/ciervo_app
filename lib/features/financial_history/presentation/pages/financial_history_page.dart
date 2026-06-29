import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/repositories/financial_history_repository.dart';
import '../cubit/financial_history_cubit.dart';
import '../cubit/financial_history_state.dart';

class FinancialHistoryPage extends StatelessWidget {
  const FinancialHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          FinancialHistoryCubit(getIt<FinancialHistoryRepository>())..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Historial financiero')),
        body: BlocBuilder<FinancialHistoryCubit, FinancialHistoryState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: switch (state.status) {
                FinancialHistoryStatus.initial ||
                FinancialHistoryStatus.loading => const CiervoLoadingState(),
                FinancialHistoryStatus.empty => const CiervoEmptyState(
                  title: 'Sin historial',
                  description:
                      'Aun no tienes movimientos financieros consolidados.',
                  icon: Icons.timeline_outlined,
                ),
                FinancialHistoryStatus.failure => CiervoErrorState(
                  title: 'No pudimos cargar historial',
                  description: state.errorMessage ?? 'Intenta nuevamente.',
                  onRetry: context.read<FinancialHistoryCubit>().load,
                ),
                FinancialHistoryStatus.loaded => ListView.separated(
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return CiervoCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.timeline_outlined),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              item.description.isEmpty
                                  ? item.type
                                  : item.description,
                            ),
                          ),
                          Text(
                            '${item.currency} ${item.amount.toStringAsFixed(0)}',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              },
            );
          },
        ),
      ),
    );
  }
}
