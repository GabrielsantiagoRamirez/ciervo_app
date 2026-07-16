import 'package:flutter/material.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../data/booking_repository.dart';
import '../widgets/business_reservation_sheet.dart';

class NewReservationPage extends StatefulWidget {
  const NewReservationPage({super.key});

  @override
  State<NewReservationPage> createState() => _NewReservationPageState();
}

class _NewReservationPageState extends State<NewReservationPage> {
  final _bookingRepository = getIt<BookingRepository>();
  final _locationService = getIt<LocationService>();
  final _profileRepository = getIt<ProfileRepository>();

  bool _loading = true;
  String? _error;
  List<ReservableBusinessCatalogItem> _items = const [];
  String _countryCode = CountryRegistration.defaultCountryCode();
  String _city = CountryRegistration.defaultContext().city;

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

    try {
      await _resolveCountryContext();
      double? latitude;
      double? longitude;
      try {
        final location = await _locationService.currentLocation();
        latitude = location.latitude;
        longitude = location.longitude;
      } catch (_) {
        // El listado también funciona por país/ciudad sin permiso GPS.
      }
      final result = await _bookingRepository.getReservableBusinesses(
        countryCode: _countryCode,
        city: _city,
        latitude: latitude,
        longitude: longitude,
      );
      final reservable = result.when(
        success: (items) => items,
        failure: (error) => throw error,
      );
      if (!mounted) return;
      setState(() {
        _items = reservable;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = UserErrorMessage.from(error);
        _loading = false;
      });
    }
  }

  Future<void> _resolveCountryContext() async {
    final profileResult = await _profileRepository.getMe();
    profileResult.when(
      success: (profile) {
        final code = (profile.countryCode ?? '').trim().toUpperCase();
        final city = (profile.city ?? '').trim();
        if (code.isNotEmpty) {
          _countryCode = code;
        }
        _city = city.isNotEmpty
            ? city
            : CountryRegistration.contextForCode(
                code.isNotEmpty ? code : _countryCode,
              ).city;
      },
      failure: (_) {},
    );
  }

  Future<void> _openReservation(ReservableBusinessCatalogItem item) async {
    final booking = await showBusinessReservationSheet(
      context,
      businessId: item.id,
      businessName: item.name,
      options: item.options,
    );
    if (booking != null && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva reserva')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  CiervoBrandLoader(message: 'Buscando comercios con reservas'),
                ],
              )
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
              )
            : _items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: const [
                  CiervoEmptyState(
                    title: 'Sin comercios reservables',
                    description:
                        'No encontramos negocios con reservas disponibles '
                        'cerca de ti ahora. Intenta más tarde o en otra zona.',
                    icon: Icons.event_busy_outlined,
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _items.length + 1,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Text(
                      'Comercios con reservas disponibles. '
                      'Verás si piden pago anticipado antes de confirmar.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  }
                  final item = _items[index - 1];
                  return _ReservableBusinessCard(
                    item: item,
                    onTap: () => _openReservation(item),
                  );
                },
              ),
      ),
    );
  }
}

class _ReservableBusinessCard extends StatelessWidget {
  const _ReservableBusinessCard({required this.item, required this.onTap});

  final ReservableBusinessCatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final prepaidCount = item.options
        .where((option) => option.requiresPrepayment)
        .length;
    final freeCount = item.options.length - prepaidCount;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: CiervoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                [
                  if (item.category.isNotEmpty) item.category,
                  if (item.distanceKm > 0)
                    '${item.distanceKm.toStringAsFixed(1)} km',
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('${item.options.length} opciones'),
                  ),
                  if (prepaidCount > 0)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.payments_outlined, size: 16),
                      label: Text(
                        prepaidCount == 1
                            ? 'Con pago anticipado'
                            : '$prepaidCount con anticipo',
                      ),
                    ),
                  if (freeCount > 0)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(
                        Icons.event_available_outlined,
                        size: 16,
                      ),
                      label: Text(
                        freeCount == 1
                            ? 'Sin anticipo'
                            : '$freeCount sin anticipo',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...item.options
                  .take(3)
                  .map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${option.displayName} — ${option.paymentLabel()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
              if (item.options.length > 3)
                Text(
                  '+${item.options.length - 3} más',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Reservar',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
