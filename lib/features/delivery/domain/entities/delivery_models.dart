import '../../../receipts/domain/entities/action_confirmation.dart';
import 'delivery_pricing.dart';

export 'delivery_pricing.dart';

class DeliveryProfile {
  const DeliveryProfile({
    required this.status,
    required this.isOnline,
    required this.hasSettlementAccount,
    required this.isSettlementAccountVerified,
    this.lastLatitude,
    this.lastLongitude,
    this.vehicleType,
    this.settlementAccountVerificationStatus,
    this.settlementAccountRejectionReason,
    this.maskedAccountNumber,
    this.maskedDocumentNumber,
    this.maskedPhone,
    this.maskedMercadoPago,
  });
  final String status;
  final bool isOnline;
  final bool hasSettlementAccount;
  final bool isSettlementAccountVerified;
  final double? lastLatitude;
  final double? lastLongitude;
  final String? vehicleType;
  final String? settlementAccountVerificationStatus;
  final String? settlementAccountRejectionReason;
  final String? maskedAccountNumber;
  final String? maskedDocumentNumber;
  final String? maskedPhone;
  final String? maskedMercadoPago;
  bool get isApproved => status == 'Approved';
  bool get canWorkOnline => isApproved && isSettlementAccountVerified;
  bool get needsSettlementAccountReview =>
      isApproved && !isSettlementAccountVerified;
}

class DeliveryOrder {
  const DeliveryOrder({
    required this.id,
    required this.status,
    required this.businessName,
    required this.businessAddress,
    required this.deliveryAddress,
    this.reference,
    this.userCiervoCode,
    this.customerName,
    this.conversationId,
    this.deliveryPin,
    this.pickupPin,
    this.pricing,
    this.unreadCount = 0,
    this.confirmation,
    this.totalAmount,
    this.productsSubtotal,
    this.deliveryFee,
    this.courierEarning,
    this.platformFee,
    this.distanceKm,
    this.currency,
    this.countryCode,
    this.publicUrl,
    this.shareTitle,
    this.shareDescription,
    this.shareImageUrl,
    this.items = const [],
    this.paymentStatus,
    this.paymentMethod,
    this.childProfileId,
    this.businessId,
  });
  final String id;
  final String status;
  final String businessName;
  final String businessAddress;
  final String deliveryAddress;
  final String? reference;
  final String? userCiervoCode;
  final String? customerName;
  final String? conversationId;
  final String? deliveryPin;
  final String? pickupPin;
  final DeliveryPricing? pricing;
  final int unreadCount;
  final ActionConfirmation? confirmation;
  final num? totalAmount;
  final num? productsSubtotal;
  final num? deliveryFee;
  final num? courierEarning;
  final num? platformFee;
  final double? distanceKm;
  final String? currency;
  final String? countryCode;
  final String? publicUrl;
  final String? shareTitle;
  final String? shareDescription;
  final String? shareImageUrl;
  final List<DeliveryOrderItem> items;
  final String? paymentStatus;
  final String? paymentMethod;
  final String? childProfileId;
  final String? businessId;

  bool get needsPayment {
    final normalized = (paymentStatus ?? '').toLowerCase();
    return normalized.isEmpty ||
        normalized == '1' ||
        normalized == 'pending' ||
        normalized.contains('pending');
  }

  bool get isCashOnDelivery {
    final normalized = (paymentStatus ?? '').toLowerCase();
    return normalized.contains('collect') ||
        normalized == '5' ||
        normalized.contains('delivery');
  }

  bool get isDelivered {
    final normalized = status.toLowerCase().replaceAll('_', '');
    return normalized == 'delivered' || normalized.contains('delivered');
  }

  DeliveryPricing get effectivePricing => pricing ??
      DeliveryPricing(
        distanceKm: distanceKm,
        deliveryFee: deliveryFee,
        platformFee: platformFee,
        courierEarning: courierEarning,
      );
}

class DeliveryPaymentResult {
  const DeliveryPaymentResult({
    required this.paymentStatus,
    this.checkoutUrl,
    this.paymentMethod,
    this.message,
  });

