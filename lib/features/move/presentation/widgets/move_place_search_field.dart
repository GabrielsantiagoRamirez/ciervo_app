import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/geo/geo_autocomplete_models.dart';
import '../../../../core/geo/geo_repository.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../wallet/presentation/widgets/ciervo_digital_card.dart';

/// Campo de origen/destino Move con autocomplete + resolución de placeId.
class MovePlaceSearchField extends StatefulWidget {
  const MovePlaceSearchField({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    required this.sessionToken,
    required this.onPlaceResolved,
    this.biasLatitude,
    this.biasLongitude,
    this.countryCode,
    this.hintText,
    this.onFocusChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final String sessionToken;
  final void Function(GeoPlaceDetails place) onPlaceResolved;
  final double? biasLatitude;
  final double? biasLongitude;
  final String? countryCode;
  final String? hintText;
  final ValueChanged<bool>? onFocusChanged;

  @override
  State<MovePlaceSearchField> createState() => _MovePlaceSearchFieldState();
}

class _MovePlaceSearchFieldState extends State<MovePlaceSearchField> {
  final _focus = FocusNode();
  final _geo = getIt<GeoRepository>();
  Timer? _debounce;
  List<GeoAutocompleteItem> _suggestions = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      widget.onFocusChanged?.call(_focus.hasFocus);
      if (!_focus.hasFocus) {
        // Pequeño delay para permitir el tap en sugerencia.
        Future<void>.delayed(const Duration(milliseconds: 180), () {
          if (mounted && !_focus.hasFocus) {
            setState(() => _suggestions = const []);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _suggestions = const [];
        _error = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _geo.autocomplete(
      query: query,
      latitude: widget.biasLatitude,
      longitude: widget.biasLongitude,
      radiusKm: 30,
      country: widget.countryCode,
      limit: 8,
      sessionToken: widget.sessionToken,
    );
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _suggestions = items;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _suggestions = const [];
        _loading = false;
        final msg = UserErrorMessage.from(error);
        _error = msg.toLowerCase().contains('solicitud')
            ? 'No pudimos buscar esa dirección. Escribe al menos 2 caracteres.'
            : msg;
      }),
    );
  }

  Future<void> _select(GeoAutocompleteItem item) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _suggestions = const [];
      _loading = true;
    });

    // Si Nominatim ya trae coords, úsalas; si no, pide place details.
    if (item.hasCoordinates && item.placeId.isEmpty) {
      final place = GeoPlaceDetails(
        latitude: item.latitude!,
        longitude: item.longitude!,
        formattedAddress: item.description,
        name: item.mainText,
      );
      widget.controller.text = place.displayAddress;
      widget.onPlaceResolved(place);
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (item.placeId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final result = await _geo.placeDetails(
      placeId: item.placeId,
      sessionToken: widget.sessionToken,
    );
    if (!mounted) return;
    result.when(
      success: (place) {
        widget.controller.text = place.displayAddress;
        widget.onPlaceResolved(place);
        setState(() => _loading = false);
      },
      failure: (error) {
        // Fallback: coords en el item autocomplete (si existen).
        if (item.hasCoordinates) {
          final place = GeoPlaceDetails(
            latitude: item.latitude!,
            longitude: item.longitude!,
            formattedAddress: item.description,
            name: item.mainText,
            placeId: item.placeId,
          );
          widget.controller.text = place.displayAddress;
          widget.onPlaceResolved(place);
          setState(() => _loading = false);
          return;
        }
        setState(() {
          _loading = false;
          _error = UserErrorMessage.from(error);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            prefixIcon: Icon(widget.prefixIcon),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (widget.controller.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Limpiar',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            widget.controller.clear();
                            setState(() => _suggestions = const []);
                          },
                        )
                      : null),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: CiervoBrandColors.gold,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.place_outlined,
                    color: CiervoBrandColors.gold,
                  ),
                  title: Text(
                    item.primaryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: item.secondaryLabel.isEmpty
                      ? null
                      : Text(
                          item.secondaryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  onTap: () => _select(item),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

String newGeoSessionToken() {
  final r = Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  final h = bytes.map(hex).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
      '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}
