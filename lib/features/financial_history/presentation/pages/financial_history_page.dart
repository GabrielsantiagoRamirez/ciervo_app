import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/layout/ciervo_page_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/repositories/financial_history_repository.dart';
import '../cubit/financial_history_cubit.dart';
import '../cubit/financial_history_state.dart';
import 'financial_movement_detail_page.dart';

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
                FinancialHistoryStatus.loading =>
                  const CiervoLoadingState(),
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
                        const SizedBox(height: CiervoPageLayout.cardGap),
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      final signedAmount = item.isCredit ? item.amount : -item.amount;
                      return InkWell(
                        onTap: () => openFinancialMovementDetail(context, item),
                        borderRadius: BorderRadius.circular(16),
                        child: CiervoCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Icon(
                                item.isCredit
                                    ? Icons.south_west_rounded
                                    : Icons.north_east_rounded,
                                color: item.isCredit
                                    ? Colors.green.shade400
                                    : Colors.red.shade300,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.displayTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item.date != null)
                                      Text(
                                        _formatDate(item.date!),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${signedAmount >= 0 ? '+' : ''}${item.currency} ${signedAmount.abs().toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: item.isCredit
                                          ? Colors.green.shade400
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                    ),
                                  ),
                                  if (item.hasReceipt)
                                    Text(
                                      'Ver recibo',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, size: 20),
                            ],
                          ),
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

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}
