// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/country/country_context.dart';
import '../../../../core/experience/experience_mode.dart';
import '../../../../core/experience/experience_mode_cubit.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/location/location_permission_status.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../discovery/presentation/widgets/activity_feed_section.dart';
import '../../../discovery/data/repositories/business_categories_repository.dart';
import '../../../discovery/domain/entities/business_summary.dart';
import '../../../discovery/domain/repositories/discovery_repository.dart';
import '../../../location/data/client_location_repository.dart';
import '../../../place_detail/presentation/pages/place_detail_page.dart';
import '../../domain/entities/home_place.dart';
import '../cubit/home_discovery_cubit.dart';
import '../cubit/home_discovery_state.dart';
import '../widgets/home_category_list.dart';
import '../widgets/home_place_card.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/home_top_bar.dart';
import '../widgets/location_permission_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeDiscoveryCubit(
        locationService: getIt<LocationService>(),
        discoveryRepository: getIt<DiscoveryRepository>(),
        clientLocationRepository: getIt<ClientLocationRepository>(),
        businessCategoriesRepository: getIt<BusinessCategoriesRepository>(),
        initialExperienceMode: context.read<ExperienceModeCubit>().state.mode,
      )..initialize(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExperienceModeCubit, ExperienceModeState>(
      builder: (context, modeState) {
        return BlocBuilder<HomeDiscoveryCubit, HomeDiscoveryState>(
          builder: (context, state) {
            final cubit = context.read<HomeDiscoveryCubit>();
            if (state.experienceMode != modeState.mode) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  cubit.setExperienceMode(modeState.mode);
                }
              });
            }
            final shouldShowPermission =
                state.permissionStatus != AppLocationPermissionStatus.granted;

            return SafeArea(
              child: RefreshIndicator(
                onRefresh: state.usingLocation
                    ? cubit.loadNearby
                    : cubit.loadGeneral,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HomeTopBar(
                              mode: modeState.mode,
                              onChangeMode: () => context.push(
                                AppRoutePaths.experienceMode,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              'Explora Ciervo',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${modeState.mode.label} - ${state.usingLocation ? 'cerca de ti' : '${state.city}, ${state.countryCode}'}',
                              style: AppTextStyles.bodyMuted,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            HomeSearchBar(onSubmitted: cubit.search),
                            const SizedBox(height: AppSpacing.md),
                            _CurrentCountry(countryCode: state.countryCode),
                            if (shouldShowPermission) ...[
                              const SizedBox(height: AppSpacing.lg),
                              LocationPermissionCard(
                                status: state.permissionStatus,
                                onAllow: cubit.requestLocation,
                                onContinueWithoutLocation: cubit.loadGeneral,
                                onOpenSettings: cubit.openAppSettings,
                                onOpenLocationSettings:
                                    cubit.openLocationSettings,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            const ActivityFeedSection(),
                            const SizedBox(height: AppSpacing.lg),
                            HomeCategoryList(
                              categories: cubit.categories,
                              selectedCategory: state.selectedCategory,
                              onCategorySelected: cubit.selectCategory,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      sliver: _DiscoveryResults(
                        state: state,
                        mode: modeState.mode,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CurrentCountry extends StatelessWidget {
  const _CurrentCountry({required this.countryCode});

  final String countryCode;

  @override
  Widget build(BuildContext context) {
    final label = countryCode == CountryContext.chile.countryCode
        ? 'Chile'
        : 'Colombia';
    return Row(
      children: [
        Icon(
          Icons.public_outlined,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'País actual: $label',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _DiscoveryResults extends StatelessWidget {
  const _DiscoveryResults({required this.state, required this.mode});

  final HomeDiscoveryState state;
  final ExperienceMode mode;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      HomeDiscoveryStatus.initial || HomeDiscoveryStatus.loading =>
        const SliverToBoxAdapter(child: CiervoLoadingState(itemCount: 4)),
      HomeDiscoveryStatus.empty => const SliverToBoxAdapter(
        child: CiervoEmptyState(
          title: 'Sin resultados',
          description:
              'No encontramos experiencias para estos filtros. Prueba otra busqueda o categoria.',
          icon: Icons.explore_off_outlined,
        ),
      ),
      HomeDiscoveryStatus.failure => SliverToBoxAdapter(
        child: CiervoErrorState(
          title: 'No pudimos cargar experiencias',
          description: state.errorMessage ?? 'Intenta nuevamente.',
          onRetry: context.read<HomeDiscoveryCubit>().loadGeneral,
        ),
      ),
      HomeDiscoveryStatus.loaded => SliverList.separated(
        itemCount: state.businesses.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final place = _mapBusinessToPlace(
            state.businesses[index],
            city: state.city,
            countryCode: state.countryCode,
          );
          return HomePlaceCard(
            place: place,
            mode: mode,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PlaceDetailPage(place: place),
                ),
              );
            },
          );
        },
      ),
    };
  }

  HomePlace _mapBusinessToPlace(
    BusinessSummary business, {
    required String city,
    required String countryCode,
  }) {
    return HomePlace(
      id: business.id,
      name: business.name,
      category: business.category.isEmpty ? 'Experiencia' : business.category,
      rating: business.rating,
      priceLevel: business.priceLevel,
      distanceKm: business.distanceKm,
      matchPercent: 0,
      imageUrl: business.imageUrl,
      businessCategoryId: business.businessCategoryId,
      isFavorite: business.isFavorite,
      isPartner: business.isPartner,
      hasCashback: business.hasCashback,
      benefitTier: business.benefitTier,
      city: city,
      countryCode: countryCode,
    );
  }
}
