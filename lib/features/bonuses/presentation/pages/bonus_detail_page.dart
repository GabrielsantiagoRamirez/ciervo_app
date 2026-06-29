import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../home/domain/entities/home_place.dart';
import '../../../media/presentation/authenticated_media_image.dart';
import '../../../place_detail/presentation/pages/place_detail_page.dart';
import '../../domain/entities/bonus.dart';
import '../../domain/repositories/bonuses_repository.dart';
import '../utils/bonus_error_messages.dart';
import '../widgets/bonus_card.dart';

class BonusDetailPage extends StatefulWidget {
  const BonusDetailPage({required this.bonusId, super.key});

  final String bonusId;

  @override
  State<BonusDetailPage> createState() => _BonusDetailPageState();
}

class _BonusDetailPageState extends State<BonusDetailPage> {
  Bonus? _bonus;
  var _loading = true;
  var _busy = false;
  String? _error;

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
    final result = await getIt<BonusesRepository>().detail(widget.bonusId);
    if (!mounted) return;
    result.when(
      success: (bonus) => setState(() {
        _bonus = bonus;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = BonusErrorMessages.fromObject(error);
        _loading = false;
      }),
    );
  }

  Future<void> _claim() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await getIt<BonusesRepository>().claim(widget.bonusId);
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (bonus) {
        setState(() => _bonus = bonus);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bono reclamado correctamente.')),
        );
      },
      failure: (error) => _showError(error),
    );
  }

  Future<void> _redeem() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await getIt<BonusesRepository>().redeem(widget.bonusId);
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (bonus) {
        setState(() => _bonus = bonus);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bono redimido correctamente.')),
        );
      },
      failure: (error) => _showError(error),
    );
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(BonusErrorMessages.fromObject(error))),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: CiervoBrandLoader(message: 'Cargando bono'),
      );
    }
    if (_error != null || _bonus == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bono')),
        body: Center(child: Text(_error ?? 'No encontrado')),
      );
    }
    final bonus = _bonus!;
    final canClaim = bonus.status == BonusStatus.active;
    final canRedeem = bonus.canRedeem ||
        bonus.status == BonusStatus.claimed ||
        bonus.status == BonusStatus.paid;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del bono')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if ((bonus.imageUrl ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: AuthenticatedMediaImage(
                  mediaId: bonus.imageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          BonusCard(bonus: bonus, onTap: () {}),
          const SizedBox(height: AppSpacing.md),
          Text(bonus.description, style: AppTextStyles.body),
          if (bonus.validUntil != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Valido hasta: ${bonus.validUntil!.toLocal()}',
              style: AppTextStyles.bodyMuted,
            ),
          ],
          if ((bonus.promoCode ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ListTile(
              tileColor: AppColors.surfaceHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text('Codigo: ${bonus.promoCode}'),
              trailing: IconButton(
                icon: const Icon(Icons.copy_outlined),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: bonus.promoCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Codigo copiado.')),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (canClaim)
            CiervoButton(
              label: _busy ? 'Procesando...' : 'Reclamar bono',
              icon: Icons.card_giftcard,
              onPressed: _busy ? null : _claim,
            ),
          if (!canClaim && canRedeem)
            CiervoButton(
              label: _busy ? 'Procesando...' : 'Redimir bono',
              icon: Icons.redeem_outlined,
              onPressed: _busy ? null : _redeem,
            ),
          if (bonus.businessId.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PlaceDetailPage(
                    place: HomePlace(
                      id: bonus.businessId,
                      name: bonus.businessName,
                      category: 'Comercio',
                      rating: 0,
                      priceLevel: '',
                      distanceKm: bonus.distanceKm ?? 0,
                      matchPercent: 0,
                      imageUrl: bonus.imageUrl ?? '',
                      city: bonus.city,
                      countryCode: bonus.country,
                    ),
                  ),
                ),
              ),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Ver establecimiento'),
            ),
          ],
        ],
      ),
    );
  }
}

class PlaceDetailBonusesSection extends StatefulWidget {
  const PlaceDetailBonusesSection({required this.businessId, super.key});

  final String businessId;

  @override
  State<PlaceDetailBonusesSection> createState() =>
      _PlaceDetailBonusesSectionState();
}

class _PlaceDetailBonusesSectionState extends State<PlaceDetailBonusesSection> {
  late Future<List<Bonus>> _items;

  @override
  void initState() {
    super.initState();
    _items = _load();
  }

  Future<List<Bonus>> _load() async {
    final result = await getIt<BonusesRepository>().catalog(
      BonusFilters(businessId: widget.businessId, activeOnly: true, pageSize: 6),
    );
    return result.when(success: (value) => value, failure: (_) => const []);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Bonus>>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 48,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bonos activos', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ...items.map(
                (bonus) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: BonusCard(
                    bonus: bonus,
                    compact: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BonusDetailPage(bonusId: bonus.id),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
}
