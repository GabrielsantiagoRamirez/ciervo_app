import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/sync/home_feed_refresh.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../domain/entities/bonus.dart';
import '../../domain/repositories/bonuses_repository.dart';
import '../pages/bonus_detail_page.dart';
import '../widgets/bonus_card.dart';

class HomeBonusesSection extends StatefulWidget {
  const HomeBonusesSection({
    required this.title,
    required this.onlyFavorites,
    this.country,
    this.city,
    super.key,
  });

  final String title;
  final bool onlyFavorites;
  final String? country;
  final String? city;

  @override
  State<HomeBonusesSection> createState() => _HomeBonusesSectionState();
}

class _HomeBonusesSectionState extends State<HomeBonusesSection> {
  late Future<List<Bonus>> _items;
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

  Future<List<Bonus>> _load() async {
    double? lat;
    double? lng;
    try {
      final location = await getIt<LocationService>().currentLocation();
      lat = location.latitude;
      lng = location.longitude;
    } catch (_) {}

    final result = await getIt<BonusesRepository>().catalog(
      BonusFilters(
        country: widget.country,
        city: widget.city,
        nearLat: lat,
        nearLng: lng,
        radiusKm: lat == null ? null : 25,
        onlyFavorites: widget.onlyFavorites,
        activeOnly: true,
        pageSize: 8,
      ),
    );
    return result.when(
      success: (value) => value,
      failure: (_) => const [],
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Bonus>>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 120,
              child: CiervoBrandLoader(message: 'Cargando bonos', compact: true),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BonusesCatalogPage(
                          onlyFavorites: widget.onlyFavorites,
                          country: widget.country,
                          city: widget.city,
                        ),
                      ),
                    ),
                    child: const Text('Ver todos'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) => SizedBox(
                    width: 280,
                    child: BonusCard(
                      bonus: items[index],
                      compact: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BonusDetailPage(bonusId: items[index].id),
                        ),
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

class BonusesCatalogPage extends StatefulWidget {
  const BonusesCatalogPage({
    this.onlyFavorites = false,
    this.businessId,
    this.country,
    this.city,
    super.key,
  });

  final bool onlyFavorites;
  final String? businessId;
  final String? country;
  final String? city;

  @override
  State<BonusesCatalogPage> createState() => _BonusesCatalogPageState();
}

class _BonusesCatalogPageState extends State<BonusesCatalogPage> {
  final _items = <Bonus>[];
  var _loading = true;
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
    final result = await getIt<BonusesRepository>().catalog(
      BonusFilters(
        onlyFavorites: widget.onlyFavorites,
        businessId: widget.businessId,
        country: widget.country,
        city: widget.city,
        activeOnly: true,
      ),
    );
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _items
          ..clear()
          ..addAll(items);
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.onlyFavorites ? 'Bonos de favoritos' : 'Bonos'),
          actions: [
            IconButton(
              icon: const Icon(Icons.card_giftcard_outlined),
              tooltip: 'Mis bonos',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MyBonusesPage()),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: _body(),
        ),
      );

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(_error!, textAlign: TextAlign.center),
          TextButton(onPressed: _load, child: const Text('Reintentar')),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          Text('No hay bonos disponibles por ahora.', textAlign: TextAlign.center),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => BonusCard(
        bonus: _items[index],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BonusDetailPage(bonusId: _items[index].id),
          ),
        ),
      ),
    );
  }
}

class MyBonusesPage extends StatefulWidget {
  const MyBonusesPage({super.key});

  @override
  State<MyBonusesPage> createState() => _MyBonusesPageState();
}

class _MyBonusesPageState extends State<MyBonusesPage> {
  final _items = <Bonus>[];
  var _loading = true;
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
    final result = await getIt<BonusesRepository>().myBonuses();
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _items
          ..clear()
          ..addAll(items);
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Mis bonos'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Historial',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BonusHistoryPage(),
                ),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: _body(),
        ),
      );

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(_error!, textAlign: TextAlign.center),
          TextButton(onPressed: _load, child: const Text('Reintentar')),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          Text('Aun no tienes bonos reclamados.', textAlign: TextAlign.center),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => BonusCard(
        bonus: _items[index],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BonusDetailPage(bonusId: _items[index].id),
          ),
        ),
      ),
    );
  }
}

class BonusHistoryPage extends StatefulWidget {
  const BonusHistoryPage({super.key});

  @override
  State<BonusHistoryPage> createState() => _BonusHistoryPageState();
}

class _BonusHistoryPageState extends State<BonusHistoryPage> {
  final _items = <Bonus>[];
  var _loading = true;
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
    final result = await getIt<BonusesRepository>().history();
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _items
          ..clear()
          ..addAll(items);
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Historial de bonos')),
        body: RefreshIndicator(
          onRefresh: _load,
          child: _body(),
        ),
      );

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(_error!, textAlign: TextAlign.center),
          TextButton(onPressed: _load, child: const Text('Reintentar')),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          Text('Sin historial de bonos.', textAlign: TextAlign.center),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => BonusCard(
        bonus: _items[index],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BonusDetailPage(bonusId: _items[index].id),
          ),
        ),
      ),
    );
  }
}
