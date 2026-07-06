import 'delivery_pricing.dart';

enum OrderFulfillmentType {
  pickup,
  delivery;

  String get apiValue => name;

  static OrderFulfillmentType? tryParse(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return switch (normalized) {
      'pickup' || 'retiro' => OrderFulfillmentType.pickup,
      'delivery' || 'domicilio' => OrderFulfillmentType.delivery,
      _ => null,
    };
  }
}

class OrderQuoteItem {
  const OrderQuoteItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  final String productId;
  final String productName;
  final int quantity;
  final num unitPrice;
  final num totalPrice;
}

class OrderQuoteOption {
  const OrderQuoteOption({
    required this.fulfillmentType,
    required this.available,
    this.reason,
    this.productSubtotal = 0,
    this.deliveryFee = 0,
    this.total = 0,
    this.currency = 'COP',
    this.countryCode,
    this.estimatedMinutes,
    this.pricing,
    this.items = const [],
  });

  final OrderFulfillmentType fulfillmentType;
  final bool available;
  final String? reason;
  final num productSubtotal;
  final num deliveryFee;
  final num total;
  final String currency;
  final String? countryCode;
  final int? estimatedMinutes;
  final DeliveryPricing? pricing;
  final List<OrderQuoteItem> items;
}

class OrderQuote {
  const OrderQuote({
    required this.businessId,
    required this.businessName,
    this.pickup,
    this.delivery,
  });

  final String businessId;
  final String businessName;
  final OrderQuoteOption? pickup;
  final OrderQuoteOption? delivery;

  OrderQuoteOption? optionFor(OrderFulfillmentType type) => switch (type) {
        OrderFulfillmentType.pickup => pickup,
        OrderFulfillmentType.delivery => delivery,
      };
}
