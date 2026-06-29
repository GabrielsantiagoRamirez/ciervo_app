import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../payments/domain/repositories/payments_repository.dart';
import '../../../wallet/presentation/pages/nfc_pay_session_page.dart';
import '../../../wallet/presentation/utils/nfc_navigation.dart';
import '../../domain/entities/delivery_models.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../../../wallet/domain/entities/wallet_card.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import 'delivery_chat_page.dart';

class CustomerOrderDetailPage extends StatefulWidget {
  const CustomerOrderDetailPage({required this.orderId, super.key});
  final String orderId;

  @override
  State<CustomerOrderDetailPage> createState() =>
      _CustomerOrderDetailPageState();
}

class _CustomerOrderDetailPageState extends State<CustomerOrderDetailPage> {
  DeliveryOrder? _order;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result =
        await getIt<DeliveryRepository>().customerOrder(widget.orderId);
    if (!mounted) return;
    result.when(
      success: (order) => setState(() {
        _order = order;
        _error = null;
      }),
      failure: (error) => setState(() => _error = UserErrorMessage.from(error)),
    );
  }

  Future<void> _pay(String method) async {
    setState(() => _busy = true);
    String? walletCardId;
    if (method == 'wallet') {
      final cards = await getIt<WalletRepository>().cards();
      WalletCard? selected;
      cards.when(
        success: (items) {
          selected = items.where((card) => card.isPrimary).firstOrNull ??
              items.firstOrNull;
          walletCardId = selected?.id;
        },
        failure: (_) {},
      );
      if (walletCardId == null || selected == null) {
        if (mounted) {
          setState(() => _busy = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No tienes tarjeta wallet disponible.')),
          );
        }
        return;
      }
      final total = _order?.totalAmount?.toDouble() ?? 0;
      if (total > 0 && !selected!.canSpend(total)) {
        if (mounted) {
          setState(() => _busy = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Saldo disponible insuficiente (COP ${selected!.availableBalance.toStringAsFixed(0)}).',
              ),
            ),
          );
        }
        return;
      }
    }

    if (method == 'mercadopago') {
      final key =
          'delivery-${widget.orderId}-${DateTime.now().microsecondsSinceEpoch}';
      final intentResult = await getIt<PaymentsRepository>().createDeliveryPayment(
        deliveryOrderId: widget.orderId,
        idempotencyKey: key,
      );
      if (!mounted) return;
      await intentResult.when(
        success: (intent) async {
          if (intent.checkoutUrl.isNotEmpty) {
            await launchUrl(
              Uri.parse(intent.checkoutUrl),
              mode: LaunchMode.externalApplication,
            );
          }
          final poll = await getIt<PaymentsRepository>().pollIntent(intent.id);
          if (!mounted) return;
          setState(() => _busy = false);
          poll.when(
            success: (finalIntent) {
              if (finalIntent.isApproved) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pago aprobado.')),
                );
                _load();
              } else if (finalIntent.isRejected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pago rechazado.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pago ${finalIntent.statusLabel.toLowerCase()}.'),
                  ),
                );
              }
            },
            failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(UserErrorMessage.from(error))),
            ),
          );
        },
        failure: (error) {
          setState(() => _busy = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(UserErrorMessage.from(error))),
          );
        },
      );
      return;
    }

    final result = await getIt<DeliveryRepository>().payOrder(
      orderId: widget.orderId,
      paymentMethod: method,
      walletCardId: walletCardId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (payment) async {
        if ((payment.checkoutUrl ?? '').isNotEmpty) {
          await launchUrl(
            Uri.parse(payment.checkoutUrl!),
            mode: LaunchMode.externalApplication,
          );
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              method == 'wallet'
                  ? (payment.message ??
                      'Pago ${deliveryPaymentStatusLabel(payment.paymentStatus)}')
                  : (payment.message ??
                      'Pedido actualizado: ${deliveryPaymentStatusLabel(payment.paymentStatus)}'),
            ),
          ),
        );
        _load();
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  Future<void> _startDeliveryNfcSession() async {
    setState(() => _busy = true);
    final result =
        await getIt<DeliveryRepository>().createOrderNfcSession(
      orderId: widget.orderId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    await result.when(
      success: (session) async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NfcPaySessionPage(
              session: session,
              businessName: _order?.businessName ?? 'Delivery',
              isDelivery: true,
            ),
          ),
        );
        _load();
      },
      failure: (error) => handleNfcError(context, error),
    );
  }

  Future<void> _addTip() async {
    final amountController = TextEditingController();
    final amount = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Propina'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monto (COP)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              double.tryParse(amountController.text.replaceAll(',', '.')),
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    setState(() => _busy = true);
    final result = await getIt<DeliveryRepository>().addTip(
      orderId: widget.orderId,
      amount: amount,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propina enviada.')),
        );
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  Future<void> _createReturn() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar devolucion'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Motivo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (confirmed != true || reasonController.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final result = await getIt<DeliveryRepository>().createReturn(
      orderId: widget.orderId,
      reason: reasonController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Devolucion registrada.')),
        );
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  Future<void> _rate() async {
    int rating = 5;
    final commentController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Calificar pedido'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: rating.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$rating',
                onChanged: (value) =>
                    setDialogState(() => rating = value.round()),
              ),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(labelText: 'Comentario'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    final result = await getIt<DeliveryRepository>().rateOrder(
      orderId: widget.orderId,
      rating: rating,
      comment: commentController.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gracias por tu calificacion.')),
        );
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Pedido #${widget.orderId}')),
    body: _order == null
        ? Center(
            child: _error == null
                ? const CircularProgressIndicator()
                : Text(_error!),
          )
        : Stack(
            children: [
              RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    CiervoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _order!.businessName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if ((_order!.reference ?? '').isNotEmpty)
                            Text('Referencia: ${_order!.reference}'),
                          Text('Estado: ${deliveryStatusLabel(_order!.status)}'),
                          Text(
                            'Pago: ${deliveryPaymentStatusLabel(_order!.paymentStatus)}',
                          ),
                          if (_order!.isCashOnDelivery)
                            const Text('Cobro en efectivo al entregar'),
                          if (_order!.customerName != null)
                            Text('Cliente: ${_order!.customerName}'),
                          if (_order!.userCiervoCode != null)
                            Text('Ciervo ID: ${_order!.userCiervoCode}'),
                          if (_order!.deliveryAddress.isNotEmpty)
                            Text('Entrega: ${_order!.deliveryAddress}'),
                          if (_order!.productsSubtotal != null)
                            Text(
                              'Subtotal productos: ${_order!.currency ?? 'COP'} ${_order!.productsSubtotal!.toStringAsFixed(0)}',
                            ),
                          if (_order!.deliveryFee != null)
                            Text(
                              'Domicilio: ${_order!.currency ?? 'COP'} ${_order!.deliveryFee!.toStringAsFixed(0)}',
                            ),
                          if (_order!.totalAmount != null)
                            Text(
                              'Total a pagar: ${_order!.currency ?? 'COP'} ${_order!.totalAmount!.toStringAsFixed(0)}',
                            ),
                        ],
                      ),
                    ),
                    if (_order!.items.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      CiervoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Items',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ..._order!.items.map(
                              (item) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.productName),
                                subtitle: Text('Cantidad: ${item.quantity}'),
                                trailing: Text(
                                  'COP ${item.totalPrice.toStringAsFixed(0)}',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_order!.needsPayment) ...[
                      const SizedBox(height: AppSpacing.lg),
                      CiervoButton(
                        label: 'Pagar con Wallet',
                        icon: Icons.account_balance_wallet_outlined,
                        onPressed: _busy ? null : () => _pay('wallet'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CiervoButton(
                        label: 'Pagar con Mercado Pago',
                        icon: Icons.open_in_new,
                        variant: CiervoButtonVariant.secondary,
                        onPressed: _busy ? null : () => _pay('mercadopago'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CiervoButton(
                        label: 'Pagar en efectivo al entregar',
                        icon: Icons.payments_outlined,
                        variant: CiervoButtonVariant.secondary,
                        onPressed: _busy ? null : () => _pay('cash'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CiervoButton(
                        label: 'Pagar con NFC CIERVO',
                        icon: Icons.nfc,
                        variant: CiervoButtonVariant.secondary,
                        onPressed: _busy ? null : () => _pay('nfc'),
                      ),
                    ],
                    if (_order!.isNfcPrepared) ...[
                      const SizedBox(height: AppSpacing.lg),
                      CiervoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Pago NFC preparado',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Al recibir tu pedido, activa NFC para que el domiciliario cobre '
                              'COP ${_order!.totalAmount?.toStringAsFixed(0) ?? '—'}.',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            CiervoButton(
                              label: 'Acercar celular para pagar',
                              icon: Icons.nfc,
                              onPressed: _busy ? null : _startDeliveryNfcSession,
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_order!.deliveryPin case final pin?) ...[
                      const SizedBox(height: AppSpacing.lg),
                      CiervoCard(
                        child: Column(
                          children: [
                            const Text('PIN de entrega'),
                            Text(
                              pin,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const Text(
                              'Compartelo solo cuando recibas tu pedido.',
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_order!.isDelivered) ...[
                      const SizedBox(height: AppSpacing.lg),
                      CiervoButton(
                        label: 'Dejar propina',
                        icon: Icons.volunteer_activism_outlined,
                        onPressed: _busy ? null : _addTip,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CiervoButton(
                        label: 'Solicitar devolucion',
                        icon: Icons.undo_outlined,
                        variant: CiervoButtonVariant.secondary,
                        onPressed: _busy ? null : _createReturn,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CiervoButton(
                        label: 'Calificar pedido',
                        icon: Icons.star_outline,
                        variant: CiervoButtonVariant.secondary,
                        onPressed: _busy ? null : _rate,
                      ),
                    ],
                    if (_order!.conversationId case final conversationId?) ...[
                      const SizedBox(height: AppSpacing.lg),
                      CiervoButton(
                        label: 'Abrir chat de entregas',
                        icon: Icons.chat_bubble_outline,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DeliveryChatPage(
                              conversationId: conversationId,
                              title: 'Pedido #${_order!.id}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_busy)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x55000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
  );
}
