import '../../../wallet/domain/entities/nfc_models.dart';
import '../../../../core/result/result.dart';
import '../entities/delivery_models.dart';

abstract interface class DeliveryRepository {
  Future<Result<DeliveryProfile?>> me();
  Future<Result<DeliveryProfile>> apply(Map<String, dynamic> payload);
  Future<Result<DeliveryProfile>> setOnline(bool online);
  Future<Result<void>> updateLocation(
    double latitude,
    double longitude,
    double? accuracy,
  );
  Future<Result<List<AvailableDeliveryOrder>>> availableOrders();
  Future<Result<DeliveryOrder>> claimOrder(String id);
  Future<Result<List<DeliveryOrder>>> orders();
  Future<Result<DeliveryOrder>> order(String id);
  Future<Result<List<DeliveryOrder>>> customerOrders();
  Future<Result<DeliveryOrder>> customerOrder(String id);
  Future<Result<OrderQuote>> orderQuote({
    required String businessId,
    required List<DeliveryOrderItemRequest> items,
    required double latitude,
    required double longitude,
    OrderFulfillmentType? fulfillmentType,
  });
  Future<Result<DeliveryOrder>> createCustomerOrder({
    required String businessId,
    required OrderFulfillmentType fulfillmentType,
    required List<DeliveryOrderItemRequest> items,
    String? deliveryAddress,
    double? latitude,
    double? longitude,
    String? notes,
    String? childProfileId,
    bool legacyDeliveryContract = false,
  });
  Future<Result<DeliveryPaymentResult>> payOrder({
    required String orderId,
    required String paymentMethod,
    String? walletCardId,
    String? childWalletCardId,
  });
  Future<Result<NfcSession>> createOrderNfcSession({required String orderId});
  Future<Result<void>> addTip({
    required String orderId,
    required double amount,
    String? walletCardId,
  });
  Future<Result<void>> createReturn({
    required String orderId,
    required String reason,
    String? notes,
  });
  Future<Result<void>> rateOrder({
    required String orderId,
    required int rating,
    String? comment,
  });
  Future<Result<List<DeliveryTrackingPoint>>> tracking(String orderId);
  Future<Result<void>> postTracking({
    required String orderId,
    required double latitude,
    required double longitude,
    String? status,
  });
  Future<Result<DeliveryOrder>> action(String id, String action, {String? pin});
  Future<Result<List<dynamic>>> conversations();
  Future<Result<List<dynamic>>> messages(String id, {required int page});
  Future<Result<Map<String, dynamic>>> sendMessage(String id, String body);
  Future<Result<void>> markRead(String id);
  Future<Result<void>> updateSettlementAccount(
    DeliverySettlementAccount account,
  );
  Future<Result<DeliverySettlementAccountDetails?>> settlementAccount();
  Future<Result<List<DeliverySettlement>>> settlements();
}

class DeliveryOrderItemRequest {
  const DeliveryOrderItemRequest({
    required this.productId,
    required this.quantity,
  });

  final String productId;
  final int quantity;

  Map<String, dynamic> toJson() => {
    'productId': int.tryParse(productId) ?? productId,
    'quantity': quantity,
  };
}
