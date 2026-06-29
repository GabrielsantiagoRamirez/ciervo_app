import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/repositories/receipts_repository.dart';
import '../cubit/receipts_cubit.dart';
import '../cubit/receipts_state.dart';

class ReceiptsPage extends StatelessWidget {
  const ReceiptsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReceiptsCubit(getIt<ReceiptsRepository>())..load(),
      child: const _ReceiptsView(),
    );
  }
}

class _ReceiptsView extends StatelessWidget {
  const _ReceiptsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recibos')),
      body: BlocBuilder<ReceiptsCubit, ReceiptsState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: switch (state.status) {
              ReceiptsStatus.initial ||
              ReceiptsStatus.loading => const CiervoLoadingState(),
              ReceiptsStatus.empty => const CiervoEmptyState(
                title: 'Sin recibos',
                description: 'Tus recibos apareceran aqui.',
                icon: Icons.receipt_long_outlined,
              ),
              ReceiptsStatus.failure => CiervoErrorState(
                title: 'No pudimos cargar recibos',
                description: state.errorMessage ?? 'Intenta nuevamente.',
                onRetry: context.read<ReceiptsCubit>().load,
              ),
              ReceiptsStatus.loaded => ListView.separated(
                itemCount: state.receipts.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) =>
                    _ReceiptTile(receipt: state.receipts[index]),
              ),
            },
          );
        },
      ),
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({required this.receipt});
  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptDetailPage(id: receipt.id),
        ),
      ),
      child: CiervoCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_outlined),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                receipt.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text('${receipt.currency} ${receipt.amount.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }
}

class ReceiptDetailPage extends StatelessWidget {
  const ReceiptDetailPage({required this.id, super.key});
  final String id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReceiptsCubit(getIt<ReceiptsRepository>())..loadDetail(id),
      child: Scaffold(
        appBar: AppBar(title: const Text('Detalle de recibo')),
        body: BlocBuilder<ReceiptsCubit, ReceiptsState>(
          builder: (context, state) {
            final receipt = state.selected;
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: state.status == ReceiptsStatus.loading
                  ? const CiervoLoadingState(itemCount: 2)
                  : receipt == null
                  ? const CiervoEmptyState(
                      title: 'Recibo no disponible',
                      description: 'No encontramos el detalle solicitado.',
                    )
                  : CiervoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            receipt.title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            '${receipt.currency} ${receipt.amount.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text('Estado: ${receipt.status}'),
                          if (receipt.userCiervoCode != null)
                            Text('Ciervo ID: ${receipt.userCiervoCode}'),
                          if (receipt.publicReceiptUrl != null)
                            Text('Recibo: ${receipt.publicReceiptUrl}'),
                          if (receipt.description != null)
                            Text(receipt.description!),
                        ],
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}
