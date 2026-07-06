import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/kids/selected_kid_context.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../place_detail/data/business_detail_repository.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../pages/customer_order_detail_page.dart';
import '../widgets/delivery_address_map_picker.dart';

/// Checkout domicilio estilo Rappi: mapa + productos + confirmación.
class DeliveryCheckoutPage extends StatefulWidget {
  const DeliveryCheckoutPage({
    required this.businessId,
    required this.businessName,
    required this.products,
    required this.initialLocation,
    required this.availability,
    super.key,
  });

  final String businessId;
  final String businessName;
  final List<BusinessProduct> products;
  final AppLocation initialLocation;
  final DeliveryAvailability? availability;

  @override
  State<DeliveryCheckoutPage> createState() => _DeliveryCheckoutPageState();
}

class _DeliveryCheckoutPageState extends State<DeliveryCheckoutPage> {
  final _notesController = TextEditingController();
  final _quantities = <String, int>{};
  late LatLng _selectedPosition;
  String _address = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition =
        LatLng(widget.initialLocation.latitude, widget.initialLocation.longitude);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Domicilio · ${widget.businessName}')),
      body: ListView(
        padding: pagePaddingOf(context),
        children: [
          Text('¿Dónde entregamos?', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          DeliveryAddressMapPicker(
            initialPosition: _selectedPosition,
            onChanged: (position, address) => setState(() {
              _selectedPosition = position;
              _address = address;
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Tu pedido', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          ...widget.products.map(_quantityTile),
          const SizedBox(height: AppSpacing.sm),
          _DeliverySummary(
            productsSubtotal: _productsSubtotal,
            deliveryFee: widget.availability?.estimatedDeliveryFee ?? 0,
            currency: widget.availability?.currency ?? 'COP',
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _notesController,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notas para el domiciliario (opcional)',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          CiervoButton(
            label: _submitting ? 'Creando pedido…' : 'Confirmar pedido',
            icon: Icons.delivery_dining,
            state: _submitting
                ? CiervoButtonState.loading
                : CiervoButtonState.normal,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _quantityTile(BusinessProduct product) {
    final quantity = _quantities[product.id] ?? 0;
    return CiervoCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(product.name),
        subtitle: Text('\$${product.price}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: quantity == 0
                  ? null
                  : () => setState(() => _quantities[product.id] = quantity - 1),
            ),
            SizedBox(width: 24, child: Center(child: Text('$quantity'))),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () =>
                  setState(() => _quantities[product.id] = quantity + 1),
            ),
          ],
        ),
      ),
    );
  }

  num get _productsSubtotal {
    num total = 0;
    for (final product in widget.products) {
      total += product.price * (_quantities[product.id] ?? 0);
    }
    return total;
  }

  Future<void> _submit() async {
    final items = _quantities.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => DeliveryOrderItemRequest(
            productId: entry.key,
            quantity: entry.value,
          ),
        )
        .toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un producto.')),
      );
      return;
    }

    final position = _selectedPosition;
    final address = _address.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirma la dirección de entrega.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final childProfileId = getIt<SelectedKidContext>().kidId;
    final result = await getIt<DeliveryRepository>().createCustomerOrder(
      businessId: widget.businessId,
      deliveryAddress: address,
      latitude: position.latitude,
      longitude: position.longitude,
      items: items,
      notes: _notesController.text,
      childProfileId: childProfileId,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      success: (order) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CustomerOrderDetailPage(orderId: order.id),
          ),
        );
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserErrorMessage.from(error))),
      ),
    );
  }
}

class _DeliverySummary extends StatelessWidget {
  const _DeliverySummary({
    required this.productsSubtotal,
    required this.deliveryFee,
    required this.currency,
  });

  final num productsSubtotal;
  final num deliveryFee;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final total = productsSubtotal + deliveryFee;
    return CiervoCard(
      child: Column(
        children: [
          _AmountRow(
            label: 'Subtotal productos',
            value: _money(productsSubtotal, currency),
          ),
          const SizedBox(height: AppSpacing.xs),
          _AmountRow(label: 'Costo domicilio', value: _money(deliveryFee, currency)),
          const Divider(),
          _AmountRow(
            label: 'Total estimado',
            value: _money(total, currency),
            prominent: true,
          ),
        ],
      ),
    );
  }

  String _money(num value, String currency) => '$currency ${value.toStringAsFixed(0)}';
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.prominent = false,
  });

  final String label;
  final String value;
  final bool prominent;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: prominent
                  ? Theme.of(context).textTheme.titleMedium
                  : null,
            ),
          ),
          Text(
            value,
            style: prominent
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )
                : null,
          ),
        ],
      );
}
