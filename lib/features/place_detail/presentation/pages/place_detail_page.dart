import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/experience/experience_mode.dart';
import '../../../../core/experience/experience_mode_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_component_styles.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/ciervo_business_share_link.dart';
import '../../../../core/utils/ciervo_share.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_chip_tag.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../../home/domain/entities/home_place.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../chat/presentation/pages/chat_conversation_page.dart';
import '../../../bonuses/presentation/pages/bonus_detail_page.dart';
import '../../../campaigns/presentation/widgets/paid_campaign_banner_section.dart';
import '../../../favorites/presentation/widgets/favorite_ciervo_button.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/country/country_registration.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/result/result.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../data/business_detail_repository.dart';
import '../../data/review_repository.dart';
import '../../domain/entities/place_detail.dart';
import '../../../location/data/client_location_repository.dart';
import '../../../kids/domain/entities/child_profile.dart';
import '../../../kids/domain/repositories/kids_repository.dart';
import '../../../master_kids/data/repositories/master_kids_repository.dart';
import '../../../master_kids/domain/models/master_kids_models.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../widgets/place_detail_location_card.dart';
import '../widgets/place_detail_promotion_card.dart';
import '../widgets/place_detail_review_tile.dart';
import '../../../media/presentation/authenticated_media_image.dart';
import '../../../product_categories/presentation/widgets/product_subcategory_filters.dart';
import '../../../reservations/presentation/widgets/business_reservation_sheet.dart';
import '../../../delivery/presentation/pages/order_checkout_page.dart';
import '../../../delivery/domain/entities/delivery_models.dart';
import '../../../../shared/widgets/ciervo_image_viewer_page.dart';

class PlaceDetailPage extends StatefulWidget {
  const PlaceDetailPage({required this.place, super.key});

