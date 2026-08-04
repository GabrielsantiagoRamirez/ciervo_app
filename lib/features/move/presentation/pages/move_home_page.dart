import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/geo/geo_autocomplete_models.dart';
import '../../../../core/geo/geo_repository.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/map_gesture_recognizers.dart';
import '../../../kids/domain/entities/child_profile.dart';
import '../../../kids/domain/repositories/kids_repository.dart';
import '../../domain/entities/move_enums.dart';
import '../../domain/entities/move_fare_quote.dart';
import '../../domain/repositories/move_repository.dart';
import '../cubit/move_passenger_cubit.dart';
import '../cubit/move_passenger_state.dart';
import '../widgets/move_category_selector.dart';
import '../widgets/move_fare_quote_card.dart';
import '../widgets/move_place_search_field.dart';
import 'move_driver_page.dart';
import 'move_kids_approvals_page.dart';
import 'move_trip_page.dart';
import 'move_trips_history_page.dart';

class MoveHomePage extends StatelessWidget {
  const MoveHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MovePassengerCubit(getIt<MoveRepository>()),
      child: const _MoveHomeView(),
    );
  }
}

class _MoveHomeView extends StatefulWidget {
  const _MoveHomeView();

  @override
  State<_MoveHomeView> createState() => _MoveHomeViewState();
}

class _MoveHomeViewState extends State<_MoveHomeView> {
  final _originController = TextEditingController(text: 'Mi ubicación');
  final _destinationController = TextEditingController();

  GoogleMapController? _mapController;
  LatLng? _origin;
  LatLng? _destination;
  MoveVehicleCategory _category = MoveVehicleCategory.standard;
  MovePaymentMethod _paymentMethod = MovePaymentMethod.wallet;
  bool _loadingLocation = true;

  List<ChildProfile> _children = const [];
  ChildProfile? _selectedChild;
  late final String _sessionToken;

