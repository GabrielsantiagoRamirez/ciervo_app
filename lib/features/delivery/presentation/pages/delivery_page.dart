import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_labels.dart';
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: CiervoCard(
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(_error!)),
                        ],
                      ),
                    ),
                  ),
                if (_profile == null) ...[
                  _NotRegisteredCard(
                    onApply: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DeliveryApplyPage(),
                        ),
                      );
                      _load();
                    },
                  ),
                ] else ...[
                  _StatusHeroCard(profile: _profile!),
                  if (_profile!.status.toLowerCase().contains('reject') &&
                      (_profile!.settlementAccountRejectionReason?.isNotEmpty ??
                          false))
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: CiervoCard(
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _profile!.settlementAccountRejectionReason!,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  _RequirementsCard(profile: _profile!),
                  const SizedBox(height: AppSpacing.md),
                  _InfoCard(profile: _profile!),
                  if (_profile!.isApproved) ...[
                    const SizedBox(height: AppSpacing.md),
                    _AvailabilityCard(
                      profile: _profile!,
                      acting: _acting,
                      onToggle: _toggleOnline,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (!_profile!.isSettlementAccountVerified)
                      CiervoButton(
                        label: 'Registrar cuenta de liquidación',
                        icon: Icons.account_balance_outlined,
                        onPressed: _openSettlementAccount,
                      ),
                    if (!_profile!.isSettlementAccountVerified)
                      const SizedBox(height: AppSpacing.sm),
                    CiervoButton(
                      label: 'Actualizar mi ubicación',
                      icon: Icons.my_location,
                      state: _acting
                          ? CiervoButtonState.loading
                          : CiervoButtonState.normal,
                      onPressed: _acting ? null : _updateLocation,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Acciones',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ActionGrid(
                      onAvailable: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AvailableDeliveryOrdersPage(),
                        ),
                      ),
                      onOrders: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DeliveryOrdersPage(),
                        ),
                      ),
                      onChat: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DeliveryChatListPage(),
                        ),
                      ),
                      onSettlement: _openSettlementAccount,
                      onSettlements: () => Navigator.of(context).push(
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
    if (_profile!.canGoOnline == false) {
      _showError(
        _profile!.onlineBlockReason ??
            'Completa los requisitos pendientes para conectarte.',
      );
      return;
    }
    if (!_profile!.isSettlementAccountVerified) {
      _showError(
        'Tu cuenta de liquidación debe estar aprobada para conectarte.',
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
}

class _NotRegisteredCard extends StatelessWidget {
  const _NotRegisteredCard({required this.onApply});

  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) => CiervoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.delivery_dining,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Únete como domiciliario',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Completa tu solicitud para entregar pedidos en Ciervo Club y generar ingresos.',
        ),
        const SizedBox(height: AppSpacing.lg),
        CiervoButton(
          label: 'Inscribirme',
          icon: Icons.delivery_dining,
          onPressed: onApply,
        ),
      ],
    ),
  );
}

class _StatusHeroCard extends StatelessWidget {
  const _StatusHeroCard({required this.profile});

  final DeliveryProfile profile;

