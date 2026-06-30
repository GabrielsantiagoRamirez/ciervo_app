import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/experience/experience_mode_cubit.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../discovery/domain/entities/business_summary.dart';
import '../../../discovery/domain/repositories/discovery_repository.dart';
import '../../../discovery/data/repositories/business_categories_repository.dart';
import '../../../home/domain/entities/home_place.dart';
import '../../../home/presentation/cubit/home_discovery_cubit.dart';
import '../../../home/presentation/cubit/home_discovery_state.dart';
import '../../../home/presentation/widgets/home_place_card.dart';
import '../../../location/data/client_location_repository.dart';
import '../../../place_detail/presentation/pages/place_detail_page.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

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
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _controller = TextEditingController();
  String _category = 'Top';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeDiscoveryCubit>();
    final modeState = context.watch<ExperienceModeCubit>().state;
    final discoveryState = context.watch<HomeDiscoveryCubit>().state;
    if (discoveryState.experienceMode != modeState.mode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          cubit.setExperienceMode(modeState.mode);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar')),
      body: CustomScrollView(
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _apply(cubit),
                    decoration: const InputDecoration(
                      hintText: 'Buscar comercios, eventos o promociones',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: cubit.categories.map((category) {
                      return ChoiceChip(
                        label: Text(_label(category)),
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    icon: const Icon(Icons.tune),
                    label: const Text('Aplicar filtros'),
                    onPressed: () => _apply(cubit),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                discoveryState.usingLocation
                    ? 'Mostrando negocios cercanos en ${discoveryState.countryCode}'
                    : 'Mostrando negocios de ${discoveryState.city}, ${discoveryState.countryCode}',
                style: Theme.of(context).textTheme.bodySmall,
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
            sliver: BlocBuilder<HomeDiscoveryCubit, HomeDiscoveryState>(
              builder: (context, state) {
                return switch (state.status) {
                  HomeDiscoveryStatus.initial => const SliverToBoxAdapter(
                      child: CiervoEmptyState(
                        title: 'Busca en Ciervo',
                        description:
                            'Encuentra experiencias por nombre, categoria o ciudad.',
                        icon: Icons.search_rounded,
                      ),
                    ),
                  HomeDiscoveryStatus.loading => const SliverToBoxAdapter(
                      child: CiervoLoadingState(itemCount: 4),
                    ),
                  HomeDiscoveryStatus.empty => SliverToBoxAdapter(
                      child: CiervoEmptyState(
                        title: _category == 'turismo'
                            ? 'Turismo en fase piloto'
                            : 'Sin resultados',
                        description: _category == 'turismo'
                            ? 'Turismo está en fase piloto. Pronto encontrarás más experiencias.'
                            : 'No encontramos coincidencias para tu búsqueda.',
                        icon: _category == 'turismo'
                            ? Icons.travel_explore_outlined
                            : Icons.search_off_rounded,
                      ),
                    ),
                  HomeDiscoveryStatus.failure => SliverToBoxAdapter(
                      child: CiervoErrorState(
                        title: 'No pudimos buscar',
                        description:
                            state.errorMessage ?? 'Intenta nuevamente.',
                      ),
                    ),
                  HomeDiscoveryStatus.loaded => SliverList.separated(
                      itemCount: state.businesses.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final place = _mapBusinessToPlace(
                          state.businesses[index],
                          city: state.city,
                          countryCode: state.countryCode,
                        );
                        return BlocBuilder<ExperienceModeCubit, ExperienceModeState>(
                          builder: (context, modeState) {
                            return HomePlaceCard(
                              place: place,
                              mode: modeState.mode,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => PlaceDetailPage(place: place),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                };
              },
            ),
          ),
        ],
      ),
    );
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

  void _apply(HomeDiscoveryCubit cubit) {
    cubit.search(_controller.text, category: _category);
  }

  String _label(String category) => switch (category) {
        'Top' => 'Todos',
        'bar' => 'Bar',
        'hoteles' => 'Hoteles',
        'restaurantes' => 'Restaurantes',
        'bares' => 'Bares',
        'discotecas' => 'Discotecas',
        'licorerias' => 'Licorerias',
        'farmacias' => 'Farmacias',
        'turismo' => 'Turismo',
        'transporte' => 'Transporte',
        _ => category,
      };
}