  @override
  void initState() {
    super.initState();
    _sessionToken = newGeoSessionToken();
    _loadCurrentLocation();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final result = await getIt<KidsRepository>().children();
    if (!mounted) return;
    result.when(
      success: (children) => setState(
        () => _children = children.where((c) => c.isActive).toList(),
      ),
      failure: (_) {},
    );
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    final service = getIt<LocationService>();
    try {
      final status = await service.permissionStatus();
      final location = status.name == 'granted'
          ? await service.currentLocation()
          : await service.lastKnownLocation();
      if (location != null && mounted) {
        final latLng = LatLng(location.latitude, location.longitude);
        setState(() {
          _origin = latLng;
          _loadingLocation = false;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
        await _reverseGeocodeOrigin(latLng);
        return;
      }
    } catch (_) {
      // Continúa sin ubicación; el usuario puede tocar el mapa.
    }
    if (mounted) setState(() => _loadingLocation = false);
  }

  String get _countryCode {
    final origin = _origin;
    if (origin != null) {
      final inferred = CountryRegistration.inferCountryCodeFromCoordinates(
        latitude: origin.latitude,
        longitude: origin.longitude,
      );
      if (inferred != null) return inferred;
    }
    return CountryRegistration.defaultCountryCode();
  }

  double get _distanceKm {
    final o = _origin;
    final d = _destination;
    if (o == null || d == null) return 0;
    return Geolocator.distanceBetween(
          o.latitude,
          o.longitude,
          d.latitude,
          d.longitude,
        ) /
        1000;
  }

  int get _durationMin => math.max(5, (_distanceKm / 25 * 60).round());

  MoveFareRequest _buildFareRequest() {
    final hour = DateTime.now().hour;
    final context = CountryRegistration.contextForCode(_countryCode);
    return MoveFareRequest(
      countryCode: _countryCode,
      city: context.city,
      vehicleCategory: _category,
      distanceKm: double.parse(_distanceKm.toStringAsFixed(2)),
      durationMin: _durationMin,
      isNight: hour >= 20 || hour < 6,
    );
  }

  Future<void> _reverseGeocodeOrigin(LatLng position) async {
    final result = await getIt<GeoRepository>().reverse(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (!mounted) return;
    result.when(
      success: (geocode) {
        if (geocode.displayLine.isNotEmpty) {
          _originController.text = geocode.displayLine;
        }
      },
      failure: (_) {},
    );
  }

  Future<void> _reverseGeocodeDestination(LatLng position) async {
    setState(() => _destination = position);
    final result = await getIt<GeoRepository>().reverse(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (!mounted) return;
    result.when(
      success: (geocode) {
        _destinationController.text = geocode.displayLine.isNotEmpty
            ? geocode.displayLine
            : _coordsLabel(position);
      },
      failure: (_) => _destinationController.text = _coordsLabel(position),
    );
  }

  String _coordsLabel(LatLng position) =>
      'Lat ${position.latitude.toStringAsFixed(5)}, '
      'Lng ${position.longitude.toStringAsFixed(5)}';

  void _onMapTap(LatLng position) => _reverseGeocodeDestination(position);

  void _onOriginResolved(GeoPlaceDetails place) {
    final latLng = LatLng(place.latitude, place.longitude);
    setState(() => _origin = latLng);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
  }

  void _onDestinationResolved(GeoPlaceDetails place) {
    final latLng = LatLng(place.latitude, place.longitude);
    setState(() => _destination = latLng);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
  }

  void _estimate() {
    if (_origin == null || _destination == null) {
      _snack('Selecciona el destino tocando el mapa.');
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<MovePassengerCubit>().estimateFare(_buildFareRequest());
  }

  Future<void> _request() async {
    final origin = _origin;
    final destination = _destination;
    if (origin == null || destination == null) {
      _snack('Selecciona origen y destino.');
      return;
    }
    if (_destinationController.text.trim().isEmpty) {
      _snack('Ingresa la dirección de destino.');
      return;
    }
    final cubit = context.read<MovePassengerCubit>();
    final child = _selectedChild;
    final tripId = await cubit.requestTrip(
      fare: _buildFareRequest(),
      originLat: origin.latitude,
      originLng: origin.longitude,
      originAddress: _originController.text.trim(),
      destLat: destination.latitude,
      destLng: destination.longitude,
      destAddress: _destinationController.text.trim(),
      // Los viajes Kids se cobran siempre de la wallet del tutor.
      paymentMethod: child != null ? MovePaymentMethod.wallet : _paymentMethod,
      childProfileId: child?.id,
    );
    if (tripId != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => MoveTripPage(tripId: tripId)),
      );
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ciervo Move'),
        actions: [
          IconButton(
            tooltip: 'Aprobaciones Kids',
            icon: const Icon(Icons.verified_user_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MoveKidsApprovalsPage(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Historial',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MoveTripsHistoryPage(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Modo conductor',
            icon: const Icon(Icons.drive_eta_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MoveDriverPage()),
            ),
          ),
        ],
      ),
      body: BlocConsumer<MovePassengerCubit, MovePassengerState>(
        listener: (context, state) {
          final error = state.errorMessage;
          final success = state.successMessage;
          if (error != null) {
            _snack(error);
            context.read<MovePassengerCubit>().clearQuote();
          } else if (success != null) {
            _snack(success);
          }
        },
        builder: (context, state) {
          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              _MapCard(
                origin: _origin,
                destination: _destination,
                loading: _loadingLocation,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_origin != null) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(_origin!, 14),
                    );
                  }
                },
                onTap: _onMapTap,
                onRecenter: _loadCurrentLocation,
              ),
              const SizedBox(height: AppSpacing.md),
              CiervoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MovePlaceSearchField(
                      controller: _originController,
                      label: 'Origen',
                      prefixIcon: Icons.my_location,
                      sessionToken: _sessionToken,
                      biasLatitude: _origin?.latitude,
                      biasLongitude: _origin?.longitude,
                      countryCode: _countryCode,
                      onPlaceResolved: _onOriginResolved,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    MovePlaceSearchField(
                      controller: _destinationController,
                      label: 'Destino',
                      prefixIcon: Icons.place_outlined,
                      hintText: 'Toca el mapa o escribe la dirección',
                      sessionToken: _sessionToken,
                      biasLatitude: _origin?.latitude,
                      biasLongitude: _origin?.longitude,
                      countryCode: _countryCode,
                      onPlaceResolved: _onDestinationResolved,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Categoría', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              MoveCategorySelector(
                selected: _category,
                onChanged: (value) {
                  setState(() => _category = value);
                  context.read<MovePassengerCubit>().clearQuote();
                },
              ),
              if (_children.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _ChildSelector(
                  children: _children,
                  selected: _selectedChild,
                  onChanged: (value) => setState(() => _selectedChild = value),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (_selectedChild != null)
                CiervoCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'El viaje se cobrará de tu wallet. Si lo solicita el '
                          'menor, quedará pendiente de tu aprobación.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )
              else
                _PaymentMethodSelector(
                  selected: _paymentMethod,
                  onChanged: (value) => setState(() => _paymentMethod = value),
                ),
              if (_distanceKm > 0) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Distancia estimada: ${_distanceKm.toStringAsFixed(1)} km · '
                  '~$_durationMin min',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              CiervoButton(
                label: 'Estimar tarifa',
                icon: Icons.calculate_outlined,
                variant: CiervoButtonVariant.secondary,
                state: state.status == MovePassengerStatus.estimating
                    ? CiervoButtonState.loading
                    : CiervoButtonState.normal,
                onPressed: _estimate,
              ),
              if (state.quote != null) ...[
                const SizedBox(height: AppSpacing.md),
                MoveFareQuoteCard(quote: state.quote!),
              ],
              const SizedBox(height: AppSpacing.md),
              CiervoButton(
                label: 'Solicitar viaje',
                icon: Icons.local_taxi_outlined,
                state: state.status == MovePassengerStatus.requesting
                    ? CiervoButtonState.loading
                    : CiervoButtonState.normal,
                onPressed: _request,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.origin,
    required this.destination,
    required this.loading,
    required this.onMapCreated,
    required this.onTap,
    required this.onRecenter,
  });

  final LatLng? origin;
  final LatLng? destination;
  final bool loading;
  final ValueChanged<GoogleMapController> onMapCreated;
  final ValueChanged<LatLng> onTap;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{
      if (origin != null)
        Marker(
          markerId: const MarkerId('origin'),
          position: origin!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Origen'),
        ),
      if (destination != null)
        Marker(
          markerId: const MarkerId('destination'),
          position: destination!,
          infoWindow: const InfoWindow(title: 'Destino'),
        ),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 260,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: origin ?? const LatLng(4.6097, -74.0817),
                zoom: 13,
              ),
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              gestureRecognizers: mapEagerGestureRecognizers,
              onMapCreated: onMapCreated,
              onTap: onTap,
            ),
            if (loading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            Positioned(
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: FloatingActionButton.small(
                heroTag: 'move-recenter',
                onPressed: onRecenter,
                child: const Icon(Icons.gps_fixed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildSelector extends StatelessWidget {
  const _ChildSelector({
    required this.children,
    required this.selected,
    required this.onChanged,
  });

  final List<ChildProfile> children;
  final ChildProfile? selected;
  final ValueChanged<ChildProfile?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Para quién es el viaje?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: selected?.id ?? '',
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.person_outline),
          ),
          items: [
            const DropdownMenuItem(value: '', child: Text('Para mí')),
            ...children.map(
              (child) => DropdownMenuItem(
                value: child.id,
                child: Text(child.fullName),
              ),
            ),
          ],
          onChanged: (value) {
            if (value == null || value.isEmpty) {
              onChanged(null);
              return;
            }
            onChanged(children.firstWhere((c) => c.id == value));
          },
        ),
      ],
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  const _PaymentMethodSelector({
    required this.selected,
    required this.onChanged,
  });

  final MovePaymentMethod selected;
  final ValueChanged<MovePaymentMethod> onChanged;

  static const _methods = [
    MovePaymentMethod.wallet,
    MovePaymentMethod.cash,
    MovePaymentMethod.card,
    MovePaymentMethod.pin,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pago', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Elige wallet, efectivo, tarjeta (física/digital), PIN o @.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            ..._methods.map((method) {
              return ChoiceChip(
                selected: method == selected,
                onSelected: (_) => onChanged(method),
                avatar: Icon(_iconFor(method), size: 18),
                label: Text(_labelFor(method)),
              );
            }),
          ],
        ),
      ],
    );
  }

  String _labelFor(MovePaymentMethod method) => switch (method) {
    MovePaymentMethod.wallet => 'Wallet Ciervo',
    MovePaymentMethod.cash => 'Efectivo',
    MovePaymentMethod.card => 'Tarjeta física/digital',
    MovePaymentMethod.pin => 'PIN / @',
    MovePaymentMethod.qr => 'QR',
    MovePaymentMethod.points => 'Puntos',
  };

  IconData _iconFor(MovePaymentMethod method) => switch (method) {
    MovePaymentMethod.wallet => Icons.account_balance_wallet_outlined,
    MovePaymentMethod.cash => Icons.payments_outlined,
    MovePaymentMethod.card => Icons.credit_card,
    MovePaymentMethod.pin => Icons.password_outlined,
    MovePaymentMethod.qr => Icons.qr_code_2,
    MovePaymentMethod.points => Icons.stars_outlined,
  };
}