  final HomePlace place;

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  List<BusinessProduct> _products = const [];
  List<ReservableOption> _reservableOptions = const [];
  BusinessPublicDetail? _publicDetail;
  DeliveryAvailability? _deliveryAvailability;
  AppLocation? _location;
  String? _userCiervoCode;
  List<PlaceReview> _reviews = const [];
  double? _ratingAverage;
  int? _reviewsCount;
  bool _hasReviewed = false;
  int? _userReviewId;
  bool _loadingCapabilities = true;
  List<ChildProfile> _children = const [];
  bool _associatingKid = false;

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final result = await getIt<KidsRepository>().children();
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _children = items.where((child) => child.isActive).toList();
      }),
      failure: (_) {},
    );
  }

  bool _loadFailed = false;
  String? _loadErrorMessage;

  Future<void> _loadCapabilities() async {
    final profileResult = await getIt<ProfileRepository>().getMe();
    final profileCountry = profileResult.when(
      success: (p) => (p.countryCode ?? '').trim().toUpperCase(),
      failure: (_) => '',
    );
    final profileCity = profileResult.when(
      success: (p) => (p.city ?? '').trim(),
      failure: (_) => '',
    );

    final placeCountry = (widget.place.countryCode ?? '').trim().toUpperCase();
    final placeCity = (widget.place.city ?? '').trim();
    final countryCode = placeCountry.isNotEmpty
        ? placeCountry
        : (profileCountry.isNotEmpty ? profileCountry : '');
    final city = placeCity.isNotEmpty
        ? placeCity
        : (profileCity.isNotEmpty
              ? profileCity
              : (countryCode.isNotEmpty
                    ? CountryRegistration.contextForCode(countryCode).city
                    : ''));

    Result<AppLocation?> locationResult;
    if (city.isNotEmpty && countryCode.isNotEmpty) {
      locationResult = await getIt<ClientLocationRepository>()
          .syncForRecommendations(city: city, countryCode: countryCode);
    } else {
      locationResult = const Success(null);
    }
    final location = locationResult.when(
      success: (value) => value,
      failure: (_) => null,
    );
    final repository = getIt<BusinessDetailRepository>();
    final detailResult = await repository.publicDetail(
      widget.place.id,
      location: location,
    );
    final availabilityResult = await repository.deliveryAvailability(
      widget.place.id,
      location: location,
    );
    if (!mounted) return;
    setState(() {
      _location = location;
      detailResult.when(
        success: (detail) {
          _publicDetail = detail;
          _loadFailed = false;
          _products = detail.products;
          _reservableOptions = detail.reservableOptions;
          _userCiervoCode = detail.userCiervoCode;
          _reviews = detail.reviews;
          _ratingAverage = detail.ratingAverage;
          _reviewsCount = detail.reviewsCount;
          _hasReviewed = detail.hasReviewed;
          _userReviewId = detail.userReviewId;
        },
        failure: (error) {
          _loadFailed = true;
          _loadErrorMessage = UserErrorMessage.from(error);
        },
      );
      availabilityResult.when(
        success: (availability) => _deliveryAvailability = availability,
        failure: (_) => _deliveryAvailability = null,
      );
      _loadingCapabilities = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    if (_loadingCapabilities) {
      return const Scaffold(
        body: CiervoBrandLoader(message: 'Cargando negocio'),
      );
    }
    if (_loadFailed || _publicDetail == null) {
      final previewImage = place.imageUrl.trim();
      return Scaffold(
        appBar: AppBar(title: Text(place.name)),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (previewImage.isNotEmpty) ...[
              GestureDetector(
                onTap: () =>
                    openCiervoImageViewer(context, images: [previewImage]),
                child: ClipRRect(
                  borderRadius: AppRadii.card,
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AuthenticatedMediaImage(
                          mediaId: previewImage,
                          fit: BoxFit.cover,
                          errorWidget: const ColoredBox(
                            color: AppColors.surfaceTop,
                          ),
                        ),
                        const Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.sm),
                            child: Icon(
                              Icons.zoom_out_map_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            CiervoErrorState(
              title: 'No pudimos cargar el comercio',
              description:
                  _loadErrorMessage ??
                  'Verifica tu conexion e intenta nuevamente.',
              onRetry: () {
                setState(() {
                  _loadingCapabilities = true;
                  _loadErrorMessage = null;
                });
                _loadCapabilities();
              },
            ),
          ],
        ),
      );
    }
    final detail = _detailFromPublic()!;
    final isDay =
        context.watch<ExperienceModeCubit>().state.mode == ExperienceMode.day;
    final subtitle = isDay
        ? 'Ideal para una experiencia premium durante el dia.'
        : 'Perfecto para una noche social premium.';
    final businessCategoryId =
        place.businessCategoryId ?? _businessCategoryIdFrom(place.category);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _HeroSection(detail: detail, showBack: false),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    _TagsRow(tags: detail.tags),
                    const SizedBox(height: AppSpacing.md),
                    Text(detail.name, style: AppTextStyles.headline),
                    const SizedBox(height: AppSpacing.xs),
                    _MetaRow(
                      detail: detail,
                      ratingAverage: _ratingAverage,
                      reviewsCount: _reviewsCount,
                    ),
                    if (_userCiervoCode != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Chip(
                          avatar: const Icon(
                            Icons.verified_user_outlined,
                            size: 18,
                          ),
                          label: Text('Ciervo ID: $_userCiervoCode'),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle, style: AppTextStyles.bodyMuted),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionTitle('Descripcion'),
                    const SizedBox(height: AppSpacing.xs),
                    Text(detail.description, style: AppTextStyles.body),
                    if (businessCategoryId != null)
                      ProductSubcategoryFilters(
                        businessCategoryId: businessCategoryId,
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    PlaceDetailBonusesSection(businessId: place.id),
                    const SizedBox(height: AppSpacing.lg),
                    PaidCampaignBannerSection(
                      businessId: place.id,
                      compactTitle: 'Campañas del comercio',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionTitle('Promociones'),
                    const SizedBox(height: AppSpacing.sm),
                    ...detail.promotions.map(
                      (promotion) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: PlaceDetailPromotionCard(promotion: promotion),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _SectionTitle('Productos'),
                    const SizedBox(height: AppSpacing.sm),
                    if (_products.isEmpty)
                      Text(
                        'No hay productos disponibles.',
                        style: AppTextStyles.bodyMuted,
                      )
                    else
                      ..._products.map(
                        (product) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ProductTile(product: product),
                        ),
                      ),
                    if (_products.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      CiervoButton(
                        label: 'Comprar',
                        icon: Icons.shopping_bag_outlined,
                        onPressed: () => _openOrderCheckout(context),
                      ),
                    ],
                    if (_products.any((item) => item.allowsPickup)) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const _CapabilityLine(
                        icon: Icons.storefront_outlined,
                        text: 'Recoger en tienda disponible',
                      ),
                    ],
                    if (_products.any((item) => item.allowsDelivery) &&
                        (_deliveryAvailability?.deliveryAvailable ??
                            false)) ...[
                      const SizedBox(height: AppSpacing.sm),
                      CiervoButton(
                        label: 'Pedir domicilio',
                        icon: Icons.delivery_dining,
                        onPressed: () => _showDeliverySheet(context),
                      ),
                    ] else if (_products.any(
                      (item) => item.allowsDelivery,
                    )) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _CapabilityLine(
                        icon: Icons.delivery_dining_outlined,
                        text:
                            _deliveryAvailability?.message ??
                            'Domicilio no disponible para tu ubicacion.',
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    const _SectionTitle('Ubicacion'),
                    const SizedBox(height: AppSpacing.sm),
                    PlaceDetailLocationCard(
                      locationLabel: detail.locationLabel,
                      distanceKm: detail.distanceKm,
                      latitude: _publicDetail?.latitude,
                      longitude: _publicDetail?.longitude,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        const Expanded(child: _SectionTitle('Reseñas')),
                        if ((_hasReviewed && _userReviewId != null) ||
                            (!_hasReviewed && _canCreateReview))
                          TextButton.icon(
                            icon: const Icon(Icons.star_outline),
                            label: Text(_hasReviewed ? 'Editar' : 'Calificar'),
                            onPressed: () => _showReviewSheet(context),
                          ),
                      ],
                    ),
                    if (!_hasReviewed && !_canCreateReview)
                      Text(
                        _publicDetail?.reviewEligibilityReason ??
                            'Debes tener una reserva, pedido, recibo, ticket o promocion redimida para calificar este negocio.',
                        style: AppTextStyles.bodyMuted,
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    ...(_reviews.isEmpty ? detail.reviews : _reviews).map(
                      (review) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: PlaceDetailReviewTile(review: review),
                      ),
                    ),
                    const SizedBox(height: 96),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.sm,
                  top: AppSpacing.sm,
                ),
                child: Material(
                  color: AppColors.glass,
                  borderRadius: AppRadii.chip,
                  child: IconButton(
                    tooltip: 'Volver',
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 380;
            final veryNarrow = constraints.maxWidth < 320;
            return Row(
              children: [
                FavoriteCiervoButton(
                  key: ValueKey('${place.id}-${_publicDetail?.isFavorite}'),
                  businessId: place.id,
                  initialValue: _publicDetail?.isFavorite ?? place.isFavorite,
                  size: narrow ? 40 : 44,
                ),
                SizedBox(width: narrow ? AppSpacing.xs : AppSpacing.sm),
                IconButton.filledTonal(
                  tooltip: 'Contactar negocio',
                  visualDensity: narrow
                      ? VisualDensity.compact
                      : VisualDensity.standard,
                  icon: const Icon(Icons.forum_outlined),
                  onPressed: () => _openBusinessChat(context),
                ),
                SizedBox(width: narrow ? AppSpacing.xs : AppSpacing.sm),
                IconButton.filledTonal(
                  tooltip: 'Compartir negocio',
                  visualDensity: narrow
                      ? VisualDensity.compact
                      : VisualDensity.standard,
                  icon: const Icon(Icons.share_outlined),
                  onPressed: _shareBusiness,
                ),
                if (_children.isNotEmpty && !veryNarrow) ...[
                  SizedBox(width: narrow ? AppSpacing.xs : AppSpacing.sm),
                  IconButton.filledTonal(
                    tooltip: 'Agregar comercio a mi hijo',
                    visualDensity: narrow
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                    icon: _associatingKid
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.child_care_outlined),
                    onPressed: _associatingKid ? null : _associateBusinessToKid,
                  ),
                ],
                SizedBox(width: narrow ? AppSpacing.xs : AppSpacing.sm),
                Expanded(
                  child: CiervoButton(
                    label: 'Reservar',
                    icon: Icons.event_seat,
                    dense: true,
                    showIcon: !narrow,
                    onPressed: () => _showReservationSheet(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  PlaceDetail? _detailFromPublic() {
    final source = _publicDetail;
    if (source == null) return null;
    final place = widget.place;
    return PlaceDetail(
      id: widget.place.id,
      name: source.name.isEmpty ? place.name : source.name,
      category: source.categoryName.isEmpty
          ? place.category
          : source.categoryName,
      imageUrl: source.imageUrl.isEmpty ? place.imageUrl : source.imageUrl,
      gallery: source.gallery.isEmpty
          ? (source.imageUrl.isEmpty ? const [] : [source.imageUrl])
          : source.gallery,
      rating: source.ratingAverage ?? source.score ?? place.rating,
      reviewCount: source.reviewsCount ?? 0,
      locationLabel: [
        if (source.address.isNotEmpty) source.address,
        if (source.city.isNotEmpty) source.city,
      ].join(source.address.isNotEmpty && source.city.isNotEmpty ? ', ' : ''),
      distanceKm: source.distanceKm == 0 ? place.distanceKm : source.distanceKm,
      description: source.description,
      tags: [
        if (source.categoryName.isNotEmpty) source.categoryName.toUpperCase(),
        ...source.amenityTags,
        if ((source.likes ?? 0) > 0) '${source.likes} likes',
      ],
      promotions: source.promotions,
      reviews: source.reviews,
    );
  }

  Future<void> _shareBusiness() async {
    final detail = _publicDetail;
    final name = detail?.name.isNotEmpty == true
        ? detail!.name
        : widget.place.name;
    final link = CiervoBusinessShareLink.build(
      businessId: widget.place.id,
      name: name,
    );
    final description = detail?.shareDescription?.trim();
    final body = [
      if (description != null && description.isNotEmpty) description,
      link,
    ].join('\n');
    await CiervoShare.shareText(body, subject: detail?.shareTitle ?? name);
  }

  Future<void> _associateBusinessToKid() async {
    if (_children.isEmpty || _associatingKid) return;
    final merchantId = int.tryParse(widget.place.id);
    if (merchantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos identificar este comercio.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<ChildProfile>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Agregar comercio a mi hijo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ..._children.map(
                (child) => ListTile(
                  leading: const Icon(Icons.child_care_outlined),
                  title: Text('${child.firstName} ${child.lastName}'.trim()),
                  subtitle: Text('Comercios: ${child.allowedBusinessesCount}'),
                  onTap: () => Navigator.pop(context, child),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;

    final kidId = int.tryParse(selected.id);
    if (kidId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil del menor no válido.')),
      );
      return;
    }

    setState(() => _associatingKid = true);
    final result = await getIt<MasterKidsRepository>().addMerchant(
      kidId,
      KidRuleMerchantCommand(merchantId),
    );
    if (!mounted) return;
    setState(() => _associatingKid = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Comercio asociado a ${selected.firstName}.')),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
      },
    );
  }

  void _showReviewSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: _ReviewSheet(
          businessId: widget.place.id,
          reviewId: _userReviewId,
          sourceType: _publicDetail?.reviewSourceType,
          sourceId: _publicDetail?.reviewSourceId,
          initialReview: _currentUserReview(),
          onSaved: _loadCapabilities,
        ),
      ),
    );
  }

  PlaceReview? _currentUserReview() {
    final reviewId = _userReviewId;
    if (reviewId == null) return null;
    for (final review in _reviews) {
      if (review.id == reviewId) return review;
    }
    return null;
  }

  void _showReservationSheet(BuildContext context) {
    showBusinessReservationSheet(
      context,
      businessId: widget.place.id,
      businessName: widget.place.name,
      options: _reservableOptions,
    );
  }

  void _showDeliverySheet(BuildContext context) {
    _openOrderCheckout(
      context,
      initialFulfillment: OrderFulfillmentType.delivery,
      products: _products.where((item) => item.allowsDelivery).toList(),
    );
  }

  void _openOrderCheckout(
    BuildContext context, {
    OrderFulfillmentType? initialFulfillment,
    List<BusinessProduct>? products,
  }) {
    final checkoutProducts =
        products ??
        _products
            .where((item) => item.allowsDelivery || item.allowsPickup)
            .toList();
    if (checkoutProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos disponibles para compra.'),
        ),
      );
      return;
    }
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa tu ubicación para continuar.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderCheckoutPage(
          businessId: widget.place.id,
          businessName: widget.place.name,
          products: checkoutProducts,
          initialLocation: _location!,
          initialFulfillment: initialFulfillment,
          deliveryAvailability: _deliveryAvailability,
        ),
      ),
    );
  }

  Future<void> _openBusinessChat(BuildContext context) async {
    final businessId = int.tryParse(widget.place.id);
    if (businessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos identificar este negocio.')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final repository = getIt<ChatRepository>();
    final existingResult = await repository.conversations();
    final existing = existingResult.when(
      success: (items) => items
          .where((conversation) => conversation.businessId == businessId)
          .firstOrNull,
      failure: (_) => null,
    );
    final result = existing == null
        ? await repository.createBusinessConversation(
            businessId: businessId,
            title: widget.place.name,
          )
        : Success(existing);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    result.when(
      success: (conversation) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatConversationPage(
            conversationId: conversation.id,
            title: conversation.title,
          ),
        ),
      ),
      failure: (error) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error)))),
    );
  }

  bool get _canCreateReview {
    final detail = _publicDetail;
    return detail?.canReview == true &&
        detail?.reviewSourceType != null &&
        detail?.reviewSourceId != null &&
        detail!.reviewSourceId! > 0;
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final BusinessProduct product;

  @override
  Widget build(BuildContext context) {
    final flags = [
      if (product.allowsDelivery) 'Domicilio',
      if (product.allowsPickup) 'Recoger',
      if (product.preparationTimeMinutes != null)
        '${product.preparationTimeMinutes} min',
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: product.imageUrl.isEmpty
          ? const CircleAvatar(child: Icon(Icons.restaurant_menu))
          : ClipRRect(
              borderRadius: AppRadii.input,
              child: SizedBox.square(
                dimension: 52,
                child: AuthenticatedMediaImage(
                  mediaId: product.imageUrl,
                  thumbnail: true,
                  fit: BoxFit.cover,
                ),
              ),
            ),
      title: Text(product.name),
      subtitle: Text(
        [
          if (product.description.isNotEmpty) product.description,
          if (flags.isNotEmpty) flags.join(' - '),
        ].join('\n'),
      ),
      trailing: Text(
        DisplayFormatters.formatPrice(product.price),
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}

class _CapabilityLine extends StatelessWidget {
  const _CapabilityLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: AppSpacing.xs),
      Expanded(child: Text(text, style: AppTextStyles.bodyMuted)),
    ],
  );
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({
    required this.businessId,
    required this.onSaved,
    this.reviewId,
    this.sourceType,
    this.sourceId,
    this.initialReview,
  });

  final String businessId;
  final int? reviewId;
  final String? sourceType;
  final int? sourceId;
  final PlaceReview? initialReview;
  final VoidCallback onSaved;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialReview;
    if (initial != null) {
      _rating = initial.rating.round().clamp(1, 5);
      _commentController.text = initial.comment;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      top: AppSpacing.sm,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Calificar negocio', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('1')),
            ButtonSegment(value: 2, label: Text('2')),
            ButtonSegment(value: 3, label: Text('3')),
            ButtonSegment(value: 4, label: Text('4')),
            ButtonSegment(value: 5, label: Text('5')),
          ],
          selected: {_rating},
          onSelectionChanged: (value) {
            setState(() => _rating = value.first);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _commentController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Comentario opcional'),
        ),
        const SizedBox(height: AppSpacing.md),
        CiervoButton(
          label: _submitting ? 'Guardando' : 'Guardar calificación',
          icon: Icons.star_outline,
          state: _submitting
              ? CiervoButtonState.loading
              : CiervoButtonState.normal,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    ),
  );

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final repository = getIt<ReviewRepository>();
    final result = widget.reviewId == null
        ? await repository.create(
            businessId: int.tryParse(widget.businessId) ?? 0,
            sourceType: widget.sourceType,
            sourceId: widget.sourceId,
            rating: _rating,
            comment: _commentController.text,
          )
        : await repository.update(
            reviewId: widget.reviewId!,
            businessId: int.tryParse(widget.businessId) ?? 0,
            sourceType: widget.sourceType,
            sourceId: widget.sourceId,
            rating: _rating,
            comment: _commentController.text,
          );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      success: (_) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        widget.onSaved();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              widget.reviewId == null
                  ? 'Reseña enviada. ¡Gracias por tu opinión!'
                  : 'Reseña actualizada.',
            ),
          ),
        );
      },
      failure: (error) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error)))),
    );
  }
}

