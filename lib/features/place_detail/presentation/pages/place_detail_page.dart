import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../../core/experience/experience_mode.dart';
import '../../../../core/experience/experience_mode_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_component_styles.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_chip_tag.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../../home/domain/entities/home_place.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../chat/presentation/pages/chat_conversation_page.dart';
import '../../../delivery/domain/repositories/delivery_repository.dart';
import '../../../favorites/data/favorites_repository.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/result/result.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../data/business_detail_repository.dart';
import '../../data/review_repository.dart';
import '../../domain/entities/place_detail.dart';
import '../../../location/data/client_location_repository.dart';
import '../widgets/place_detail_location_card.dart';
import '../widgets/place_detail_promotion_card.dart';
import '../widgets/place_detail_review_tile.dart';
import '../../../media/presentation/authenticated_media_image.dart';
import '../../../product_categories/presentation/widgets/product_subcategory_filters.dart';
import '../../../reservations/data/booking_repository.dart';
import '../../../../core/kids/selected_kid_context.dart';
import '../../../delivery/presentation/pages/customer_order_detail_page.dart';
import '../../../receipts/presentation/pages/action_confirmation_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
  }

  bool _loadFailed = false;

  Future<void> _loadCapabilities() async {
    final locationResult = await getIt<ClientLocationRepository>()
        .syncForRecommendations(
          city: widget.place.city ?? 'Bogota',
          countryCode: widget.place.countryCode ?? 'CO',
        );
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
        failure: (_) => _loadFailed = true,
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
      return Scaffold(
        appBar: AppBar(title: Text(place.name)),
        body: CiervoErrorState(
          title: 'No pudimos cargar el comercio',
          description: 'Verifica tu conexion e intenta nuevamente.',
          onRetry: () {
            setState(() => _loadingCapabilities = true);
            _loadCapabilities();
          },
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _HeroSection(detail: detail)),
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
                      avatar: const Icon(Icons.verified_user_outlined, size: 18),
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
                  Text('No hay productos disponibles.', style: AppTextStyles.bodyMuted)
                else
                  ..._products.map(
                    (product) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ProductTile(product: product),
                    ),
                  ),
                if (_products.any((item) => item.allowsPickup)) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const _CapabilityLine(
                    icon: Icons.storefront_outlined,
                    text: 'Recoger en tienda disponible',
                  ),
                ],
                if (_products.any((item) => item.allowsDelivery) &&
                    (_deliveryAvailability?.deliveryAvailable ?? false)) ...[
                  const SizedBox(height: AppSpacing.sm),
                  CiervoButton(
                    label: 'Pedir domicilio',
                    icon: Icons.delivery_dining,
                    onPressed: () => _showDeliverySheet(context),
                  ),
                ] else if (_products.any((item) => item.allowsDelivery)) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _CapabilityLine(
                    icon: Icons.delivery_dining_outlined,
                    text: _deliveryAvailability?.message ??
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
                    const Expanded(child: _SectionTitle('ReseÃ±as')),
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
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            _FavoriteButton(
              key: ValueKey('${place.id}-${_publicDetail?.isFavorite}'),
              businessId: place.id,
              initialValue: _publicDetail?.isFavorite ?? place.isFavorite,
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filledTonal(
              tooltip: 'Contactar negocio',
              icon: const Icon(Icons.forum_outlined),
              onPressed: () => _openBusinessChat(context),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filledTonal(
              tooltip: 'Compartir negocio',
              icon: const Icon(Icons.share_outlined),
              onPressed: _shareBusiness,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: CiervoButton(
                label: 'Reservar',
                icon: Icons.event_seat,
                onPressed: () => _showReservationSheet(context),
              ),
            ),
          ],
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
        if ((source.likes ?? 0) > 0) '${source.likes} likes',
      ],
      promotions: source.promotions,
      reviews: source.reviews,
    );
  }

  Future<void> _shareBusiness() async {
    final detail = _publicDetail;
    final parts = [
      detail?.shareTitle,
      detail?.shareDescription,
      detail?.publicUrl,
    ].whereType<String>().where((item) => item.trim().isNotEmpty).toList();
    if (parts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este negocio aun no tiene enlace para compartir.')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: parts.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enlace del negocio copiado.')),
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
    if (_reservableOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este negocio aun no tiene opciones de reserva.'),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: _ReservationSheet(
          businessId: widget.place.id,
          options: _reservableOptions,
        ),
      ),
    );
  }

  void _showDeliverySheet(BuildContext context) {
    final deliveryProducts =
        _products.where((item) => item.allowsDelivery).toList();
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa tu ubicacion para pedir domicilio.')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: _DeliveryOrderSheet(
          businessId: widget.place.id,
          products: deliveryProducts,
          location: _location!,
          availability: _deliveryAvailability,
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
            title: 'Consulta ${widget.place.name}',
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
      subtitle: Text([
        if (product.description.isNotEmpty) product.description,
        if (flags.isNotEmpty) flags.join(' - '),
      ].join('\n')),
      trailing: Text('\$${product.price}'),
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

class _ReservationSheet extends StatefulWidget {
  const _ReservationSheet({required this.businessId, required this.options});

  final String businessId;
  final List<ReservableOption> options;

  @override
  State<_ReservationSheet> createState() => _ReservationSheetState();
}

class _ReservationSheetState extends State<_ReservationSheet> {
  final _notesController = TextEditingController();
  ReservableOption? _option;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  int _peopleCount = 2;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _option = widget.options.firstOrNull;
  }

  @override
  void dispose() {
    _notesController.dispose();
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
            Text('Reservar', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<ReservableOption>(
              initialValue: _option,
              items: widget.options
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.name.isEmpty ? 'Opcion ${item.id}' : item.name),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _option = value),
              decoration: const InputDecoration(labelText: 'Opcion'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_date.toIso8601String().substring(0, 10)),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: Text(_time.format(context)),
                    onPressed: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Stepper(
              currentStep: 0,
              controlsBuilder: (_, _) => const SizedBox.shrink(),
              steps: [
                Step(
                  title: Text('Personas: $_peopleCount'),
                  content: Slider(
                    min: 1,
                    max: 12,
                    divisions: 11,
                    value: _peopleCount.toDouble(),
                    label: '$_peopleCount',
                    onChanged: (value) =>
                        setState(() => _peopleCount = value.round()),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _notesController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notas opcionales'),
            ),
            const SizedBox(height: AppSpacing.md),
            CiervoButton(
              label: _submitting ? 'Confirmando' : 'Confirmar reserva',
              icon: Icons.event_available,
              state: _submitting ? CiervoButtonState.loading : CiervoButtonState.normal,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      );

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: _date,
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(context: context, initialTime: _time);
    if (value != null) setState(() => _time = value);
  }

  Future<void> _submit() async {
    final option = _option;
    if (option == null) return;
    setState(() => _submitting = true);
    final result = await getIt<BookingRepository>().createBusinessReservation(
      businessId: widget.businessId,
      reservableOptionId: option.id,
      date: _date,
      time:
          '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}:00',
      peopleCount: _peopleCount,
      notes: _notesController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      success: (booking) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ActionConfirmationPage(
              confirmation: booking.confirmation!,
            ),
          ),
        );
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }
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
        Navigator.of(context).pop();
        widget.onSaved();
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }
}
class _DeliveryOrderSheet extends StatefulWidget {
  const _DeliveryOrderSheet({
    required this.businessId,
    required this.products,
    required this.location,
    required this.availability,
  });

  final String businessId;
  final List<BusinessProduct> products;
  final AppLocation location;
  final DeliveryAvailability? availability;

  @override
  State<_DeliveryOrderSheet> createState() => _DeliveryOrderSheetState();
}

class _DeliveryOrderSheetState extends State<_DeliveryOrderSheet> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _quantities = <String, int>{};
  bool _submitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Pedir domicilio', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.md),
              ...widget.products.map(_quantityTile),
              const SizedBox(height: AppSpacing.sm),
              _DeliverySummary(
                productsSubtotal: _productsSubtotal,
                deliveryFee: widget.availability?.estimatedDeliveryFee ?? 0,
                currency: widget.availability?.currency ?? 'COP',
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Direccion de entrega'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _notesController,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notas opcionales'),
              ),
              const SizedBox(height: AppSpacing.md),
              CiervoButton(
                label: _submitting ? 'Creando pedido' : 'Confirmar pedido',
                icon: Icons.shopping_bag_outlined,
                state: _submitting ? CiervoButtonState.loading : CiervoButtonState.normal,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      );

  Widget _quantityTile(BusinessProduct product) {
    final quantity = _quantities[product.id] ?? 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(product.name),
      subtitle: Text('\$${product.price}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: quantity == 0
                ? null
                : () => setState(() => _quantities[product.id] = quantity - 1),
          ),
          SizedBox(width: 24, child: Center(child: Text('$quantity'))),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => setState(() => _quantities[product.id] = quantity + 1),
          ),
        ],
      ),
    );
  }

  num get _productsSubtotal {
    num total = 0;
    for (final product in widget.products) {
      total += product.price * (_quantities[product.id] ?? 0);
    }
    return total;
  }

  Future<void> _submit() async {
    final items = _quantities.entries
        .where((entry) => entry.value > 0)
        .map((entry) => DeliveryOrderItemRequest(
              productId: entry.key,
              quantity: entry.value,
            ))
        .toList();
    if (items.isEmpty || _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona productos y direccion.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final childProfileId = getIt<SelectedKidContext>().kidId;
    final result = await getIt<DeliveryRepository>().createCustomerOrder(
      businessId: widget.businessId,
      deliveryAddress: _addressController.text.trim(),
      latitude: widget.location.latitude,
      longitude: widget.location.longitude,
      items: items,
      notes: _notesController.text,
      childProfileId: childProfileId,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      success: (order) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CustomerOrderDetailPage(orderId: order.id),
          ),
        );
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }
}

