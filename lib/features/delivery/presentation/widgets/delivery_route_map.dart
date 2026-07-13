import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_spacing.dart';

/// Mapa de ruta delivery: comercio, entrega y domiciliario (estilo Rappi/Uber Eats).
class DeliveryRouteMap extends StatefulWidget {
  const DeliveryRouteMap({
    this.pickup,
    this.delivery,
    this.courier,
    this.height = 220,
    this.showNavigateButtons = false,
    super.key,
  });

  final LatLng? pickup;
  final LatLng? delivery;
  final LatLng? courier;
  final double height;
  final bool showNavigateButtons;

  @override
  State<DeliveryRouteMap> createState() => _DeliveryRouteMapState();
}

class _DeliveryRouteMapState extends State<DeliveryRouteMap> {
  GoogleMapController? _controller;
  Set<Marker> _markers = const {};

  @override
  void didUpdateWidget(covariant DeliveryRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickup != widget.pickup ||
        oldWidget.delivery != widget.delivery ||
        oldWidget.courier != widget.courier) {
      _syncMarkers();
      _fitBounds();
    }
  }

  @override
  void initState() {
    super.initState();
    _syncMarkers();
  }

  void _syncMarkers() {
    final markers = <Marker>{};
    if (widget.pickup case final pickup?) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Comercio'),
        ),
      );
    }
    if (widget.delivery case final delivery?) {
      markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: delivery,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Entrega'),
        ),
      );
    }
    if (widget.courier case final courier?) {
      markers.add(
        Marker(
          markerId: const MarkerId('courier'),
          position: courier,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: const InfoWindow(title: 'Domiciliario'),
        ),
      );
    }
    setState(() => _markers = markers);
  }

  Future<void> _fitBounds() async {
    final controller = _controller;
    if (controller == null) return;
    final points = [
      if (widget.pickup != null) widget.pickup!,
      if (widget.delivery != null) widget.delivery!,
      if (widget.courier != null) widget.courier!,
    ];
    if (points.isEmpty) return;
    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 14),
      );
      return;
    }
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points.skip(1)) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
  }

  Future<void> _openNavigation(LatLng target) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${target.latitude},${target.longitude}&travelmode=driving',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        widget.delivery ??
        widget.pickup ??
        widget.courier ??
        const LatLng(4.6097, -74.0817);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: initial, zoom: 13),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (controller) async {
                _controller = controller;
                await _fitBounds();
              },
            ),
          ),
        ),
        if (widget.showNavigateButtons) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              if (widget.pickup case final pickup?)
                OutlinedButton.icon(
                  onPressed: () => _openNavigation(pickup),
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: const Text('Ir al comercio'),
                ),
              if (widget.delivery case final delivery?)
                OutlinedButton.icon(
                  onPressed: () => _openNavigation(delivery),
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: const Text('Ir a entrega'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
