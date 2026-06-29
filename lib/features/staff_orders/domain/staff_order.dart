class StaffOrder {
  const StaffOrder({
    required this.id,
    required this.reference,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.total,
    required this.items,
    this.notes,
    this.deliveryPersonName,
    this.createdAt,
  });

  factory StaffOrder.fromJson(Map<String, dynamic> json) {
    final delivery = json['delivery'] is Map
        ? Map<String, dynamic>.from(json['delivery'] as Map)
        : const <String, dynamic>{};
    return StaffOrder(
      id: _string(json, const ['id', 'orderId']),
      reference: _string(json, const ['reference', 'publicCode', 'code']),
      status: _stringValue(
        delivery['status'] ?? json['deliveryStatus'] ?? json['status'],
        fallback: 'pending',
      ),
      customerName: _stringValue(
        json['customerName'] ?? json['clientName'] ?? json['client']?['name'],
      ),
      customerPhone: _stringValue(
        json['customerPhone'] ?? json['phone'] ?? json['client']?['phone'],
      ),
      deliveryAddress: _stringValue(
        delivery['deliveryAddress'] ??
            json['deliveryAddress'] ??
            json['customerAddress'],
      ),
      total: _num(json['total'] ?? json['totalAmount'] ?? json['amount']) ?? 0,
      notes: _nullableString(json['notes'] ?? delivery['notes']),
      deliveryPersonName: _nullableString(
        delivery['deliveryPersonName'] ??
            json['deliveryPersonName'] ??
            json['delivery']?['name'],
      ),
      createdAt: DateTime.tryParse(
        '${json['createdAt'] ?? json['date'] ?? json['createdDate'] ?? ''}',
      ),
      items: _items(json['items'] ?? json['orderItems'] ?? json['products']),
    );
  }

  final String id;
  final String reference;
  final String status;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final num total;
  final String? notes;
  final String? deliveryPersonName;
  final DateTime? createdAt;
  final List<StaffOrderItem> items;
}

class StaffOrderItem {
  const StaffOrderItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory StaffOrderItem.fromJson(Map<String, dynamic> json) => StaffOrderItem(
    productName: _stringValue(json['productName'] ?? json['name']),
    quantity: _int(json['quantity']),
    unitPrice: _num(json['unitPrice'] ?? json['price']) ?? 0,
    totalPrice: _num(json['totalPrice'] ?? json['total']) ?? 0,
  );

  final String productName;
  final int quantity;
  final num unitPrice;
  final num totalPrice;
}

List<StaffOrderItem> _items(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(StaffOrderItem.fromJson)
      .toList();
}

String _string(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  return '';
}

String _stringValue(dynamic value, {String fallback = ''}) {
  if (value == null || value.toString().isEmpty) return fallback;
  return value.toString();
}

String? _nullableString(dynamic value) {
  final text = _stringValue(value);
  return text.isEmpty ? null : text;
}

int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;

num? _num(dynamic value) => value is num ? value : num.tryParse('$value');

String staffOrderStatusLabel(String status) => switch (status) {
  'pending' => 'Pendiente',
  'accepted' => 'Aceptado',
  'preparing' => 'En preparacion',
  'ready_for_pickup' => 'Listo para recoger',
  'assigned' => 'Asignado',
  'picked_up' => 'Recogido',
  'delivered' => 'Entregado',
  'cancelled' => 'Cancelado',
  'rejected' => 'Rechazado',
  _ => status,
};
