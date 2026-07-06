import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/kids/selected_kid_context.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/commerce_purchase_splash.dart';
import '../../../place_detail/data/business_detail_repository.dart';
import '../../domain/entities/delivery_models.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../pages/customer_order_detail_page.dart';
import '../widgets/delivery_address_map_picker.dart';

/// Checkout unificado: retiro en local o delivery con cotización real del backend.
class OrderCheckoutPage extends StatefulWidget {
  const OrderCheckoutPage({
    required this.businessId,
    required this.businessName,
    required this.products,
    required this.initialLocation,
    this.initialFulfillment,
    this.deliveryAvailability,
    super.key,
  });

  final String businessId;
  final String businessName;
  final List<BusinessProduct> products;
  final AppLocation initialLocation;
  final OrderFulfillmentType? initialFulfillment;
  final DeliveryAvailability? deliveryAvailability;

  @override
  State<OrderCheckoutPage> createState() => _OrderCheckoutPageState();
}

class _OrderCheckoutPageState extends State<OrderCheckoutPage> {
  final _notesController = TextEditingController();
  final _quantities = <String, int>{};
  late LatLng _selectedPosition;
  String _address = '';
  OrderFulfillmentType? _fulfillment;
  OrderQuote? _quote;
  bool _quoting = false;
  bool _submitting = false;
  bool _legacyDeliveryOnly = false;
  String? _quoteError;

  @override
  void initState() {
    super.initState();
    _selectedPosition =
        LatLng(widget.initialLocation.latitude, widget.initialLocation.longitude);
    for (final product in widget.products) {
      _quantities[product.id] = 0;
    }
    _fulfillment = widget.initialFulfillment;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshQuote());
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  List<DeliveryOrderItemRequest> get _selectedItems => _quantities.entries
      .where((entry) => entry.value > 0)
      .map(
        (entry) => DeliveryOrderItemRequest(
          productId: entry.key,
          quantity: entry.value,
        ),
      )
      .toList();

  OrderQuoteOption? get _selectedQuoteOption {
    final quote = _quote;
    final fulfillment = _fulfillment;
    if (quote == null || fulfillment == null) return null;
    return quote.optionFor(fulfillment);
  }

  Future<void> _refreshQuote() async {
    final items = _selectedItems;
    if (items.isEmpty) {
      setState(() {
        _quote = null;
        _quoteError = null;
      });
      return;
    }

    setState(() {
      _quoting = true;
      _quoteError = null;
    });

    final result = await getIt<DeliveryRepository>().orderQuote(
      businessId: widget.businessId,
      items: items,
      latitude: _selectedPosition.latitude,
      longitude: _selectedPosition.longitude,
    );

    if (!mounted) return;
    result.when(
      success: (quote) {
        OrderFulfillmentType? fulfillment = _fulfillment;
        final pickupOk = quote.pickup?.available == true;
        final deliveryOk = quote.delivery?.available == true;
        if (fulfillment == null) {
          fulfillment = deliveryOk
              ? OrderFulfillmentType.delivery
              : pickupOk
                  ? OrderFulfillmentType.pickup
                  : null;
        } else if (fulfillment == OrderFulfillmentType.delivery && !deliveryOk) {
          fulfillment = pickupOk ? OrderFulfillmentType.pickup : null;
        } else if (fulfillment == OrderFulfillmentType.pickup && !pickupOk) {
          fulfillment = deliveryOk ? OrderFulfillmentType.delivery : null;
        }

        setState(() {
          _quote = quote;
          _fulfillment = fulfillment;
          _quoting = false;
        });
      },
      failure: (error) {
        if (error is AppException &&
            error.code == 'order_quote_unavailable' &&
            widget.deliveryAvailability != null) {
          final quote = _buildLegacyQuote(items, widget.deliveryAvailability!);
          setState(() {
            _legacyDeliveryOnly = true;
            _quote = quote;
            _fulfillment = OrderFulfillmentType.delivery;
            _quoting = false;
            _quoteError = null;
          });
          return;
        }
        setState(() {
          _quoteError = UserErrorMessage.from(error);
          _quoting = false;
        });
      },
    );
  }

