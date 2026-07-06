import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/geo/geo_repository.dart';
import '../../../../core/location/location_permission_status.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';

/// Selector de dirección estilo Rappi: mapa con pin central + búsqueda.
class DeliveryAddressMapPicker extends StatefulWidget {
  const DeliveryAddressMapPicker({
    required this.initialPosition,
    this.height = 280,
    this.onChanged,
    super.key,
  });

  final LatLng initialPosition;
  final double height;
  final void Function(LatLng position, String address)? onChanged;

  @override
  State<DeliveryAddressMapPicker> createState() =>
      _DeliveryAddressMapPickerState();
}

class _DeliveryAddressMapPickerState extends State<DeliveryAddressMapPicker> {
  final _searchController = TextEditingController();
  final _geo = getIt<GeoRepository>();
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(4.6097, -74.0817);
  String _address = '';
  bool _loadingAddress = true;
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _center = widget.initialPosition;
    _reverseGeocode(_center);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng position) async {
    setState(() => _loadingAddress = true);
    final result = await _geo.reverse(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (!mounted) return;
    result.when(
      success: (geo) {
        final line = geo.displayLine.isNotEmpty
            ? geo.displayLine
            : (geo.formattedAddress ?? '');
        setState(() {
          _center = position;
          _address = line;
          _loadingAddress = false;
        });
        widget.onChanged?.call(_center, _address);
      },
      failure: (_) => setState(() {
        _address =
            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        _loadingAddress = false;
      }),
    );
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.length < 4) return;
    setState(() => _searching = true);
    final result = await _geo.geocodeAddress(query);
    if (!mounted) return;
    setState(() => _searching = false);
    result.when(
      success: (geo) async {
        final lat = geo.latitude;
        final lng = geo.longitude;
        if (lat == null || lng == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No encontramos coordenadas para esa dirección.')),
          );
          return;
        }
        final target = LatLng(lat, lng);
        await _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(target, 16),
        );
        await _reverseGeocode(target);
      },
      failure: (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No encontramos esa dirección.')),
        );
      },
    );
  }

  Future<void> _useMyLocation() async {
    final locationService = getIt<LocationService>();
    var status = await locationService.permissionStatus();
    if (status != AppLocationPermissionStatus.granted) {
      status = await locationService.requestPermission();
    }
    if (status != AppLocationPermissionStatus.granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa la ubicación para continuar.')),
      );
      return;
    }
    try {
      final location = await locationService.currentLocation();
      final target = LatLng(location.latitude, location.longitude);
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 16),
      );
      await _reverseGeocode(target);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos obtener tu ubicación.')),
      );
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (value.trim().length >= 4) _searchAddress();
    });
  }

  LatLng get selectedPosition => _center;
  String get selectedAddress => _address;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Buscar dirección',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _searchAddress,
                  ),
          ),
          onSubmitted: (_) => _searchAddress(),
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 15,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (controller) => _mapController = controller,
                onCameraIdle: () async {
                  final controller = _mapController;
                  if (controller == null) return;
                  final bounds = await controller.getVisibleRegion();
                  final lat = (bounds.northeast.latitude +
                          bounds.southwest.latitude) /
                      2;
                  final lng = (bounds.northeast.longitude +
                          bounds.southwest.longitude) /
                      2;
                  await _reverseGeocode(LatLng(lat, lng));
                },
              ),
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 36),
                  child: Icon(
                    Icons.location_on,
                    size: 42,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              Positioned(
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: FloatingActionButton.small(
                  heroTag: 'delivery-map-my-location',
                  onPressed: _useMyLocation,
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                _loadingAddress
                    ? 'Obteniendo dirección…'
                    : (_address.isEmpty ? 'Mueve el mapa al punto de entrega' : _address),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: CiervoButton(
            label: 'Usar mi ubicación',
            icon: Icons.my_location,
            variant: CiervoButtonVariant.secondary,
            onPressed: _useMyLocation,
          ),
        ),
      ],
    );
  }
}
