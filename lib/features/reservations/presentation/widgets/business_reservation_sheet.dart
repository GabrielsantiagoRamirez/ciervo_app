import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/ciervo_date_picker.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/insufficient_balance_dialog.dart';
import '../../../place_detail/data/business_detail_repository.dart';
import '../../../receipts/domain/entities/action_confirmation.dart';
import '../../../receipts/presentation/pages/action_confirmation_page.dart';
import '../../data/booking_repository.dart';
import '../../domain/entities/booking.dart';
import '../pages/reservation_prepayment_page.dart';

Future<Booking?> showBusinessReservationSheet(
  BuildContext context, {
  required String businessId,
  required List<ReservableOption> options,
  String? businessName,
  bool showConfirmationReceipt = true,
}) {
  if (options.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Este negocio aún no tiene opciones de reserva.'),
      ),
    );
    return Future<Booking?>.value();
  }

  return showModalBottomSheet<Booking>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: BusinessReservationSheet(
        businessId: businessId,
        businessName: businessName,
        options: options,
      ),
    ),
  ).then((booking) async {
    if (booking == null || !context.mounted) return booking;

    var confirmed = booking;
    var paymentApproved = !booking.requiresPrepayment;
    if (booking.requiresPrepayment) {
      paymentApproved =
          await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => ReservationPrepaymentPage(
                booking: booking,
                businessId: businessId,
              ),
            ),
          ) ==
          true;
    }

    if (paymentApproved && context.mounted) {
      confirmed = await _refreshBooking(booking) ?? booking;
    }

    if (showConfirmationReceipt && paymentApproved && context.mounted) {
      await _showBookingReceipt(
        context,
        booking: confirmed,
        fallbackBusinessName: businessName,
      );
    }
    return confirmed;
  });
}

Future<Booking?> _refreshBooking(Booking booking) async {
  final code = booking.publicCode.trim();
  if (code.isEmpty) return null;
  final result = await getIt<BookingRepository>().getByCode(code);
  return result.when(success: (value) => value, failure: (_) => null);
}

Future<void> _showBookingReceipt(
  BuildContext context, {
  required Booking booking,
  String? fallbackBusinessName,
}) async {
  final base = booking.confirmation;
  final userCode = base?.userCiervoCode ?? await resolveCurrentCiervoUserCode();
  if (!context.mounted) return;
  await showCiervoPaymentReceipt(
    context,
    confirmation: ActionConfirmation(
      title: booking.requiresPrepayment
          ? 'Reserva y anticipo confirmados'
          : base?.title ?? 'Reserva confirmada',
      confirmationCode: base?.confirmationCode ?? booking.publicCode,
      userCiervoCode: userCode,
      businessName:
          base?.businessName ?? booking.businessName ?? fallbackBusinessName,
      amount: booking.requiresPrepayment
          ? booking.prepaymentAmount ?? booking.totalAmount
          : base?.amount ?? booking.totalAmount,
      currency: base?.currency ?? booking.currency,
      status: booking.requiresPrepayment
          ? 'Anticipo pagado'
          : base?.status ?? 'Reserva confirmada',
      date:
          base?.date ?? booking.bookingDate?.toIso8601String().substring(0, 10),
      time: base?.time ?? booking.time,
      publicReceiptUrl: base?.publicReceiptUrl,
      shareDescription:
          base?.shareDescription ??
          'Tu reserva en Ciervo Club fue confirmada correctamente.',
    ),
    referenceLabel: 'Reserva',
    referenceValue: booking.publicCode.isNotEmpty
        ? booking.publicCode
        : base?.confirmationCode ?? '${booking.id}',
  );
}

class BusinessReservationSheet extends StatefulWidget {
  const BusinessReservationSheet({
    required this.businessId,
    required this.options,
    this.businessName,
    super.key,
  });

  final String businessId;
  final String? businessName;
  final List<ReservableOption> options;

  @override
  State<BusinessReservationSheet> createState() =>
      _BusinessReservationSheetState();
}

class _BusinessReservationSheetState extends State<BusinessReservationSheet> {
  final _notesController = TextEditingController();
  ReservableOption? _option;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  int _peopleCount = 2;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _option = widget.options.firstOrNull;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final option = _option;
    final maxPeople = (option?.capacity ?? 12).clamp(1, 30).toDouble();
    final people = _peopleCount.toDouble().clamp(1.0, maxPeople);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        top: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.businessName == null
                  ? 'Reservar'
                  : 'Reservar en ${widget.businessName}',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<ReservableOption>(
              initialValue: _option,
              items: widget.options
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _option = value),
              decoration: const InputDecoration(labelText: 'Opción'),
            ),
            if (option != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                option.paymentLabel(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: option.requiresPrepayment
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (option.capacity > 0)
                Text(
                  'Capacidad: hasta ${option.capacity} personas',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_date.toIso8601String().substring(0, 10)),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: Text(_time.format(context)),
                    onPressed: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Personas: ${people.round()}'),
            Slider(
              min: 1,
              max: maxPeople,
              divisions: maxPeople <= 1 ? null : maxPeople.round() - 1,
              value: people,
              label: '${people.round()}',
              onChanged: (value) =>
                  setState(() => _peopleCount = value.round()),
            ),
            TextField(
              controller: _notesController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notas opcionales'),
            ),
            const SizedBox(height: AppSpacing.md),
            CiervoButton(
              label: _submitting
                  ? 'Confirmando'
                  : option?.requiresPrepayment == true
                  ? 'Reservar y pagar anticipo'
                  : 'Confirmar reserva',
              icon: Icons.event_available,
              state: _submitting
                  ? CiervoButtonState.loading
                  : CiervoButtonState.normal,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final value = await showCiervoDatePicker(
      context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: _date,
      helpText: 'Selecciona la fecha',
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(context: context, initialTime: _time);
    if (value != null) setState(() => _time = value);
  }

  Future<void> _submit() async {
    final option = _option;
    if (option == null) return;
    final maxPeople = (option.capacity > 0 ? option.capacity : 12).clamp(1, 30);
    final peopleCount = _peopleCount.clamp(1, maxPeople);
    setState(() => _submitting = true);
    final result = await getIt<BookingRepository>().createBusinessReservation(
      businessId: widget.businessId,
      reservableOptionId: option.id,
      date: _date,
      time:
          '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}:00',
      peopleCount: peopleCount,
      notes: _notesController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    await result.when(
      success: (booking) async {
        Navigator.of(context).pop(booking);
      },
      failure: (error) async {
        final message = UserErrorMessage.from(error);
        if (message.toLowerCase().contains('saldo')) {
          await showInsufficientBalanceDialog(context, description: message);
        } else if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
    );
  }
}
