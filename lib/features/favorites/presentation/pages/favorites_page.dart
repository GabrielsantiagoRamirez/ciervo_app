import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/experience/experience_mode_cubit.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../home/domain/entities/home_place.dart';
import '../../../home/presentation/widgets/home_place_card.dart';
import '../../../place_detail/presentation/pages/place_detail_page.dart';
import '../../data/favorites_repository.dart';
import '../../domain/entities/favorite_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _scrollController = ScrollController();
  final _items = <FavoriteBusiness>[];
  var _page = 1;
  var _loading = true;
  var _loadingMore = false;
  var _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_maybeLoadMore)
      ..dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_hasMore || _loading || _loadingMore) return;
    if (_scrollController.position.extentAfter < 420) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _page = 1;
        _hasMore = true;
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    final result = await getIt<FavoritesRepository>().favorites(page: _page);
    if (!mounted) return;
    result.when(
      success: (items) {
        setState(() {
          if (reset) _items.clear();
          _items.addAll(_dedupe(items));
          _hasMore = items.length >= 30;
          _page += 1;
          _loading = false;
          _loadingMore = false;
        });
      },
      failure: (error) {
        setState(() {
          _error = UserErrorMessage.from(error);
          _loading = false;
          _loadingMore = false;
        });
      },
    );
  }

  List<FavoriteBusiness> _dedupe(List<FavoriteBusiness> incoming) {
    final existing = _items.map((item) => item.id).toSet();
    return incoming.where((item) => existing.add(item.id)).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mis favoritos')),
        body: RefreshIndicator(
          onRefresh: () => _load(reset: true),
          child: _body(),
        ),
      );

  Widget _body() {
    if (_loading) return const CiervoLoadingState(itemCount: 4);
    if (_error != null && _items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          CiervoErrorState(
            title: 'No pudimos cargar tus favoritos',
            description: _error!,
            onRetry: () => _load(reset: true),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          CiervoEmptyState(
            title: 'Sin favoritos',
            description: 'Guarda comercios para encontrarlos rapido despues.',
            icon: Icons.favorite_border,
          ),
        ],
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _items.length + (_loadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final place = _placeFrom(_items[index]);
        return HomePlaceCard(
          place: place,
          mode: context.watch<ExperienceModeCubit>().state.mode,
          isFavorite: true,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlaceDetailPage(place: place),
              ),
            );
            if (mounted) _load(reset: true);
          },
        );
      },
    );
  }

  HomePlace _placeFrom(FavoriteBusiness favorite) => HomePlace(
        id: favorite.id,
        name: favorite.name,
        category: favorite.category,
        rating: favorite.rating,
        priceLevel: favorite.priceLevel,
        distanceKm: favorite.distanceKm,
        matchPercent: 0,
        imageUrl: favorite.imageUrl,
        businessCategoryId: favorite.businessCategoryId,
      );
}
