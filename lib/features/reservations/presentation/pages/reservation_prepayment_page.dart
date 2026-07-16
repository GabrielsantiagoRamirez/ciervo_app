import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/idempotency_key.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../payments/domain/entities/payment_intent.dart';
import '../../../payments/domain/repositories/payments_repository.dart';
import '../../domain/entities/booking.dart';

class ReservationPrepaymentPage extends StatefulWidget {
  const ReservationPrepaymentPage({
    required this.booking,
    required this.businessId,
    super.key,
  });

  final Booking booking;
  final String businessId;

  @override
  State<ReservationPrepaymentPage> createState() =>
      _ReservationPrepaymentPageState();
}

class _ReservationPrepaymentPageState extends State<ReservationPrepaymentPage>
    with WidgetsBindingObserver {
  final _payments = getIt<PaymentsRepository>();

  late final String _idempotencyKey = IdempotencyKey.generate();
  PaymentIntent? _intent;
  bool _loading = true;
  bool _polling = false;
  bool _checkoutOpened = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _createIntent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _checkoutOpened &&
        !_polling &&
        _intent != null) {
      _checkPayment();
    }
  }

  Future<void> _createIntent() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _payments.createBookingPayment(
      bookingId: '${widget.booking.id}',
      businessId:
          '${widget.booking.businessId ?? int.tryParse(widget.businessId) ?? widget.businessId}',
      idempotencyKey: _idempotencyKey,
    );
    if (!mounted) return;
    await result.when(
      success: (intent) async {
        _intent = intent;
        setState(() => _loading = false);
        await _openCheckout();
      },
      failure: (error) async {
        setState(() {
          _loading = false;
          _error = UserErrorMessage.from(error);
        });
      },
    );
  }

  Future<void> _openCheckout() async {
    final url = (_intent?.checkoutUrl ?? '').trim();
    if (url.isEmpty) {
      setState(() {
        _error =
            'Aún no hay enlace de pago. Usa “Reintentar preparar pago” '
            'si el anticipo no se preparó.';
      });
      return;
    }
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    setState(() {
      _checkoutOpened = opened;
      if (!opened) {
        _error = 'No pudimos abrir el enlace de pago. Intenta nuevamente.';
      }
    });
  }

  Future<void> _checkPayment() async {
    final intent = _intent;
    if (intent == null || _polling) return;
    setState(() {
      _polling = true;
      _error = null;
    });
    final result = await _payments.pollIntent(
      intent.id,
      interval: const Duration(seconds: 2),
      maxAttempts: 15,
    );
    if (!mounted) return;
    result.when(
      success: (finalIntent) {
        _intent = finalIntent;
        if (finalIntent.isApproved) {
          Navigator.of(context).pop(true);
          return;
        }
        setState(() {
          _polling = false;
          _error = finalIntent.isRejected
              ? 'El pago fue rechazado. Puedes intentar de nuevo.'
              : 'El anticipo sigue ${finalIntent.statusLabel.toLowerCase()}.';
        });
      },
      failure: (error) {
        setState(() {
          _polling = false;
          _error = UserErrorMessage.from(error);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final num amount =
        _intent?.amount ??
        widget.booking.prepaymentAmount ??
        widget.booking.totalAmount ??
        0;
    final currency =
        ((_intent?.currency ?? widget.booking.currency).trim().isEmpty)
        ? widget.booking.currency
        : (_intent?.currency ?? widget.booking.currency);
    final busy = _loading || _polling;
    final hasCheckout = (_intent?.checkoutUrl ?? '').trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Pagar anticipo')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Icon(
                Icons.event_available_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.booking.businessName ?? 'Reserva',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Anticipo: $currency ${amount.toStringAsFixed(0)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Se abrirá el checkout del proveedor configurado por el '
                'servidor para el país y moneda de este negocio.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (!hasCheckout)
                CiervoButton(
                  label: 'Reintentar preparar pago',
                  icon: Icons.refresh,
                  onPressed: busy ? null : _createIntent,
                )
              else ...[
                CiervoButton(
                  label: 'Abrir enlace de pago',
                  icon: Icons.open_in_new,
                  onPressed: busy ? null : _openCheckout,
                ),
                const SizedBox(height: AppSpacing.sm),
                CiervoButton(
                  label: 'Ya pagué, consultar estado',
                  icon: Icons.refresh,
                  variant: CiervoButtonVariant.secondary,
                  onPressed: busy ? null : _checkPayment,
                ),
              ],
            ],
          ),
          if (busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xE6070708),
                child: CiervoBrandLoader(message: 'Preparando pago seguro'),
              ),
            ),
        ],
      ),
    );
  }
}
