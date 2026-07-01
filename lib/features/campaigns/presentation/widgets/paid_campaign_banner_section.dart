import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/sync/home_feed_refresh.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../bonuses/presentation/pages/bonus_detail_page.dart';
import '../../../home/domain/entities/home_place.dart';
import '../../../media/presentation/authenticated_media_image.dart';
import '../../../place_detail/presentation/pages/place_detail_page.dart';
import '../../domain/entities/paid_campaign.dart';
import '../../domain/repositories/campaigns_repository.dart';

class PaidCampaignBannerSection extends StatefulWidget {
  const PaidCampaignBannerSection({
    this.country,
    this.city,
    this.businessId,
    this.compactTitle,
    super.key,
  });

  final String? country;
  final String? city;
  final String? businessId;
  final String? compactTitle;

  @override
  State<PaidCampaignBannerSection> createState() =>
      _PaidCampaignBannerSectionState();
}

class _PaidCampaignBannerSectionState extends State<PaidCampaignBannerSection> {
  late Future<List<PaidCampaign>> _campaigns;
  final _viewed = <String>{};
  late VoidCallback _onExternalRefresh;

  @override
  void initState() {
    super.initState();
    _campaigns = _load();
    _onExternalRefresh = () => setState(() => _campaigns = _load());
    HomeFeedRefresh.instance.addListener(_onExternalRefresh);
  }

  @override
  void dispose() {
    HomeFeedRefresh.instance.removeListener(_onExternalRefresh);
    super.dispose();
  }

  Future<List<PaidCampaign>> _load() async {
    double? lat;
    double? lng;
    try {
      final location = await getIt<LocationService>().currentLocation();
      lat = location.latitude;
      lng = location.longitude;
    } catch (_) {}

    final result = await getIt<CampaignsRepository>().active(
      CampaignFilters(
        country: widget.country,
        city: widget.city,
        businessId: widget.businessId,
        nearLat: lat,
        nearLng: lng,
        radiusKm: lat == null ? null : 25,
        pageSize: widget.businessId == null ? 8 : 4,
      ),
    );
    final items = result.when(
      success: (value) => value.where((c) => c.isActive).toList(),
      failure: (_) => const <PaidCampaign>[],
    );
    for (final campaign in items) {
      if (_viewed.add(campaign.id)) {
        getIt<CampaignsRepository>().registerView(campaign.id);
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<PaidCampaign>>(
        future: _campaigns,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 120,
              child: CiervoBrandLoader(
                message: 'Cargando campañas',
                compact: true,
              ),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) return const SizedBox.shrink();

          final title = widget.compactTitle ?? 'Campañas destacadas';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 168,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) => _CampaignBanner(
                    campaign: items[index],
                    onTap: () => _open(context, items[index]),
                  ),
                ),
              ),
            ],
          );
        },
      );

  Future<void> _open(BuildContext context, PaidCampaign campaign) async {
    await getIt<CampaignsRepository>().registerClick(campaign.id);
    if (!context.mounted) return;

    if ((campaign.bonusId ?? '').isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BonusDetailPage(bonusId: campaign.bonusId!),
        ),
      );
      return;
    }
    if ((campaign.businessId ?? '').isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlaceDetailPage(
            place: HomePlace(
              id: campaign.businessId!,
              name: campaign.businessName ?? 'Comercio',
              category: 'Experiencia',
              rating: 0,
              priceLevel: '',
              distanceKm: campaign.distanceKm ?? 0,
              matchPercent: 0,
              imageUrl: campaign.imageUrl,
              city: campaign.city,
              countryCode: campaign.country,
            ),
          ),
        ),
      );
    }
  }
}

class _CampaignBanner extends StatelessWidget {
  const _CampaignBanner({required this.campaign, required this.onTap});

  final PaidCampaign campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 280,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: CiervoCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (campaign.imageUrl.isNotEmpty)
                    AuthenticatedMediaImage(
                      mediaId: campaign.imageUrl,
                      thumbnail: true,
                      fit: BoxFit.cover,
                    )
                  else
                    const ColoredBox(color: AppColors.surfaceHigh),
                  ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Patrocinado',
                            style: TextStyle(
                              color: Color(0xFF111111),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          campaign.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        if (campaign.description.isNotEmpty)
                          Text(
                            campaign.description,
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
