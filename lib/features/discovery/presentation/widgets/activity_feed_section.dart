// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../bonuses/presentation/pages/bonus_detail_page.dart';
import '../../../home/domain/entities/home_place.dart';
import '../../../media/presentation/authenticated_media_image.dart';
import '../../../place_detail/presentation/pages/place_detail_page.dart';
import '../../data/repositories/activity_feed_repository.dart';
import '../../domain/entities/activity_feed_item.dart';

class ActivityFeedSection extends StatefulWidget {
  const ActivityFeedSection({super.key});

  @override
  State<ActivityFeedSection> createState() => _ActivityFeedSectionState();
}

class _ActivityFeedSectionState extends State<ActivityFeedSection> {
  late Future<List<ActivityFeedItem>> _items;

  @override
  void initState() {
    super.initState();
    _items = _load();
  }

  Future<List<ActivityFeedItem>> _load() async {
    final result = await getIt<ActivityFeedRepository>().feed();
    return result.when(
      success: (value) => value,
      failure: (error) => throw error,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ActivityFeedItem>>(
    future: _items,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox(
          height: 132,
          child: CiervoBrandLoader(
            message: 'Buscando novedades',
            compact: true,
          ),
        );
      }
      if (snapshot.hasError) {
        return CiervoCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(UserErrorMessage.from(snapshot.error!)),
        );
      }
      final items = snapshot.data ?? const [];
      if (items.isEmpty) {
        return const CiervoCard(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text('Sin novedades por ahora.'),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Novedades para ti',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) => _ActivityCard(item: items[index]),
            ),
          ),
        ],
      );
    },
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});

  final ActivityFeedItem item;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 260,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openActivity(context, item),
      child: CiervoCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if ((item.imageMediaId ?? '').isNotEmpty)
                AuthenticatedMediaImage(
                  mediaId: item.imageMediaId!,
                  thumbnail: true,
                  fit: BoxFit.cover,
                ),
              ColoredBox(color: Colors.black.withValues(alpha: 0.42)),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Chip(
                      label: Text(item.category ?? item.type),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    if (item.description.isNotEmpty)
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _openActivity(BuildContext context, ActivityFeedItem item) {
  final type = item.type.toLowerCase();
  if ((item.bonusId ?? '').isNotEmpty ||
      type.contains('bonus') ||
      type.contains('coupon')) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BonusDetailPage(bonusId: item.bonusId!),
      ),
    );
    return;
  }
  if (type.contains('ads_campaign') ||
      type.contains('campaign_published') ||
      type.contains('campaign')) {
    if (item.businessId != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlaceDetailPage(place: _placeFromActivity(item)),
        ),
      );
      return;
    }
  }
  if (item.businessId != null) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaceDetailPage(place: _placeFromActivity(item)),
      ),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _ActivityDetailPage(item: item),
    ),
  );
}

HomePlace _placeFromActivity(ActivityFeedItem item) => HomePlace(
      id: '${item.businessId}',
      name: item.title,
      category: item.category ?? 'Experiencia',
      rating: 0,
      priceLevel: '',
      distanceKm: 0,
      matchPercent: 0,
      imageUrl: item.imageMediaId ?? '',
      city: 'Bogota',
      countryCode: 'CO',
    );

class _ActivityDetailPage extends StatelessWidget {
  const _ActivityDetailPage({required this.item});

  final ActivityFeedItem item;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Novedad')),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        CiervoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(item.description),
              const SizedBox(height: AppSpacing.md),
              _line('Tipo', item.type),
              _line('Categoría', item.category),
              _line('Ruta interna', item.deepLink),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _line(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text('$label: $value'),
    );
  }
}
