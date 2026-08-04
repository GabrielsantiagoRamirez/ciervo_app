// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/kids/selected_kid_context.dart';
import '../../../../shared/widgets/kids_mode_banner.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/country/country_registration.dart';
import '../../../../core/experience/experience_mode.dart';
import '../../../../core/experience/experience_mode_cubit.dart';
import '../../../../core/geo/geo_repository.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/sync/home_feed_refresh.dart';
import '../../../../core/location/location_permission_status.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../../shared/widgets/staggered_reveal.dart';
import '../../../discovery/presentation/widgets/activity_feed_section.dart';
import '../../../safety/domain/repositories/safety_repository.dart';
import '../../../bonuses/presentation/pages/bonuses_pages.dart';
import '../../../campaigns/presentation/widgets/paid_campaign_banner_section.dart';
import '../../../favorites/presentation/widgets/home_favorites_section.dart';
import '../../../discovery/data/repositories/business_categories_repository.dart';
import '../../../discovery/domain/entities/business_summary.dart';
import '../../../discovery/domain/entities/discovery_smart_filters.dart';
import '../../../discovery/domain/repositories/discovery_repository.dart';
import '../../../location/data/client_location_repository.dart';
import '../../../place_detail/presentation/pages/place_detail_page.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/entities/home_place.dart';
import '../cubit/home_discovery_cubit.dart';
import '../cubit/home_discovery_state.dart';
import '../widgets/home_category_list.dart';
import '../widgets/home_place_card.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/home_services_grid.dart';
import '../widgets/home_top_bar.dart';
import '../widgets/location_permission_card.dart';
import '../widgets/smart_filters_sheet.dart';
import '../../../promotions/presentation/widgets/gold_trial_promotion_sheet.dart';
import '../../../memberships/presentation/widgets/membership_renewal_reminder.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final _viewKey = GlobalKey<_HomeViewState>();

  void scrollToTopAndRefresh() =>
      _viewKey.currentState?.scrollToTopAndRefresh();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeDiscoveryCubit(
        locationService: getIt<LocationService>(),
        discoveryRepository: getIt<DiscoveryRepository>(),
        clientLocationRepository: getIt<ClientLocationRepository>(),
        businessCategoriesRepository: getIt<BusinessCategoriesRepository>(),
        geoRepository: getIt<GeoRepository>(),
        profileRepository: getIt<ProfileRepository>(),
        initialExperienceMode: context.read<ExperienceModeCubit>().state.mode,
      )..initialize(),
      child: _HomeView(key: _viewKey),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView({super.key});

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> with WidgetsBindingObserver {
  late final SelectedKidContext _kidContext;
  Timer? _autoRefreshTimer;
  final _scrollController = ScrollController();
  final _searchSectionKey = GlobalKey();
  bool _appResumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getIt<SafetyRepository>().refreshLocalFilters();
    _kidContext = getIt<SelectedKidContext>();
    _kidContext.addListener(_onKidModeChanged);
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      if (!_appResumed || !mounted) return;
      _refreshFeedSections();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showGoldTrialPromotionIfEligible(context);
      if (!mounted) return;
      await showMembershipRenewalReminderIfNeeded(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _kidContext.removeListener(_onKidModeChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
  }

  void _focusCommerceSearch() {
    final ctx = _searchSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    } else if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Busca un comercio arriba o elige uno de la lista.'),
      ),
    );
  }

  void scrollToTopAndRefresh() {
    if (!mounted) return;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
    _refreshFeedSections();
  }

  void _refreshFeedSections() {
    if (!mounted) return;
    HomeFeedRefresh.instance.refreshAll();
    final cubit = context.read<HomeDiscoveryCubit>();
    final state = cubit.state;
    if (state.usingLocation) {
      cubit.loadNearby();
    } else {
      cubit.loadGeneral();
    }
  }

  Future<void> _onPullRefresh(
    HomeDiscoveryCubit cubit,
    bool usingLocation,
  ) async {
    HomeFeedRefresh.instance.refreshAll();
    if (usingLocation) {
      await cubit.loadNearby();
    } else {
      await cubit.loadGeneral();
    }
  }

  void _onKidModeChanged() {
    if (!mounted) return;
    setState(() {});
    final cubit = context.read<HomeDiscoveryCubit>();
    if (cubit.state.permissionStatus == AppLocationPermissionStatus.granted) {
      cubit.loadNearby();
    } else {
      cubit.loadGeneral();
    }
  }

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

            return Column(
              children: [
                KidsModeBanner(
                  kidContext: _kidContext,
                  onExit: _kidContext.clear,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _onPullRefresh(cubit, state.usingLocation),
                    child: CustomScrollView(
                      controller: _scrollController,
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
                                  activeFilterCount: state.filters.activeCount,
                                  onModeChanged: (mode) {
                                    context.read<ExperienceModeCubit>().setMode(
                                      mode,
                                    );
                                  },
                                  onOpenFilters: () async {
                                    final applied = await showSmartFiltersSheet(
                                      context: context,
                                      initial: state.filters,
                                    );
                                    if (applied != null && context.mounted) {
                                      await cubit.applyFilters(applied);
                                    }
                                  },
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                Text(
                                  'Explora Ciervo',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${modeState.mode.label} · ${state.usingLocation ? 'cerca de ti' : '${state.city}, ${state.countryCode}'}',
                                  style: AppTextStyles.bodyMuted,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                KeyedSubtree(
                                  key: _searchSectionKey,
                                  child: const HomeSearchBar(),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _CurrentCountry(countryCode: state.countryCode),
                                const SizedBox(height: AppSpacing.md),
                                CiervoButton(
                                  label: 'Tickets y eventos',
                                  icon: Icons.confirmation_number_outlined,
                                  onPressed: () => context.push('/tickets'),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                CiervoButton(
                                  label: 'Marketplace',
                                  icon: Icons.storefront_outlined,
                                  variant: CiervoButtonVariant.secondary,
                                  onPressed: () => context.push('/marketplace'),
                                ),
                                if (shouldShowPermission) ...[
                                  const SizedBox(height: AppSpacing.lg),
                                  LocationPermissionCard(
                                    status: state.permissionStatus,
                                    onAllow: cubit.requestLocation,
                                    onContinueWithoutLocation:
                                        cubit.loadGeneral,
                                    onOpenSettings: cubit.openAppSettings,
                                    onOpenLocationSettings:
                                        cubit.openLocationSettings,
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.lg),
                                HomeCategoryList(
                                  categories: cubit.categories,
                                  selectedCategory: state.selectedCategory,
                                  onCategorySelected: cubit.selectCategory,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.xl,
                          ),
                          sliver: _DiscoveryResults(
                            state: state,
                            mode: modeState.mode,
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.xxl,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const ActivityFeedSection(),
                                const SizedBox(height: AppSpacing.lg),
                                PaidCampaignBannerSection(
                                  country: state.countryCode,
                                  city: state.city,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                HomeFavoritesSection(
                                  country: state.countryCode,
                                  city: state.city,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                HomeServicesGrid(
                                  onFindCommerce: _focusCommerceSearch,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                HomeBonusesSection(
                                  title: 'Bonos cerca de ti',
                                  onlyFavorites: false,
                                  country: state.countryCode,
                                  city: state.city,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                HomeBonusesSection(
                                  title: 'Bonos de tus favoritos',
                                  onlyFavorites: true,
                                  country: state.countryCode,
                                  city: state.city,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
    final label = CountryRegistration.countryLabel(countryCode);
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
      HomeDiscoveryStatus.empty => SliverToBoxAdapter(
        child: _DiscoveryEmptyState(state: state),
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
          return StaggeredReveal(
            index: index,
            baseDelay: const Duration(milliseconds: 45),
            child: HomePlaceCard(
              place: place,
              mode: mode,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PlaceDetailPage(place: place),
                  ),
                );
              },
            ),
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
      name: business.name.isNotEmpty ? business.name : 'Negocio',
      category: business.category.isEmpty ? 'General' : business.category,
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
      experienceBucket: business.experienceBucket,
      open24Hours: business.open24Hours,
      acceptsCiervoPayments: business.acceptsCiervoPayments,
      hasDelivery: business.hasDelivery,
      requiresReservation: business.requiresReservation,
      isFamilyFriendly: business.isFamilyFriendly,
      isPetFriendly: business.isPetFriendly,
      isAccessible: business.isAccessible,
      hasParking: business.hasParking,
      hasActivePromotions: business.hasActivePromotions,
      isOpen: business.isOpen,
    );
  }
}

class _DiscoveryEmptyState extends StatelessWidget {
  const _DiscoveryEmptyState({required this.state});

  final HomeDiscoveryState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeDiscoveryCubit>();
    final show24h = state.experienceMode != ExperienceMode.allDay;

    return Column(
      children: [
        CiervoEmptyState(
          title: 'Sin resultados',
          description: state.filters.hasActiveFilters
              ? 'Ningún comercio cumple todos los filtros activos. Desactiva algunos o limpia la búsqueda.'
              : show24h
              ? 'No hay experiencias en esta franja. Prueba ver comercios 24h o ampliar el radio.'
              : 'No encontramos experiencias cerca. Prueba ampliar el radio de búsqueda.',
          icon: Icons.explore_off_outlined,
          actionLabel: state.filters.hasActiveFilters
              ? 'Limpiar filtros'
              : show24h
              ? 'Ver 24h'
              : 'Ampliar radio',
          onAction: () async {
            if (state.filters.hasActiveFilters) {
              await cubit.applyFilters(const DiscoverySmartFilters());
              return;
            }
            if (show24h) {
              await context.read<ExperienceModeCubit>().setMode(
                ExperienceMode.allDay,
              );
              return;
            }
            await cubit.expandRadius();
          },
        ),
        if (!state.filters.hasActiveFilters && show24h) ...[
          const SizedBox(height: AppSpacing.sm),
          CiervoButton(
            label: 'Ampliar radio',
            icon: Icons.radar_outlined,
            onPressed: cubit.expandRadius,
          ),
        ],
      ],
    );
  }
}
