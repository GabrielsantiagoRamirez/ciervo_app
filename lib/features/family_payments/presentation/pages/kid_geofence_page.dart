import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/location/location_permission_status.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/kid_parental_rules.dart';
import '../../domain/repositories/family_payments_repository.dart';

class KidGeofencePage extends StatefulWidget {
  const KidGeofencePage({required this.kidId, super.key});
  final String kidId;

  @override
  State<KidGeofencePage> createState() => _KidGeofencePageState();
}

class _KidGeofencePageState extends State<KidGeofencePage> {
  final _repository = getIt<FamilyPaymentsRepository>();
  bool _enabled = false;
  double _radius = 500;
  LatLng? _center;
  bool _loading = true;
  bool _saving = false;
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
    final result = await _repository.kidGeofence(widget.kidId);
    if (!mounted) return;
    if (!mounted) return;
    if (result case Success(value: final rules)) {
      _enabled = rules.enabled;
      _radius = rules.radiusMeters ?? 500;
      if (rules.latitude != null && rules.longitude != null) {
        _center = LatLng(rules.latitude!, rules.longitude!);
      } else {
        await _useCurrentLocation(silent: true);
      }
      setState(() => _loading = false);
    } else if (result case Failure(error: final error)) {
      setState(() {
        _loading = false;
        _error = UserErrorMessage.from(error);
      });
    }
  }

  Future<void> _useCurrentLocation({bool silent = false}) async {
    final locationService = getIt<LocationService>();
    var status = await locationService.permissionStatus();
    if (status != AppLocationPermissionStatus.granted) {
      status = await locationService.requestPermission();
    }
    if (status != AppLocationPermissionStatus.granted) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activa la ubicación para continuar.')),
        );
      }
      return;
    }
    try {
      final location = await locationService.currentLocation();
      if (!mounted) return;
      setState(() {
        _center = LatLng(location.latitude, location.longitude);
      });
    } catch (_) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos obtener tu ubicación.')),
        );
      }
    }
  }

  Future<void> _save() async {
    final center = _center;
    if (center == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un centro en el mapa.')),
      );
      return;
    }
    setState(() => _saving = true);
    final result = await _repository.saveKidGeofence(
      kidId: widget.kidId,
      geofence: KidGeofenceRules(
        enabled: _enabled,
        latitude: center.latitude,
        longitude: center.longitude,
        radiusMeters: _radius,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geocerca guardada.')),
      ),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geocerca')),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CiervoLoadingState(itemCount: 3),
            )
          : _error != null
              ? Padding(
                  padding: pagePaddingOf(context),
                  child: CiervoErrorState(
                    title: 'No pudimos cargar la geocerca',
                    description: _error!,
                    onRetry: _load,
                  ),
                )
              : ListView(
                  padding: pagePaddingOf(context),
                  children: [
                    CiervoCard(
                      child: SwitchListTile(
                        title: const Text('Geocerca activa'),
                        subtitle: const Text(
                          'Solo permite pagos dentro de la zona segura.',
                        ),
                        value: _enabled,
                        onChanged: (value) => setState(() => _enabled = value),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CiervoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 260,
                            child: _center == null
                                ? const Center(child: Text('Selecciona un centro'))
                                : GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: _center!,
                                      zoom: 14,
                                    ),
                                    circles: {
                                      Circle(
                                        circleId: const CircleId('geofence'),
                                        center: _center!,
                                        radius: _radius,
                                        fillColor: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.15),
                                        strokeColor:
                                            Theme.of(context).colorScheme.primary,
                                      ),
                                    },
                                    onTap: (position) =>
                                        setState(() => _center = position),
                                    markers: {
                                      Marker(
                                        markerId: const MarkerId('center'),
                                        position: _center!,
                                      ),
                                    },
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: _useCurrentLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Usar mi ubicación'),
                          ),
                          Text('Radio: ${_radius.toStringAsFixed(0)} m'),
                          Slider(
                            value: _radius,
                            min: 100,
                            max: 5000,
                            divisions: 49,
                            label: '${_radius.toStringAsFixed(0)} m',
                            onChanged: (value) => setState(() => _radius = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CiervoButton(
                      label: _saving ? 'Guardando...' : 'Guardar geocerca',
                      icon: Icons.save_outlined,
                      state: _saving
                          ? CiervoButtonState.loading
                          : CiervoButtonState.normal,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
    );
  }
}
