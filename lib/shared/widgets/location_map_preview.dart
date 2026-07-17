import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/di/service_locator.dart';
import '../../core/geo/geo_repository.dart';
import '../../core/theme/app_spacing.dart';

/// Vista previa de mapa real (Google Maps en modo lite) con la dirección
/// resuelta vía `/api/geo/reverse`. Al tocarla abre Google Maps externo.
class LocationMapPreview extends StatefulWidget {
  const LocationMapPreview({
    required this.latitude,
    required this.longitude,
    this.height = 120,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(14)),
    this.showAddressLabel = true,
    super.key,
  });

  final double latitude;
  final double longitude;
  final double height;
  final BorderRadius borderRadius;
  final bool showAddressLabel;

  @override
  State<LocationMapPreview> createState() => _LocationMapPreviewState();
}

class _LocationMapPreviewState extends State<LocationMapPreview> {
  String? _address;
  String? _mapsUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final result = await getIt<GeoRepository>().reverse(
      latitude: widget.latitude,
      longitude: widget.longitude,
    );
    if (!mounted) return;
    result.when(
      success: (geo) => setState(() {
        _loading = false;
        _address = geo.displayLine.isNotEmpty
            ? geo.displayLine
            : '${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}';
        _mapsUrl = geo.mapsUrl;
      }),
      failure: (_) => setState(() {
        _loading = false;
        _address =
            '${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}';
      }),
    );
  }

  Future<void> _openMaps() async {
    final url = _mapsUrl;
    if (url == null || url.isEmpty) {
      final fallback = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}',
      );
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final target = LatLng(widget.latitude, widget.longitude);
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: target, zoom: 15),
              liteModeEnabled: true,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('location'),
                  position: target,
                ),
              },
              onTap: (_) => _openMaps(),
            ),
            if (widget.showAddressLabel)
              Positioned(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: Material(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _openMaps,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _loading
                                ? 'Obteniendo dirección…'
                                : (_address ?? ''),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        const Icon(Icons.open_in_new, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
