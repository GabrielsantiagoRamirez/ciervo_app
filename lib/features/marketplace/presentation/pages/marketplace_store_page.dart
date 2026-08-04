import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../media/presentation/authenticated_media_image.dart';
import '../../domain/entities/marketplace_models.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../widgets/marketplace_promo_card.dart';

class MarketplaceStorePage extends StatefulWidget {
  const MarketplaceStorePage({required this.storeId, super.key});

  final int storeId;

  @override
  State<MarketplaceStorePage> createState() => _MarketplaceStorePageState();
}

class _MarketplaceStorePageState extends State<MarketplaceStorePage> {
  final _repo = getIt<MarketplaceRepository>();
  MarketplaceStore? _store;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.storeProfile(widget.storeId);
    result.when(
      success: (store) => _store = store,
      failure: (error) => _error = UserErrorMessage.from(error),
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CiervoLoadingState(itemCount: 3)),
      );
    }
    if (_error != null || _store == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comercio')),
        body: CiervoErrorState(
          title: 'No pudimos cargar el comercio',
          description: _error ?? 'Intenta de nuevo.',
          onRetry: _load,
        ),
      );
    }

    final store = _store!;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 700 ? 2 : 1;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                store.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: store.coverImage?.isNotEmpty == true
                  ? AuthenticatedMediaImage(
                      mediaId: store.coverImage!,
                      fit: BoxFit.cover,
                    )
                  : const ColoredBox(color: AppColors.surfaceHigh),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (store.ciervoId.isNotEmpty)
                    Text(
                      'CIERVO ID: ${store.ciervoId}',
                      style: AppTextStyles.bodyMuted,
                    ),
                  if (store.category != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(store.category!, style: AppTextStyles.label),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _InfoChip(
                        icon: store.open ? Icons.lock_open : Icons.lock_outline,
                        label: store.open ? 'Abierto' : 'Cerrado',
                      ),
                      if (store.delivery)
                        const _InfoChip(
                          icon: Icons.delivery_dining_outlined,
                          label: 'Delivery',
                        ),
                      if (store.ciervoPay)
                        const _InfoChip(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'CIERVO Pay',
                        ),
                      if (store.cashbackEnabled)
                        const _InfoChip(
                          icon: Icons.savings_outlined,
                          label: 'Cashback',
                        ),
                      if (store.pointsEnabled)
                        const _InfoChip(
                          icon: Icons.stars_outlined,
                          label: 'Puntos',
                        ),
                      if (store.rating != null)
                        _InfoChip(
                          icon: Icons.star_rate_rounded,
                          label: store.rating!.toStringAsFixed(1),
                        ),
                    ],
                  ),
                  if (store.description?.isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(store.description!, style: AppTextStyles.bodyMuted),
                  ],
                  if (store.address?.isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(store.address!, style: AppTextStyles.body),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text('Promociones', style: AppTextStyles.title),
                ],
              ),
            ),
          ),
          if (store.promotions.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CiervoEmptyState(
                  title: 'Sin promociones',
                  description: 'Este comercio aún no tiene ofertas activas.',
                  icon: Icons.local_offer_outlined,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: columns == 1 ? 1.35 : 0.78,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final promo = store.promotions[index];
                  return MarketplacePromoCard(
                    promo: promo,
                    onTap: () =>
                        context.push('/marketplace/promos/${promo.id}'),
                  );
                }, childCount: store.promotions.length),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
