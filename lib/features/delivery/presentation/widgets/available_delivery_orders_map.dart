import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/entities/delivery_models.dart';

class AvailableDeliveryOrdersMap extends StatelessWidget {
  const AvailableDeliveryOrdersMap({
    required this.orders,
    required this.onSelect,
    super.key,
  });

  final List<AvailableDeliveryOrder> orders;
  final ValueChanged<AvailableDeliveryOrder> onSelect;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('No hay pedidos en el mapa.'));
    }

    final markers = <Marker>{};
    LatLng? firstPoint;
    for (final order in orders) {
      if (order.pickupLatitude != null && order.pickupLongitude != null) {
        final pickup = LatLng(order.pickupLatitude!, order.pickupLongitude!);
        firstPoint ??= pickup;
        markers.add(
          Marker(
            markerId: MarkerId('pickup-${order.id}'),
            position: pickup,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(
              title: order.businessName,
              snippet:
                  'Recogida · ${order.distanceKm?.toStringAsFixed(1) ?? '?'} km',
              onTap: () => onSelect(order),
            ),
          ),
        );
      }
      if (order.deliveryLatitude != null && order.deliveryLongitude != null) {
        final delivery = LatLng(
          order.deliveryLatitude!,
          order.deliveryLongitude!,
        );
        firstPoint ??= delivery;
        markers.add(
          Marker(
            markerId: MarkerId('delivery-${order.id}'),
            position: delivery,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: 'Entrega',
              snippet: order.deliveryAddress,
              onTap: () => onSelect(order),
            ),
          ),
        );
      }
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: firstPoint ?? const LatLng(4.6097, -74.0817),
        zoom: 12,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onTap: (_) {},
    );
  }
}
