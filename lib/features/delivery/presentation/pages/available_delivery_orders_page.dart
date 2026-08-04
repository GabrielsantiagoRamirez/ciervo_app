import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../domain/entities/delivery_models.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../widgets/available_delivery_orders_map.dart';
import '../widgets/delivery_pricing_card.dart';
import 'delivery_order_detail_page.dart';

class AvailableDeliveryOrdersPage extends StatefulWidget {
  const AvailableDeliveryOrdersPage({super.key});

  @override
  State<AvailableDeliveryOrdersPage> createState() =>
      _AvailableDeliveryOrdersPageState();
}

class _AvailableDeliveryOrdersPageState
    extends State<AvailableDeliveryOrdersPage> {
  List<AvailableDeliveryOrder> _orders = const [];
  DeliveryProfile? _profile;
  bool _loading = true;
  String? _claimingId;
  String? _error;
  double? _courierLat;
  double? _courierLng;

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
    final repository = getIt<DeliveryRepository>();
    await _resolveCourierLocation();
    final profileResult = await repository.me();
    final result = await repository.availableOrders();
    if (!mounted) return;
    profileResult.when(
      success: (profile) => _profile = profile,
      failure: (_) => _profile = null,
    );
    result.when(
      success: (orders) => setState(() {
        _orders = orders;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      }),
    );
  }

  Future<void> _resolveCourierLocation() async {
    try {
      final location = await getIt<LocationService>().currentLocation();
      _courierLat = location.latitude;
      _courierLng = location.longitude;
    } catch (_) {
      _courierLat ??= _profile?.lastLatitude;
      _courierLng ??= _profile?.lastLongitude;
    }
  }

  /// Distancia en km desde el domiciliario hasta el punto de recogida.
  double? _distanceToPickup(AvailableDeliveryOrder order) {
    final lat = _courierLat;
    final lng = _courierLng;
    final pickupLat = order.pickupLatitude;
    final pickupLng = order.pickupLongitude;
    if (lat == null || lng == null || pickupLat == null || pickupLng == null) {
      return null;
    }
    return Geolocator.distanceBetween(lat, lng, pickupLat, pickupLng) / 1000;
  }

  /// Distancia del trayecto (recogida → entrega).
  double? _tripDistance(AvailableDeliveryOrder order) {
    if (order.distanceKm != null) return order.distanceKm;
    final pickupLat = order.pickupLatitude;
    final pickupLng = order.pickupLongitude;
    final dropLat = order.deliveryLatitude;
    final dropLng = order.deliveryLongitude;
    if (pickupLat == null ||
        pickupLng == null ||
        dropLat == null ||
        dropLng == null) {
      return null;
    }
    return Geolocator.distanceBetween(pickupLat, pickupLng, dropLat, dropLng) /
        1000;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Domicilios disponibles'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list), text: 'Lista'),
              Tab(icon: Icon(Icons.map_outlined), text: 'Mapa'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(context),
            AvailableDeliveryOrdersMap(orders: _orders, onSelect: _claim),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) => _loading
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          onRefresh: _load,
          child: _orders.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    CiervoEmptyState(
                      title: 'Sin domicilios disponibles',
                      description:
                          _error ?? 'Los pedidos aprobados apareceran aqui.',
                      icon: Icons.delivery_dining_outlined,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _orders.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final canClaim =
                        _profile?.isSettlementAccountVerified == true;
                    return CiervoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.businessName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _AddressLine(
                            icon: Icons.store_mall_directory_outlined,
                            label: 'Recogida',
                            address: order.businessAddress,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _AddressLine(
                            icon: Icons.flag_outlined,
                            label: 'Entrega',
                            address: order.deliveryAddress,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _DistanceChips(
                            toPickupKm: _distanceToPickup(order),
                            tripKm: _tripDistance(order),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DeliveryPricingCard(
                            pricing: order.effectivePricing,
                            currency: order.currency ?? 'COP',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (!canClaim)
                            const Padding(
                              padding: EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Text(
                                'Necesitas una cuenta de liquidacion aprobada para aceptar domicilios.',
                              ),
                            ),
                          CiervoButton(
                            label: 'Aceptar domicilio',
                            icon: Icons.check,
                            state: _claimingId == order.id
                                ? CiervoButtonState.loading
                                : CiervoButtonState.normal,
                            onPressed: canClaim && _claimingId == null
                                ? () => _claim(order)
                                : null,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );

  Future<void> _claim(AvailableDeliveryOrder order) async {
    if (_profile?.isSettlementAccountVerified != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tu cuenta de liquidacion debe estar aprobada para reclamar domicilios.',
          ),
        ),
      );
      return;
    }
    setState(() => _claimingId = order.id);
    final result = await getIt<DeliveryRepository>().claimOrder(order.id);
    if (!mounted) return;
    setState(() => _claimingId = null);
    result.when(
      success: (claimed) async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DeliveryOrderDetailPage(orderId: claimed.id),
          ),
        );
        _load();
      },
      failure: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
        _load();
      },
    );
  }
}

class _AddressLine extends StatelessWidget {
  const _AddressLine({
    required this.icon,
    required this.label,
    required this.address,
  });

  final IconData icon;
  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                address.isEmpty ? 'Sin dirección' : address,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DistanceChips extends StatelessWidget {
  const _DistanceChips({this.toPickupKm, this.tripKm});

  final double? toPickupKm;
  final double? tripKm;

  String _format(double km) =>
      km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    if (toPickupKm == null && tripKm == null) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        if (toPickupKm != null)
          _chip(
            context,
            Icons.directions_walk,
            'A ${_format(toPickupKm!)} de la recogida',
          ),
        if (tripKm != null)
          _chip(context, Icons.route_outlined, 'Trayecto ${_format(tripKm!)}'),
      ],
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xxs),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
