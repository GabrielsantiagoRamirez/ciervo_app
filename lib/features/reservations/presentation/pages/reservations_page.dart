// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../core/utils/display_labels.dart';
import '../../data/booking_repository.dart';
import '../../../wallet/presentation/pages/request_money_page.dart';
import '../../domain/entities/booking.dart';
import '../../../qr_wallet/domain/entities/ciervo_qr_item.dart';
import '../../../qr_wallet/presentation/widgets/ciervo_qr_card.dart';
import 'new_reservation_page.dart';

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

  Future<void> _openNewReservation() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const NewReservationPage()),
    );
    if (created == true && mounted) {
      setState(_reload);
    }
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
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _openNewReservation,
      icon: const Icon(Icons.add),
      label: const Text('Nueva reserva'),
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
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: _groupedBookings(bookings)
                .expand(
                  (group) => [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.xs,
                      ),
                      child: Text(
                        group.key,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ...group.value.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _BookingCard(
                          booking: booking,
                          onRefresh: () => setState(_reload),
                        ),
                      ),
                    ),
                  ],
                )
                .toList(),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Puedes buscar por código RSV, @usuario o número de documento. '
              'También puedes escanear un QR guardado en favoritos.',
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'RSV-XXXXXXXX · @toesca · documento',
                helperText: 'Ejemplos: RSV-AB12CD34, @toesca o 12345678',
              ),
            ),
          ],
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

    final query = code.trim();
    final result = await getIt<BookingRepository>().lookup(query);
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
      failure: (error) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(error)))),
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
      _line('Estado', DisplayLabels.bookingStatus(booking.status)),
      _line('Fecha', _date(booking.bookingDate)),
      _line('Negocio', booking.businessName ?? 'Sin información'),
      if ((booking.city ?? '').isNotEmpty) _line('Ciudad', booking.city!),
      if ((booking.categoryName ?? '').isNotEmpty)
        _line('Categoría', booking.categoryName!),
      if ((booking.time ?? '').isNotEmpty) _line('Hora', booking.time!),
      _line('Tipo', booking.bookingType),
      _line('Personas', '${booking.peopleCount}'),
      _line(
        'Total',
        booking.totalAmount == null ? 'Por definir' : '${booking.totalAmount}',
      ),
      _line('Moneda', booking.currency),
      if (booking.totalAmount != null && booking.totalAmount! > 0) ...[
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RequestMoneyPage(
                bookingId: booking.id,
                businessId: booking.businessId,
                initialAmount: booking.totalAmount?.toDouble(),
                initialCurrency: booking.currency,
              ),
            ),
          ),
          icon: const Icon(Icons.chat_outlined),
          label: const Text('Pedir pago en chat'),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      if (booking.requiresPrepayment &&
          !_isBookingConfirmed(booking.status)) ...[
        Text(
          'Anticipo pendiente',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      CiervoQrCard(
        onRefresh: onRefresh,
        item: CiervoQrItem(
          id: '${booking.id}',
          type: CiervoQrType.booking,
          status: _qrStatusForBooking(booking),
          reference: booking.publicCode,
          title: _isBookingConfirmed(booking.status)
              ? 'Presenta este codigo/QR en el negocio'
              : 'QR disponible cuando la reserva esté confirmada',
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
  String _date(DateTime? value) => value == null
      ? 'Sin información'
      : value.toLocal().toString().substring(0, 16);
}

bool _isBookingConfirmed(String status) {
  final text = status.trim().toLowerCase();
  return text.contains('confirm') ||
      text.contains('approved') ||
      text.contains('paid') ||
      text.contains('acept');
}

CiervoQrStatus _qrStatusForBooking(Booking booking) {
  final text = booking.status.trim().toLowerCase();
  if (text.contains('cancel') || text.contains('reject') || text.contains('denied')) {
    return CiervoQrStatus.cancelled;
  }
  if (text.contains('expir')) {
    return CiervoQrStatus.expired;
  }
  if (booking.requiresPrepayment && !_isBookingConfirmed(text)) {
    return CiervoQrStatus.unknown;
  }
  if (_isBookingConfirmed(text)) {
    return CiervoQrStatus.active;
  }
  if (text.contains('pending') || text.contains('pendiente')) {
    return CiervoQrStatus.unknown;
  }
  return CiervoQrStatus.unknown;
}

List<MapEntry<String, List<Booking>>> _groupedBookings(List<Booking> bookings) {
  final sorted = [...bookings]
    ..sort((a, b) {
      final ad = a.bookingDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.bookingDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
  final groups = <String, List<Booking>>{};
  for (final booking in sorted) {
    final date = booking.bookingDate;
    final key = date == null
        ? 'Sin fecha'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    groups.putIfAbsent(key, () => []).add(booking);
  }
  return groups.entries.toList();
}