class _DeliverySummary extends StatelessWidget {
  const _DeliverySummary({
    required this.productsSubtotal,
    required this.deliveryFee,
    required this.currency,
  });

  final num productsSubtotal;
  final num deliveryFee;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final total = productsSubtotal + deliveryFee;
    return CiervoCard(
      child: Column(
        children: [
          _AmountRow(
            label: 'Subtotal productos',
            value: _money(productsSubtotal, currency),
          ),
          const SizedBox(height: AppSpacing.xs),
          _AmountRow(label: 'Domicilio', value: _money(deliveryFee, currency)),
          const Divider(),
          _AmountRow(
            label: 'Total a pagar',
            value: _money(total, currency),
            prominent: true,
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.prominent = false,
  });

  final String label;
  final String value;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final style = prominent
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

String _money(num value, String currency) =>
    '$currency ${value.toStringAsFixed(0)}';

class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({
    required this.businessId,
    required this.initialValue,
    super.key,
  });

  final String businessId;
  final bool initialValue;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _favorite = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _favorite = widget.initialValue;
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<FavoritesRepository>().exists(widget.businessId);
    if (!mounted) return;
    result.when(
      success: (value) => setState(() => _favorite = value),
      failure: (_) {},
    );
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    final repository = getIt<FavoritesRepository>();
    final result = _favorite
        ? await repository.remove(widget.businessId)
        : await repository.add(widget.businessId);
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) {
        setState(() => _favorite = !_favorite);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _favorite ? 'Agregado a favoritos.' : 'Quitado de favoritos.',
            ),
          ),
        );
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
        tooltip: _favorite ? 'Quitar favorito' : 'Agregar favorito',
        onPressed: _busy ? null : _toggle,
        icon: _busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_favorite ? Icons.favorite : Icons.favorite_border),
      );
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
  const _HeroSection({required this.detail});

  final PlaceDetail detail;

  @override
  Widget build(BuildContext context) {
    final images = detail.gallery.isEmpty
        ? [if (detail.imageUrl.isNotEmpty) detail.imageUrl]
        : detail.gallery;
    return Stack(
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
                      errorWidget: const ColoredBox(color: AppColors.surfaceTop),
                    ),
                  )
                else if (images.isNotEmpty)
                  AuthenticatedMediaImage(
                    mediaId: images.first,
                    fit: BoxFit.cover,
                    errorWidget: const ColoredBox(color: AppColors.surfaceTop),
                  )
                else
                  const ColoredBox(color: AppColors.surfaceTop),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppComponentStyles.cardOverlayGradient,
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
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
                        child: Icon(Icons.swipe, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
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
  const _MetaRow({
    required this.detail,
    this.ratingAverage,
    this.reviewsCount,
  });

  final PlaceDetail detail;
  final double? ratingAverage;
  final int? reviewsCount;

  @override
  Widget build(BuildContext context) {
    final rating = ratingAverage ?? detail.rating;
    final count = reviewsCount ?? detail.reviewCount;
    return Text(
      '$rating - $count reseÃ±as - ${detail.locationLabel}',
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