int? _businessCategoryIdFrom(String value) {
  final normalized = value
      .toLowerCase()
      .replaceAll('Ã­', 'i')
      .replaceAll('Ã©', 'e')
      .replaceAll('Ã¡', 'a')
      .replaceAll('Ã³', 'o')
      .replaceAll('Ãº', 'u')
      .trim();
  return switch (normalized) {
    'hoteles' || 'hotel' => 101,
    'restaurantes' || 'restaurante' => 102,
    'bares' || 'bar' => 103,
    'discotecas' || 'discoteca' => 104,
    'licorerias' || 'licoreria' => 105,
    'farmacias' || 'farmacia' => 106,
    'turismo' => 107,
    'transporte' => 108,
    _ => null,
  };
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.detail, this.showBack = true});

  final PlaceDetail detail;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final images = detail.gallery.isEmpty
        ? [if (detail.imageUrl.isNotEmpty) detail.imageUrl]
        : detail.gallery;
    return GestureDetector(
      onTap: images.isEmpty
          ? null
          : () => openCiervoImageViewer(context, images: images),
      child: Stack(
        children: [
          Hero(
            tag: 'place-${detail.id}',
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (images.length > 1)
                    PageView.builder(
                      itemCount: images.length,
                      itemBuilder: (context, index) => AuthenticatedMediaImage(
                        mediaId: images[index],
                        fit: BoxFit.cover,
                        errorWidget: const ColoredBox(
                          color: AppColors.surfaceTop,
                        ),
                      ),
                    )
                  else if (images.isNotEmpty)
                    AuthenticatedMediaImage(
                      mediaId: images.first,
                      fit: BoxFit.cover,
                      errorWidget: const ColoredBox(
                        color: AppColors.surfaceTop,
                      ),
                    )
                  else
                    const ColoredBox(color: AppColors.surfaceTop),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppComponentStyles.cardOverlayGradient,
                    ),
                  ),
                  if (images.isNotEmpty)
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: AppRadii.chip,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            child: Icon(
                              Icons.zoom_out_map_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (images.length > 1)
                    Positioned(
                      right: AppSpacing.md,
                      bottom: AppSpacing.xl + AppSpacing.sm,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: AppRadii.chip,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          child: Icon(
                            Icons.swipe,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (showBack)
            Positioned(
              top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
              left: AppSpacing.sm,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: AppRadii.chip,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: tags
          .map(
            (tag) => CiervoChipTag(
              label: tag,
              selected: tag == tags.first,
              onSelected: (_) {},
            ),
          )
          .toList(),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.detail, this.ratingAverage, this.reviewsCount});

  final PlaceDetail detail;
  final double? ratingAverage;
  final int? reviewsCount;

  @override
  Widget build(BuildContext context) {
    final rating = ratingAverage ?? detail.rating;
    final count = reviewsCount ?? detail.reviewCount;
    return Text(
      '$rating - $count reseñas - ${detail.locationLabel}',
      style: AppTextStyles.bodyMuted,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.title);
  }
}
