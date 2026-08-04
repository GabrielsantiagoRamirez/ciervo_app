import 'package:flutter/material.dart';

import '../../../../core/experience/experience_mode.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/home_place.dart';
import '../../../favorites/presentation/widgets/favorite_ciervo_button.dart';
import '../../../media/presentation/authenticated_media_image.dart';

class HomePlaceCard extends StatelessWidget {
  const HomePlaceCard({
    required this.place,
    required this.onTap,
    required this.mode,
    this.isFavorite,
    this.showFavoriteToggle = true,
    super.key,
  });

  final HomePlace place;
  final VoidCallback onTap;
  final ExperienceMode mode;
  final bool? isFavorite;
  final bool showFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    const overlayGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x15000000), AppColors.overlayGradientEnd],
    );
    final amenities = _amenityIcons(place).take(4).toList();

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadii.card,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Hero(
            tag: 'place-${place.id}',
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (place.imageUrl.isNotEmpty)
                  AuthenticatedMediaImage(
                    mediaId: place.imageUrl,
                    thumbnail: true,
                    fit: BoxFit.cover,
                    errorWidget: const _PremiumPlaceholder(),
                  )
                else
                  const _PremiumPlaceholder(),
                DecoratedBox(
                  decoration: BoxDecoration(gradient: overlayGradient),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (place.isPartner)
                              const _IconBadge(
                                icon: Icons.handshake_outlined,
                                label: 'Aliado',
                              ),
                            if (place.hasCashback)
                              const _IconBadge(
                                icon: Icons.savings_outlined,
                                label: 'Cashback',
                              ),
                            if (place.hasActivePromotions)
                              const _Badge(
                                label: 'Promo',
                                backgroundColor: AppColors.primary,
                                textColor: Color(0xFF111111),
                              ),
                            if ((place.benefitTier ?? '').isNotEmpty)
                              _Badge(
                                label: place.benefitTier!,
                                backgroundColor: AppColors.primary,
                                textColor: const Color(0xFF111111),
                              ),
                          ],
                        ),
                      ),
                      if (showFavoriteToggle)
                        FavoriteCiervoButton(
                          businessId: place.id,
                          initialValue: isFavorite ?? place.isFavorite,
                          size: 39,
                        )
                      else if (isFavorite ?? place.isFavorite)
                        const _IconBadge(
                          icon: Icons.pets,
                          label: 'Favorito',
                        ),
                      if (place.isOpen != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        _Badge(
                          label: place.isOpen! ? 'Abierto' : 'Cerrado',
                          backgroundColor: place.isOpen!
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFF5D4037),
                          textColor: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: Row(
                    children: [
                      _Badge(
                        label: place.distanceKm > 0
                            ? '${place.distanceKm.toStringAsFixed(1)} km'
                            : 'General',
                        backgroundColor: AppColors.glass,
                        textColor: AppColors.textPrimary,
                      ),
                      if (amenities.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.xs),
                        ...amenities.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _IconBadge(
                              icon: item.icon,
                              label: item.label,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: 36,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x80000000),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            place.name,
                            style: AppTextStyles.title.copyWith(
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            _metaLabel(place),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.label.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _metaLabel(HomePlace place) {
    final parts = [
      if (place.category.isNotEmpty) place.category,
      if (place.rating > 0) place.rating.toStringAsFixed(1),
      if (place.priceLevel.isNotEmpty) place.priceLevel,
    ];
    return parts.join(' · ');
  }
}

class _AmenityIcon {
  const _AmenityIcon(this.icon, this.label);
  final IconData icon;
  final String label;
}

List<_AmenityIcon> _amenityIcons(HomePlace place) {
  return [
    if (place.acceptsCiervoPayments)
      const _AmenityIcon(Icons.payments_outlined, 'Pagos CIERVO'),
    if (place.hasDelivery)
      const _AmenityIcon(Icons.delivery_dining_outlined, 'Delivery'),
    if (place.requiresReservation)
      const _AmenityIcon(Icons.event_available_outlined, 'Reserva'),
    if (place.isFamilyFriendly)
      const _AmenityIcon(Icons.family_restroom_outlined, 'Familias'),
    if (place.isPetFriendly)
      const _AmenityIcon(Icons.pets_outlined, 'Pet friendly'),
    if (place.isAccessible)
      const _AmenityIcon(Icons.accessible_outlined, 'Accesible'),
    if (place.hasParking)
      const _AmenityIcon(Icons.local_parking_outlined, 'Parking'),
    if (place.open24Hours)
      const _AmenityIcon(Icons.schedule_outlined, '24h'),
  ];
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: const BoxDecoration(
        color: AppColors.glass,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: AppColors.primary),
    ),
  );
}

class _PremiumPlaceholder extends StatelessWidget {
  const _PremiumPlaceholder();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surfaceTop, AppColors.backgroundAlt],
      ),
    ),
    child: Center(
      child: Icon(Icons.image_outlined, color: AppColors.primary, size: 42),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadii.chip,
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(color: textColor, fontSize: 12),
      ),
    );
  }
}