  final String paymentStatus;
  final String? checkoutUrl;
  final String? paymentMethod;
  final String? message;

  bool get requiresExternalCheckout =>
      (checkoutUrl ?? '').isNotEmpty &&
      paymentStatus.toLowerCase().contains('process');
}

class DeliveryOrderItem {
  const DeliveryOrderItem({
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

String deliveryStatusLabel(String status) {
  final normalized = status.toLowerCase().replaceAll('_', '');
  return switch (normalized) {
    'pendingbusinessapproval' => 'Pendiente de aprobacion del negocio',
    'rejectedbybusiness' => 'Rechazado por el negocio',
    'pendingcourieracceptance' => 'Buscando domiciliario',
    'courierassigned' => 'Domiciliario asignado',
    'acceptedbycourier' => 'Aceptado por domiciliario',
    'couriernotfound' => 'Sin domiciliario disponible',
    'pendingassignment' => 'Pendiente de asignacion',
    'assigned' => 'Domiciliario asignado',
    'accepted' => 'Pedido aceptado',
    'businessaccepted' => 'Aceptado por el negocio',
    'preparing' => 'Preparando pedido',
    'readyforpickup' => 'Listo para recoger',
    'arrivedatbusiness' => 'Domiciliario en el negocio',
    'pickedup' => 'Pedido recogido',
    'ontheway' => 'Pedido en camino',
    'arrivedatcustomer' => 'Domiciliario en el destino',
    'delivered' => 'Entregado',
    'cancelled' => 'Cancelado',
    _ => status.replaceAll('_', ' '),
  };
}

String deliveryPaymentStatusLabel(String? status) {
  if (status == null || status.isEmpty) return 'Pendiente';
  final normalized = status.toLowerCase();
  return switch (normalized) {
    '1' || 'pending' => 'Pendiente de pago',
    '2' || 'processing' => 'Procesando pago',
    '3' || 'paid' || 'succeeded' => 'Pagado',
    '4' || 'failed' => 'Pago fallido',
    '5' || 'collectondelivery' => 'Cobro al entregar',
    '6' || 'cancelled' => 'Pago cancelado',
    _ => status,
  };
}

class AvailableDeliveryOrder {
  const AvailableDeliveryOrder({
    required this.id,
    required this.businessName,
    required this.businessAddress,
    required this.deliveryAddress,
    this.distanceKm,
    this.courierEarning,
    this.currency,
    this.pricing,
  });

  final String id;
  final String businessName;
  final String businessAddress;
  final String deliveryAddress;
  final double? distanceKm;
  final num? courierEarning;
  final String? currency;
  final DeliveryPricing? pricing;

  DeliveryPricing get effectivePricing => pricing ??
      DeliveryPricing(
        distanceKm: distanceKm,
        courierEarning: courierEarning,
      );
}

class DeliverySettlementAccount {
  const DeliverySettlementAccount({
    required this.bank,
    required this.accountType,
    required this.accountNumber,
    required this.holderName,
    required this.documentNumber,
    this.walletProvider,
    this.walletNumber,
  });

  final String bank;
  final String accountType;
  final String accountNumber;
  final String holderName;
  final String documentNumber;
  final String? walletProvider;
  final String? walletNumber;

  Map<String, dynamic> toJson() => {
    'bank': bank,
    'accountType': accountType,
    'accountNumber': accountNumber,
    'holderName': holderName,
    'documentNumber': documentNumber,
    if (walletProvider != null && walletProvider!.trim().isNotEmpty)
      'walletProvider': walletProvider!.trim(),
    if (walletNumber != null && walletNumber!.trim().isNotEmpty)
      'walletNumber': walletNumber!.trim(),
  };
}

class DeliverySettlement {
  const DeliverySettlement({
    required this.id,
    required this.orderId,
    required this.status,
    required this.createdAt,
    this.amount,
    this.currency,
  });

  final String id;
  final String orderId;
  final String status;
  final DateTime? createdAt;
  final num? amount;
  final String? currency;
}
