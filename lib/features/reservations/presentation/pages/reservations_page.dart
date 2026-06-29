// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../data/booking_repository.dart';
import '../../domain/entities/booking.dart';
import '../../../qr_wallet/domain/entities/ciervo_qr_item.dart';
import '../../../qr_wallet/presentation/widgets/ciervo_qr_card.dart';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({super.key});
  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  late Future<List<Booking>> _bookings;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _bookings = getIt<BookingRepository>().getMine().then(
      (result) => result.when(
        success: (value) => value,
        failure: (error) => throw error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mis reservas'),
      actions: [
        IconButton(
          tooltip: 'Buscar por codigo',
          onPressed: _searchByCode,
          icon: const Icon(Icons.manage_search),
        ),
      ],
    ),
    body: FutureBuilder<List<Booking>>(
      future: _bookings,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CiervoBrandLoader(message: 'Cargando tus reservas');
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(UserErrorMessage.from(snapshot.error!)),
                  TextButton(
                    onPressed: () => setState(_reload),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        final bookings = snapshot.data ?? const [];
        if (bookings.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: CiervoEmptyState(
              title: 'Aun no tienes reservas',
              description: 'Tus proximas reservas apareceran aqui.',
              icon: Icons.event_available_outlined,
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => setState(_reload),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, index) => _BookingCard(
              booking: bookings[index],
              onRefresh: () => setState(_reload),
            ),
          ),
        );
      },
    ),
  );

  Future<void> _searchByCode() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consultar reserva'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'RSV-XXXXXXXX'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.trim().isEmpty || !mounted) return;
    final result = await getIt<BookingRepository>().getByCode(code);
    if (!mounted) return;
    result.when(
      success: (booking) => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(booking.publicCode),
          content: _BookingDetails(booking: booking),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onRefresh});
  final Booking booking;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: _BookingDetails(booking: booking, onRefresh: onRefresh),
    ),
  );
}

class _BookingDetails extends StatelessWidget {
  const _BookingDetails({required this.booking, this.onRefresh});
  final Booking booking;
  final VoidCallback? onRefresh;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(booking.publicCode, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.xs),
      _line('Estado', booking.status),
      _line('Fecha', _date(booking.bookingDate)),
      _line('Negocio', booking.businessName ?? 'Sin informacion'),
      _line('Tipo', booking.bookingType),
      _line('Personas', '${booking.peopleCount}'),
      _line(
        'Total',
        booking.totalAmount == null ? 'Por definir' : '${booking.totalAmount}',
      ),
      _line('Moneda', booking.currency),
      const SizedBox(height: AppSpacing.md),
      CiervoQrCard(
        onRefresh: onRefresh,
        item: CiervoQrItem(
          id: '${booking.id}',
          type: CiervoQrType.booking,
          status: CiervoQrStatus.active,
          reference: booking.publicCode,
          title: 'Presenta este codigo/QR en el negocio',
          subtitle: booking.businessName,
          qrId: booking.qrId,
          qrPayload: booking.qrPayload,
          expiresAt: booking.qrExpiresAt,
          eventDate: booking.bookingDate,
          rawStatus: booking.status,
        ),
      ),
    ],
  );

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Text('$label: $value'),
  );
  String _date(DateTime? value) =>
      value == null
          ? 'Sin informacion'
          : value.toLocal().toString().substring(0, 16);
}
