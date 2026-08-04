import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/ciervo_share.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../media/presentation/authenticated_media_image.dart';
import '../../domain/entities/marketplace_models.dart';
import '../../domain/repositories/marketplace_repository.dart';

class MarketplacePromoDetailPage extends StatefulWidget {
  const MarketplacePromoDetailPage({required this.promotionId, super.key});

  final int promotionId;

  @override
  State<MarketplacePromoDetailPage> createState() =>
      _MarketplacePromoDetailPageState();
}

class _MarketplacePromoDetailPageState
    extends State<MarketplacePromoDetailPage> {
  final _repo = getIt<MarketplaceRepository>();
  MarketplacePromo? _promo;
  MarketplaceBenefits? _benefits;
  String? _error;
  bool _loading = true;
  int _quantity = 1;
  String _paymentMethod = 'CIERVO';
  bool _favoriteBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.promotion(widget.promotionId);
    await result.when(
      success: (promo) async {
        _promo = promo;
        await _repo.recordView(promo.id);
        await _repo.recordClick(promo.id);
        await _refreshBenefits();
      },
      failure: (error) async {
        _error = UserErrorMessage.from(error);
      },
    );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refreshBenefits() async {
    final promo = _promo;
    if (promo == null) return;
    final result = await _repo.calculateBenefits(
      promotionId: promo.id,
      quantity: _quantity,
      paymentMethod: _paymentMethod,
    );
    result.when(
      success: (benefits) {
        if (mounted) setState(() => _benefits = benefits);
      },
      failure: (_) {},
    );
  }

  Future<void> _toggleFavorite() async {
    final promo = _promo;
    if (promo == null || _favoriteBusy) return;
    setState(() => _favoriteBusy = true);
    final result = promo.isFavorite
        ? await _repo.removeFavorite(promo.id)
        : await _repo.addFavorite(promo.id);
    result.when(
      success: (_) {
        setState(() {
          _promo = promo.copyWith(isFavorite: !promo.isFavorite);
        });
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
    );
    if (mounted) setState(() => _favoriteBusy = false);
  }

  Future<void> _share() async {
    final promo = _promo;
    if (promo == null) return;
    await _repo.recordShare(promo.id);
    await CiervoShare.shareText(
      '${promo.title} en ${promo.businessName} · CIERVO Marketplace',
      subject: promo.title,
    );
  }

  Future<void> _reserve() async {
    final promo = _promo;
    if (promo == null) return;
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );
    if (!mounted) return;
    final result = await _repo.createReservation(
      promotionId: promo.id,
      date: date,
      time: time == null
          ? null
          : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      people: _quantity.clamp(1, 20),
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva creada.')),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserErrorMessage.from(error))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CiervoLoadingState(itemCount: 3)));
    }
    if (_error != null || _promo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Promoción')),
        body: CiervoErrorState(
          title: 'No pudimos cargar la promo',
          description: _error ?? 'Intenta de nuevo.',
          onRetry: _load,
        ),
      );
    }

    final promo = _promo!;
    final price = promo.offerPrice ?? promo.price;
    final benefits = _benefits;

    return Scaffold(
      appBar: AppBar(
        title: Text(promo.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: promo.isFavorite
                ? Image.asset(
                    'assets/notifications/ciervo_logo_gold.png',
                    width: 22,
                    height: 22,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.pets,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.pets_outlined),
            color: promo.isFavorite ? AppColors.primary : null,
          ),
          IconButton(onPressed: _share, icon: const Icon(Icons.share_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: promo.imageUrl.isNotEmpty
                  ? AuthenticatedMediaImage(
                      mediaId: promo.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A1712), Color(0xFF0D0D0D)],
                          ),
                        ),
                      ),
                    )
                  : const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1A1712), Color(0xFF0D0D0D)],
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(promo.title, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            onTap: () => context.push('/marketplace/stores/${promo.businessId}'),
            child: Text(
              promo.businessName,
              style: AppTextStyles.body.copyWith(color: AppColors.primary),
            ),
          ),
          if (promo.description?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            Text(promo.description!, style: AppTextStyles.bodyMuted),
          ],
          if (promo.conditions?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Condiciones', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.xs),
            Text(promo.conditions!, style: AppTextStyles.bodyMuted),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (price != null)
            Text(
              DisplayFormatters.formatMoney(price, currency: promo.currency),
              style: AppTextStyles.title.copyWith(color: AppColors.primary),
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Text('Cantidad'),
              const Spacer(),
              IconButton(
                onPressed: _quantity <= 1
                    ? null
                    : () async {
                        setState(() => _quantity--);
                        await _refreshBenefits();
                      },
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_quantity', style: AppTextStyles.title),
              IconButton(
                onPressed: () async {
                  setState(() => _quantity++);
                  await _refreshBenefits();
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final method in const ['CIERVO', 'CONTACT', 'PENDING'])
                ChoiceChip(
                  label: Text(method),
                  selected: _paymentMethod == method,
                  onSelected: (_) async {
                    setState(() => _paymentMethod = method);
                    await _refreshBenefits();
                  },
                ),
            ],
          ),
          if (benefits != null) ...[
            const SizedBox(height: AppSpacing.md),
            Card(
              color: AppColors.surfaceHigh,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Beneficios', style: AppTextStyles.label),
                    const SizedBox(height: AppSpacing.xs),
                    _BenefitRow(
                      'Subtotal',
                      DisplayFormatters.formatMoney(
                        benefits.subtotal,
                        currency: benefits.currency,
                      ),
                    ),
                    _BenefitRow(
                      'Descuento',
                      DisplayFormatters.formatMoney(
                        benefits.discount,
                        currency: benefits.currency,
                      ),
                    ),
                    _BenefitRow(
                      'Cashback',
                      DisplayFormatters.formatMoney(
                        benefits.cashback,
                        currency: benefits.currency,
                      ),
                    ),
                    _BenefitRow('Puntos', '${benefits.totalPoints}'),
                    const Divider(),
                    _BenefitRow(
                      'Total a pagar',
                      DisplayFormatters.formatMoney(
                        benefits.totalPay,
                        currency: benefits.currency,
                      ),
                      emphasize: true,
                    ),
                    if (!benefits.eligible &&
                        benefits.eligibilityMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          benefits.eligibilityMessage!,
                          style: AppTextStyles.bodyMuted.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (promo.reservationEnabled)
            CiervoButton(
              label: 'Reservar',
              icon: Icons.event_available_outlined,
              onPressed: _reserve,
            ),
          const SizedBox(height: AppSpacing.sm),
          CiervoButton(
            label: 'Comprar',
            icon: Icons.shopping_bag_outlined,
            onPressed: () => context.push(
              '/marketplace/promos/${promo.id}/checkout',
              extra: {
                'quantity': _quantity,
                'paymentMethod': _paymentMethod,
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow(this.label, this.value, {this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasize ? AppTextStyles.label : AppTextStyles.bodyMuted,
            ),
          ),
          Text(
            value,
            style: emphasize
                ? AppTextStyles.label.copyWith(color: AppColors.primary)
                : AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
