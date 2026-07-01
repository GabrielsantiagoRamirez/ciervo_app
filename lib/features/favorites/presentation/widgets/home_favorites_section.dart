import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/experience/experience_mode_cubit.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/sync/home_feed_refresh.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../../home/domain/entities/home_place.dart';
import '../../../home/presentation/widgets/home_place_card.dart';
import '../../../place_detail/presentation/pages/place_detail_page.dart';
import '../../domain/entities/favorite_business.dart';
import '../../domain/entities/favorite_filters.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../pages/favorites_page.dart';
import 'favorite_counts_badge.dart';

class HomeFavoritesSection extends StatefulWidget {
  const HomeFavoritesSection({
    this.country,
    this.city,
    super.key,
  });

  final String? country;
  final String? city;

  @override
  State<HomeFavoritesSection> createState() => _HomeFavoritesSectionState();
}

class _HomeFavoritesSectionState extends State<HomeFavoritesSection> {
  late Future<_FavoritesPreview> _preview;
  late VoidCallback _onExternalRefresh;

  @override
  void initState() {
    super.initState();
    _preview = _load();
    _onExternalRefresh = () => setState(() => _preview = _load());
    HomeFeedRefresh.instance.addListener(_onExternalRefresh);
  }

  @override
  void dispose() {
    HomeFeedRefresh.instance.removeListener(_onExternalRefresh);
    super.dispose();
  }

  Future<_FavoritesPreview> _load() async {
    double? lat;
    double? lng;
    try {
      final location = await getIt<LocationService>().currentLocation();
      lat = location.latitude;
      lng = location.longitude;
    } catch (_) {}

    final result = await getIt<FavoritesRepository>().list(
      FavoriteFilters(
        country: widget.country,
        city: widget.city,
        nearLat: lat,
        nearLng: lng,
        radiusKm: lat == null ? null : 25,
        sortBy: FavoriteSortBy.recent,
        pageSize: 6,
      ),
    );
    return result.when(
      success: (items) => _FavoritesPreview(items),
      failure: (_) => const _FavoritesPreview([]),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_FavoritesPreview>(
        future: _preview,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 120,
              child: CiervoBrandLoader(
                message: 'Cargando favoritos',
                compact: true,
              ),
            );
          }
          final items = snapshot.data?.items ?? const [];
          if (items.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tus favoritos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const FavoritesPage(),
                      ),
                    ),
                    child: const Text('Ver todos'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final favorite = items[index];
                    final place = HomePlace(
                      id: favorite.businessId,
                      name: favorite.name,
                      category: favorite.category,
                      rating: favorite.rating,
                      priceLevel: favorite.priceLevel,
                      distanceKm: favorite.distanceKm,
                      matchPercent: 0,
                      imageUrl: favorite.imageUrl,
                      businessCategoryId: favorite.businessCategoryId,
                      isFavorite: true,
                      city: favorite.city,
                      countryCode: favorite.country,
                    );
                    return SizedBox(
                      width: 280,
                      child: Stack(
                        children: [
                          HomePlaceCard(
                            place: place,
                            mode: context.watch<ExperienceModeCubit>().state.mode,
                            isFavorite: true,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PlaceDetailPage(place: place),
                              ),
                            ),
                          ),
                          Positioned(
                            right: AppSpacing.sm,
                            bottom: 48,
                            child: FavoriteCountsBadge(
                              bonuses: favorite.activeBonusesCount,
                              campaigns: favorite.activeCampaignsCount,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
}

class _FavoritesPreview {
  const _FavoritesPreview(this.items);
  final List<FavoriteBusiness> items;
}
