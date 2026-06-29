import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/entities/delivery_models.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../widgets/delivery_pricing_card.dart';
import 'delivery_chat_page.dart';

class DeliveryOrderDetailPage extends StatefulWidget {
  const DeliveryOrderDetailPage({required this.orderId, super.key});
  final String orderId;
  @override
  State<DeliveryOrderDetailPage> createState() =>
      _DeliveryOrderDetailPageState();
}

class _DeliveryOrderDetailPageState extends State<DeliveryOrderDetailPage> {
  DeliveryOrder? _order;
  bool _loading = true;
  bool _acting = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<DeliveryRepository>().order(widget.orderId);
    if (!mounted) return;
    result.when(
      success: (o) => setState(() {
        _order = o;
        _loading = false;
        _error = null;
      }),
      failure: (e) => setState(() {
        _error = UserErrorMessage.from(e);
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Pedido #${widget.orderId}')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _order == null
        ? Center(child: Text(_error ?? 'Pedido no disponible.'))
        : ListView(
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
                    Text('Recogida: ${_order!.businessAddress}'),
                    Text('Entrega: ${_order!.deliveryAddress}'),
                    if (_order!.customerName != null)
                      Text('Cliente: ${_order!.customerName}'),
                    Text('Estado: ${deliveryStatusLabel(_order!.status)}'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              DeliveryPricingCard(
                pricing: _order!.effectivePricing,
                currency: _order!.currency ?? 'COP',
                pickupPin: _order!.pickupPin,
                deliveryPin: _order!.deliveryPin,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_order!.conversationId case final conversationId?) ...[
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
                const SizedBox(height: AppSpacing.md),
              ],
              if (_actionFor(_order!.status) case final action?)
                CiervoButton(
                  label: action.label,
                  icon: action.icon,
                  state: _acting
                      ? CiervoButtonState.loading
                      : CiervoButtonState.normal,
                  onPressed: _acting ? null : () => _runAction(action),
                ),
            ],
          ),
  );
  _DeliveryAction? _actionFor(String status) => switch (status) {
    'CourierAssigned' => const _DeliveryAction(
      'accept',
      'Aceptar pedido',
      Icons.check,
    ),
    'Assigned' => const _DeliveryAction(
      'accept',
      'Aceptar pedido',
      Icons.check,
    ),
    'AcceptedByCourier' => const _DeliveryAction(
      'arrived-business',
      'Llegue al negocio',
      Icons.storefront,
    ),
    'Accepted' => const _DeliveryAction(
      'arrived-business',
      'Llegue al negocio',
      Icons.storefront,
    ),
    'ArrivedAtBusiness' => const _DeliveryAction(
      'pickup-confirm',
      'Confirmar recogida',
      Icons.pin_outlined,
      needsPin: true,
    ),
    'PickedUp' => const _DeliveryAction(
      'on-the-way',
      'Iniciar recorrido',
      Icons.route,
    ),
    'OnTheWay' => const _DeliveryAction(
      'arrived-customer',
      'Llegue al cliente',
      Icons.location_on_outlined,
    ),
    'ArrivedAtCustomer' => const _DeliveryAction(
      'deliver',
      'Confirmar entrega',
      Icons.verified_outlined,
      needsPin: true,
    ),
    _ => null,
  };
  Future<void> _runAction(_DeliveryAction action) async {
    String? pin;
    if (action.needsPin) {
      pin = await _askPin();
      if (pin == null || pin.trim().isEmpty) return;
    }
    setState(() => _acting = true);
    final result = await getIt<DeliveryRepository>().action(
      widget.orderId,
      action.path,
      pin: pin?.trim(),
    );
    if (!mounted) return;
    result.when(
      success: (o) => setState(() {
        _order = o;
        _acting = false;
      }),
      failure: (e) {
        setState(() => _acting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(UserErrorMessage.from(e))));
      },
    );
  }

  Future<String?> _askPin() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingresa el PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }
}

class _DeliveryAction {
  const _DeliveryAction(
    this.path,
    this.label,
    this.icon, {
    this.needsPin = false,
  });
  final String path;
  final String label;
  final IconData icon;
  final bool needsPin;
}
