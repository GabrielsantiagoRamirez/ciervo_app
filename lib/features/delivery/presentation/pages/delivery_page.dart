import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/entities/delivery_models.dart';
import '../../domain/repositories/delivery_repository.dart';
import 'delivery_apply_page.dart';
import 'available_delivery_orders_page.dart';
import 'delivery_orders_page.dart';
import 'delivery_chat_list_page.dart';
import 'delivery_settlement_account_page.dart';
import 'delivery_settlements_page.dart';

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});
  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  DeliveryProfile? _profile;
  bool _loading = true;
  bool _acting = false;
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
    final result = await getIt<DeliveryRepository>().me();
    if (!mounted) return;
    result.when(
      success: (value) => setState(() {
        _profile = value;
        _loading = false;
      }),
      failure: (e) => setState(() {
        _error = UserErrorMessage.from(e);
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Trabajar como domiciliario')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_profile == null) ...[
                  const CiervoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No estas inscrito',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'Completa la solicitud para trabajar como domiciliario en Ciervo.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CiervoButton(
                    label: 'Inscribirme',
                    icon: Icons.delivery_dining,
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DeliveryApplyPage(),
                        ),
                      );
                      _load();
                    },
                  ),
                ] else ...[
                  CiervoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado: ${_statusLabel(_profile!.status)}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (_profile!.vehicleType != null)
                          Text('Vehiculo: ${_profile!.vehicleType}'),
                        Text(
                          'Disponibilidad: ${_profile!.isOnline ? 'Online' : 'Offline'}',
                        ),
                        Text(
                          'Ultima ubicacion: ${_profile!.lastLatitude == null ? 'Sin registrar' : '${_profile!.lastLatitude}, ${_profile!.lastLongitude}'}',
                        ),
                        if (_profile!.isApproved) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _SettlementAccountStatus(profile: _profile!),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Disponible para trabajar'),
                            value: _profile!.isOnline,
                            subtitle: _profile!.isSettlementAccountVerified
                                ? null
                                : const Text(
                                    'Necesitas una cuenta aprobada para ponerte online.',
                                  ),
                            onChanged:
                                _acting || !_profile!.isSettlementAccountVerified
                                ? null
                                : _toggleOnline,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_profile!.isApproved) ...[
                    const SizedBox(height: AppSpacing.md),
                    if (!_profile!.isSettlementAccountVerified) ...[
                      CiervoButton(
                        label: 'Registrar o corregir cuenta de liquidacion',
                        icon: Icons.account_balance_outlined,
                        onPressed: _openSettlementAccount,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    CiervoButton(
                      label: 'Actualizar mi ubicacion',
                      icon: Icons.my_location,
                      state: _acting
                          ? CiervoButtonState.loading
                          : CiervoButtonState.normal,
                      onPressed: _acting ? null : _updateLocation,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CiervoButton(
                      label: 'Domicilios disponibles',
                      icon: Icons.delivery_dining_outlined,
                      variant: CiervoButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AvailableDeliveryOrdersPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CiervoButton(
                      label: 'Mis pedidos',
                      icon: Icons.local_shipping_outlined,
                      variant: CiervoButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DeliveryOrdersPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CiervoButton(
                      label: 'Chat de entregas',
                      icon: Icons.forum_outlined,
                      variant: CiervoButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DeliveryChatListPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CiervoButton(
                      label: 'Cuenta de liquidacion',
                      icon: Icons.account_balance_outlined,
                      variant: CiervoButtonVariant.secondary,
                      onPressed: _openSettlementAccount,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CiervoButton(
                      label: 'Mis liquidaciones',
                      icon: Icons.payments_outlined,
                      variant: CiervoButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DeliverySettlementsPage(),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
  );
  Future<void> _toggleOnline(bool online) async {
    if (!_profile!.isApproved) return;
    if (!_profile!.isSettlementAccountVerified) {
      _showError(
        'Tu cuenta de liquidacion debe estar aprobada para ponerte online.',
      );
      return;
    }
    setState(() => _acting = true);
    final result = await getIt<DeliveryRepository>().setOnline(online);
    if (!mounted) return;
    result.when(
      success: (p) => setState(() {
        _profile = p;
        _acting = false;
      }),
      failure: (e) {
        setState(() => _acting = false);
        _showError(e);
      },
    );
  }

  Future<void> _updateLocation() async {
    setState(() => _acting = true);
    try {
      var permission = await getIt<LocationService>().permissionStatus();
      if (permission.name != 'granted') {
        permission = await getIt<LocationService>().requestPermission();
      }
      final location = await getIt<LocationService>().currentLocation();
      final result = await getIt<DeliveryRepository>().updateLocation(
        location.latitude,
        location.longitude,
        location.accuracy,
      );
      if (!mounted) return;
      result.when(success: (_) => _load(), failure: _showError);
    } catch (e) {
      if (mounted) {
        setState(() => _acting = false);
        _showError(e);
      }
    }
  }

  void _showError(Object error) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error))));
  Future<void> _openSettlementAccount() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeliverySettlementAccountPage(profile: _profile),
      ),
    );
    _load();
  }

  String _statusLabel(String status) =>
      const {
        'Pending': 'Pendiente de aprobacion',
        'Approved': 'Aprobado',
        'Rejected': 'Rechazado',
        'Suspended': 'Suspendido',
      }[status] ??
      status;
}

class _SettlementAccountStatus extends StatelessWidget {
  const _SettlementAccountStatus({required this.profile});

  final DeliveryProfile profile;

  @override
  Widget build(BuildContext context) {
    final status = profile.settlementAccountVerificationStatus;
    final rejected = status == 'Rejected';
    final color = rejected
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuenta de liquidacion: ${status ?? (profile.hasSettlementAccount ? 'Pending' : 'Sin registrar')}',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
        if (profile.settlementAccountRejectionReason != null)
          Text('Motivo: ${profile.settlementAccountRejectionReason}'),
        if (!profile.isSettlementAccountVerified)
          const Text(
            'Cuando sea aprobada podras ponerte online y recibir domicilios.',
          ),
      ],
    );
  }
}
