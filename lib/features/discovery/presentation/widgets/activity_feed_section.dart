// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/sync/home_feed_refresh.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../bonuses/presentation/pages/bonus_detail_page.dart';
import '../../../favorites/presentation/widgets/favorite_ciervo_button.dart';
import '../../../home/domain/entities/home_place.dart';
import '../../../media/presentation/authenticated_media_image.dart';
import '../../../place_detail/presentation/pages/place_detail_page.dart';
import '../../data/repositories/activity_feed_repository.dart';
import '../../domain/entities/activity_feed_item.dart';
import '../../../safety/data/models/safety_models.dart';
import '../../../safety/data/services/safety_filter_cache.dart';
import '../../../safety/presentation/widgets/safety_sheets.dart';

class ActivityFeedSection extends StatefulWidget {
  const ActivityFeedSection({super.key});

  @override
  State<ActivityFeedSection> createState() => _ActivityFeedSectionState();
}

class _ActivityFeedSectionState extends State<ActivityFeedSection> {
  late Future<List<ActivityFeedItem>> _items;
  late VoidCallback _onExternalRefresh;

  @override
  void initState() {
    super.initState();
    _items = _load();
    _onExternalRefresh = () => setState(() => _items = _load());
    HomeFeedRefresh.instance.addListener(_onExternalRefresh);
  }

  @override
  void dispose() {
    HomeFeedRefresh.instance.removeListener(_onExternalRefresh);
    super.dispose();
  }

  Future<List<ActivityFeedItem>> _load() async {
    final result = await getIt<ActivityFeedRepository>().feed();
    return result.when(
      success: (value) {
        final cache = getIt<SafetyFilterCache>();
        return value.where((item) => !_isBlocked(cache, item)).toList();
      },
      failure: (error) => throw error,
    );
  }

  bool _isBlocked(SafetyFilterCache cache, ActivityFeedItem item) {
    if (item.businessId != null &&
        cache.isContentBlocked(
          ReportTargetType.business,
          '${item.businessId}',
        )) {
      return true;
    }
    if (item.eventId != null &&
        cache.isContentBlocked(ReportTargetType.event, '${item.eventId}')) {
      return true;
    }
    if (item.productId != null &&
        cache.isContentBlocked(ReportTargetType.post, '${item.productId}')) {
      return true;
    }
    if (item.promotionId != null &&
        cache.isContentBlocked(
          ReportTargetType.promotion,
          '${item.promotionId}',
        )) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ActivityFeedItem>>(
    future: _items,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox.shrink();
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
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) =>
                  _ActivityCard(item: items[index]),
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

  ReportTargetType? _targetType(ActivityFeedItem item) {
    if (item.promotionId != null) return ReportTargetType.promotion;
    if (item.eventId != null) return ReportTargetType.event;
    if (item.productId != null) return ReportTargetType.post;
    if (item.businessId != null) return ReportTargetType.business;
    return null;
  }

  String? _targetId(ActivityFeedItem item) {
    if (item.promotionId != null) return '${item.promotionId}';
    if (item.eventId != null) return '${item.eventId}';
    if (item.productId != null) return '${item.productId}';
    if (item.businessId != null) return '${item.businessId}';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cashback = item.cashbackDisplay;
    final points = item.pointsDisplay;
    final price = item.price;

    return SizedBox(
      width: 250,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openActivity(context, item),
        onLongPress: () {
          final type = _targetType(item);
          final id = _targetId(item);
          if (type == null || id == null) return;
          showSafetyOptionsSheet(
            context,
            title: item.title,
            contentType: type,
            contentId: id,
            onActionCompleted: () {
              HomeFeedRefresh.instance.refreshAll();
            },
          );
        },
        child: CiervoCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.hasNetworkImage)
                  Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _FeedCardBackdrop(),
                  )
                else if ((item.imageMediaId ?? '').isNotEmpty)
                  AuthenticatedMediaImage(
                    mediaId: item.imageMediaId!,
                    thumbnail: true,
                    fit: BoxFit.cover,
                    errorWidget: const _FeedCardBackdrop(),
                  )
                else
                  const _FeedCardBackdrop(),
                if (item.hasNetworkImage ||
                    (item.imageMediaId ?? '').isNotEmpty)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x33000000), Color(0xCC000000)],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              alignment: WrapAlignment.center,
                              children: [
                                _MiniChip(label: item.category ?? item.type),
                                if (cashback != null)
                                  _MiniChip(label: cashback, highlight: true),
                                if (points != null)
                                  _MiniChip(label: points, highlight: true),
                              ],
                            ),
                          ),
                          if (item.businessId != null)
                            FavoriteCiervoButton(
                              businessId: '${item.businessId}',
                              initialValue: item.isFavoriteBusiness,
                              size: 40,
                            ),
                        ],
                      ),
                      const Spacer(),
                      if (item.businessName?.isNotEmpty == true)
                        Text(
                          item.businessName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (price != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          DisplayFormatters.formatMoney(
                            price,
                            currency: item.currency,
                          ),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.primary),
                        ),
                      ] else if (item.description.isNotEmpty)
                        Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
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
}

/// Fondo de marca sin placeholder gris ni ícono vacío en el centro.
class _FeedCardBackdrop extends StatelessWidget {
  const _FeedCardBackdrop();

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

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, this.highlight = false});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.92)
            : Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlight ? AppColors.dayText : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

void _openActivity(BuildContext context, ActivityFeedItem item) {
  if (item.promotionId != null) {
    context.push('/marketplace/promos/${item.promotionId}');
    return;
  }

  final deepLink = item.deepLink?.trim() ?? '';
  final promoFromLink = RegExp(
    r'^/?promotions?/(\d+)/?$',
    caseSensitive: false,
  ).firstMatch(deepLink);
  if (promoFromLink != null) {
    context.push('/marketplace/promos/${promoFromLink.group(1)}');
    return;
  }

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
  if (item.businessId != null) {
    if (type.contains('product') ||
        type.contains('promo') ||
        type.contains('marketplace') ||
        type.contains('new_promotion') ||
        type.contains('new_product')) {
      context.push('/marketplace/stores/${item.businessId}');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaceDetailPage(place: _placeFromActivity(item)),
      ),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => _ActivityDetailPage(item: item)),
  );
}

HomePlace _placeFromActivity(ActivityFeedItem item) => HomePlace(
  id: '${item.businessId}',
  name: item.businessName?.isNotEmpty == true ? item.businessName! : item.title,
  category: item.category ?? 'Experiencia',
  rating: 0,
  priceLevel: '',
  distanceKm: 0,
  matchPercent: 0,
  imageUrl: item.imageUrl ?? item.imageMediaId ?? '',
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
              _line('Cashback', item.cashbackDisplay),
              _line('Puntos', item.pointsDisplay),
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