  @override
  Widget build(BuildContext context) {
    final status = DisplayLabels.deliveryStatus(profile.status);
    final color = _statusColor(profile.status);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(profile.status), color: color, size: 32),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xxs),
                Text(_statusMessage(profile.status)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusMessage(String status) {
    final key = status.toLowerCase();
    if (key.contains('pending')) {
      return 'Tu solicitud está en revisión. Te notificaremos cuando seas aprobado.';
    }
    if (key.contains('reject')) {
      return 'Tu solicitud fue rechazada. Contacta soporte si necesitas ayuda.';
    }
    if (key.contains('suspend')) {
      return 'Tu cuenta está suspendida temporalmente.';
    }
    return 'Ya puedes recibir pedidos cuando estés disponible.';
  }

  Color _statusColor(String status) {
    final key = status.toLowerCase();
    if (key.contains('approve')) return Colors.green;
    if (key.contains('reject') || key.contains('suspend')) return Colors.red;
    return Colors.orange;
  }

  IconData _statusIcon(String status) {
    final key = status.toLowerCase();
    if (key.contains('approve')) return Icons.verified_outlined;
    if (key.contains('reject')) return Icons.block_outlined;
    return Icons.hourglass_top_outlined;
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.profile});

  final DeliveryProfile profile;

  @override
  Widget build(BuildContext context) => CiervoCard(
    child: Column(
      children: [
        _row(
          Icons.two_wheeler_outlined,
          'Vehículo',
          DisplayLabels.vehicleType(profile.vehicleType),
        ),
        if (profile.maskedVehiclePlate != null &&
            profile.maskedVehiclePlate!.isNotEmpty) ...[
          const Divider(height: 24),
          _row(Icons.pin_outlined, 'Placa', profile.maskedVehiclePlate!),
        ],
        const Divider(height: 24),
        _row(
          Icons.location_on_outlined,
          'Última ubicación',
          DisplayLabels.locationSummary(
            latitude: profile.lastLatitude,
            longitude: profile.lastLongitude,
          ),
        ),
        if (profile.hasSettlementAccount) ...[
          const Divider(height: 24),
          _row(
            Icons.account_balance_outlined,
            'Cuenta de liquidación',
            _settlementLabel(profile),
          ),
        ],
      ],
    ),
  );

  String _settlementLabel(DeliveryProfile profile) {
    final status = profile.settlementAccountVerificationStatus;
    if (status == null) return 'Registrada';
    return DisplayLabels.deliveryStatus(status);
  }

  Widget _row(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 22),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ],
  );
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({
    required this.profile,
    required this.acting,
    required this.onToggle,
  });

  final DeliveryProfile profile;
  final bool acting;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final canToggle =
        profile.canGoOnline != false && profile.isSettlementAccountVerified && !acting;
    final blockReason = profile.onlineBlockReason;
    return CiervoCard(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(
          profile.isOnline ? Icons.wifi_tethering : Icons.wifi_tethering_off,
          color: profile.isOnline ? Colors.green : null,
        ),
        title: Text(
          DisplayLabels.availability(profile.isOnline),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          canToggle
              ? 'Activa para recibir pedidos cercanos.'
              : blockReason ??
                  'Necesitas una cuenta de liquidación aprobada para conectarte.',
        ),
        value: profile.isOnline,
        onChanged: canToggle ? onToggle : null,
      ),
    );
  }
}

class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard({required this.profile});

  final DeliveryProfile profile;

  @override
  Widget build(BuildContext context) => CiervoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requisitos pendientes',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        _item(
          'KYC aprobado',
          profile.kycApproved == true,
        ),
        _item(
          'Cuenta de liquidación aprobada',
          profile.isSettlementAccountVerified,
        ),
        _item(
          'Perfil domiciliario aprobado',
          profile.isApproved,
        ),
      ],
    ),
  );

  Widget _item(String label, bool done) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      done ? Icons.check_circle : Icons.radio_button_unchecked,
      color: done ? Colors.green : null,
    ),
    title: Text(label),
    dense: true,
  );
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.onAvailable,
    required this.onOrders,
    required this.onChat,
    required this.onSettlement,
    required this.onSettlements,
  });

  final VoidCallback onAvailable;
  final VoidCallback onOrders;
  final VoidCallback onChat;
  final VoidCallback onSettlement;
  final VoidCallback onSettlements;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      _chip(context, 'Disponibles', Icons.delivery_dining_outlined, onAvailable),
      _chip(context, 'Mis pedidos', Icons.local_shipping_outlined, onOrders),
      _chip(context, 'Chat', Icons.forum_outlined, onChat),
      _chip(context, 'Cuenta', Icons.account_balance_outlined, onSettlement),
      _chip(context, 'Liquidaciones', Icons.payments_outlined, onSettlements),
    ],
  );

  Widget _chip(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) => ActionChip(
    avatar: Icon(icon, size: 18),
    label: Text(label),
    onPressed: onTap,
  );
}
