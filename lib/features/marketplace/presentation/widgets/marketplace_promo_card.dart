import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../media/presentation/authenticated_media_image.dart';
import '../../domain/entities/marketplace_models.dart';

class MarketplacePromoCard extends StatelessWidget {
  const MarketplacePromoCard({
    required this.promo,
    required this.onTap,
    this.onFavorite,
    this.horizontal = false,
    super.key,
  });

  final MarketplacePromo promo;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return SizedBox(
        width: 220,
        child: _CardBody(
          promo: promo,
          onTap: onTap,
          onFavorite: onFavorite,
          compact: true,
        ),
      );
    }
    return _CardBody(
      promo: promo,
      onTap: onTap,
      onFavorite: onFavorite,
      compact: false,
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.promo,
    required this.onTap,
    required this.compact,
    this.onFavorite,
  });

  final MarketplacePromo promo;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final price = promo.offerPrice ?? promo.price;
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: AppRadii.card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (promo.imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: compact ? 16 / 10 : 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AuthenticatedMediaImage(
                      mediaId: promo.imageUrl,
                      thumbnail: true,
                      fit: BoxFit.cover,
                      errorWidget: const _PromoImageFallback(),
                    ),
                    Positioned(
                      top: AppSpacing.xs,
                      left: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (promo.hasCashback || promo.cashbackAmount != null)
                            const _Chip(label: 'Cashback'),
                          if (promo.pointsEnabled || promo.points > 0)
                            const _Chip(label: 'Puntos'),
                          if (promo.reservationEnabled)
                            const _Chip(label: 'Reserva'),
                          if (promo.hasDelivery) const _Chip(label: 'Delivery'),
                        ],
                      ),
                    ),
                    if (onFavorite != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          onPressed: onFavorite,
                          icon: Icon(
                            promo.isFavorite ? Icons.pets : Icons.pets_outlined,
                            size: 18,
                            color: promo.isFavorite
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  0,
                ),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (promo.hasCashback || promo.cashbackAmount != null)
                      const _Chip(label: 'Cashback'),
                    if (promo.pointsEnabled || promo.points > 0)
                      const _Chip(label: 'Puntos'),
                    if (promo.reservationEnabled) const _Chip(label: 'Reserva'),
                    if (promo.hasDelivery) const _Chip(label: 'Delivery'),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    promo.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    promo.businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (price != null)
                        Flexible(
                          child: Text(
                            DisplayFormatters.formatMoney(
                              price,
                              currency: promo.currency,
                            ),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      if (promo.discountPercent != null &&
                          promo.discountPercent! > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '-${promo.discountPercent!.toStringAsFixed(0)}%',
                          style: AppTextStyles.bodyMuted.copyWith(
                            color: AppColors.success,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMuted.copyWith(
          fontSize: 10,
          color: AppColors.primaryHigh,
        ),
      ),
    );
  }
}

class _PromoImageFallback extends StatelessWidget {
  const _PromoImageFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1712), Color(0xFF0D0D0D)],
        ),
      ),
    );
  }
}