  OrderQuote _buildLegacyQuote(
    List<DeliveryOrderItemRequest> items,
    DeliveryAvailability availability,
  ) {
    final currency = availability.currency ?? 'COP';
    num subtotal = 0;
    final quoteItems = <OrderQuoteItem>[];
    for (final item in items) {
      final product = widget.products
          .where((candidate) => candidate.id == item.productId)
          .firstOrNull;
      if (product == null) continue;
      final lineTotal = product.price * item.quantity;
      subtotal += lineTotal;
      quoteItems.add(
        OrderQuoteItem(
          productId: product.id,
          productName: product.name,
          quantity: item.quantity,
          unitPrice: product.price,
          totalPrice: lineTotal,
        ),
      );
    }
    final deliveryFee = availability.estimatedDeliveryFee ?? 0;
    return OrderQuote(
      businessId: widget.businessId,
      businessName: widget.businessName,
      delivery: OrderQuoteOption(
        fulfillmentType: OrderFulfillmentType.delivery,
        available: availability.deliveryAvailable,
        reason: availability.message,
        productSubtotal: subtotal,
        deliveryFee: deliveryFee,
        total: subtotal + deliveryFee,
        currency: currency,
        items: quoteItems,
      ),
    );
  }

  Future<void> _submit() async {
    final items = _selectedItems;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un producto.')),
      );
      return;
    }

    final fulfillment = _fulfillment;
    final option = _selectedQuoteOption;
    if (fulfillment == null || option == null || !option.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            option?.reason ?? 'Esta opción de entrega no está disponible.',
          ),
        ),
      );
      return;
    }

    final address = _address.trim();
    if (fulfillment == OrderFulfillmentType.delivery && address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirma la dirección de entrega.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final childProfileId = getIt<SelectedKidContext>().kidId;
    final fulfillmentLabel = fulfillment == OrderFulfillmentType.pickup
        ? 'Retiro en ${widget.businessName}'
        : 'Domicilio a: $address';

    final order = await runCommercePurchaseWithSplash<DeliveryOrder>(
      context: context,
      purchase: () async {
        final result = await getIt<DeliveryRepository>().createCustomerOrder(
          businessId: widget.businessId,
          fulfillmentType: fulfillment,
          items: items,
          deliveryAddress: fulfillment == OrderFulfillmentType.delivery
              ? address
              : null,
          latitude: _selectedPosition.latitude,
          longitude: _selectedPosition.longitude,
          notes: _notesController.text,
          childProfileId: childProfileId,
          legacyDeliveryContract: _legacyDeliveryOnly,
        );
        return result.when(
          success: (value) => value,
          failure: (error) => throw Exception(UserErrorMessage.from(error)),
        );
      },
      buildReceipt: (value) => CommercePurchaseReceipt.fromOrder(
        value,
        fulfillmentLabel: fulfillmentLabel,
      ),
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    if (order == null) return;

    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerOrderDetailPage(orderId: order.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final option = _selectedQuoteOption;
    final pickupAvailable =
        !_legacyDeliveryOnly && _quote?.pickup?.available == true;
    final deliveryAvailable = _quote?.delivery?.available == true;

    return Scaffold(
      appBar: AppBar(title: Text('Pedido · ${widget.businessName}')),
      body: ListView(
        padding: pagePaddingOf(context),
        children: [
          Text('Tu pedido', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          ...widget.products.map(_quantityTile),
          const SizedBox(height: AppSpacing.lg),
          Text('¿Cómo lo recibes?', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          if (_quoting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (pickupAvailable)
              _FulfillmentCard(
                selected: _fulfillment == OrderFulfillmentType.pickup,
                title: 'Retiro en local',
                subtitle: _quote?.pickup == null
                    ? 'Sin costo de envío'
                    : DisplayFormatters.formatMoney(
                        _quote!.pickup!.total,
                        currency: _quote!.pickup!.currency,
                      ),
                detail: 'Sin costo de envío',
                icon: Icons.storefront_outlined,
                onTap: () => setState(
                  () => _fulfillment = OrderFulfillmentType.pickup,
                ),
              ),
            if (deliveryAvailable) ...[
              const SizedBox(height: AppSpacing.sm),
              _FulfillmentCard(
                selected: _fulfillment == OrderFulfillmentType.delivery,
                title: 'Domicilio',
                subtitle: _quote?.delivery == null
                    ? 'Con costo de envío'
                    : DisplayFormatters.formatMoney(
                        _quote!.delivery!.total,
                        currency: _quote!.delivery!.currency,
                      ),
                detail: _quote?.delivery == null
                    ? null
                    : 'Subtotal ${DisplayFormatters.formatMoney(_quote!.delivery!.productSubtotal, currency: _quote!.delivery!.currency)} + envío ${DisplayFormatters.formatMoney(_quote!.delivery!.deliveryFee, currency: _quote!.delivery!.currency)}',
                icon: Icons.delivery_dining_outlined,
                onTap: () => setState(
                  () => _fulfillment = OrderFulfillmentType.delivery,
                ),
              ),
            ],
            if (_quoteError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_quoteError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (!pickupAvailable && !deliveryAvailable && _selectedItems.isNotEmpty)
              Text(
                _quote?.pickup?.reason ??
                    _quote?.delivery?.reason ??
                    'No hay opciones de entrega disponibles para este pedido.',
              ),
          ],
          if (_fulfillment == OrderFulfillmentType.delivery) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('¿Dónde entregamos?', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            DeliveryAddressMapPicker(
              initialPosition: _selectedPosition,
              onChanged: (position, address) {
                setState(() {
                  _selectedPosition = position;
                  _address = address;
                });
                _refreshQuote();
              },
            ),
          ],
          if (option != null && option.available) ...[
            const SizedBox(height: AppSpacing.lg),
            CiervoCard(
              child: Column(
                children: [
                  _AmountRow(
                    label: 'Subtotal productos',
                    value: DisplayFormatters.formatMoney(
                      option.productSubtotal,
                      currency: option.currency,
                    ),
                  ),
                  if (option.deliveryFee > 0) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _AmountRow(
                      label: 'Costo domicilio',
                      value: DisplayFormatters.formatMoney(
                        option.deliveryFee,
                        currency: option.currency,
                      ),
                    ),
                  ],
                  const Divider(),
                  _AmountRow(
                    label: 'Total',
                    value: DisplayFormatters.formatMoney(
                      option.total,
                      currency: option.currency,
                    ),
                    prominent: true,
                  ),
                  if (option.estimatedMinutes != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text('Tiempo estimado: ${option.estimatedMinutes} min'),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _notesController,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: _fulfillment == OrderFulfillmentType.pickup
                  ? 'Notas para el comercio (opcional)'
                  : 'Notas para el domiciliario (opcional)',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          CiervoButton(
            label: _submitting ? 'Procesando pedido…' : 'Confirmar y pagar',
            icon: Icons.shopping_bag_outlined,
            state: _submitting || _quoting
                ? CiervoButtonState.loading
                : CiervoButtonState.normal,
            onPressed: _submitting || _quoting ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _quantityTile(BusinessProduct product) {
    final quantity = _quantities[product.id] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CiervoCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(product.name),
          subtitle: Text(DisplayFormatters.formatMoney(product.price)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: quantity == 0
                    ? null
                    : () {
                        setState(() => _quantities[product.id] = quantity - 1);
                        _refreshQuote();
                      },
              ),
              SizedBox(width: 24, child: Center(child: Text('$quantity'))),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  setState(() => _quantities[product.id] = quantity + 1);
                  _refreshQuote();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FulfillmentCard extends StatelessWidget {
  const _FulfillmentCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.detail,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final String? detail;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.45)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: selected ? colorScheme.primary : null),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(subtitle),
                    if (detail != null)
                      Text(
                        detail!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
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
