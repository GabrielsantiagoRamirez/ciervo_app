import 'package:dio/dio.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/result/result.dart';
import '../../../receipts/domain/entities/action_confirmation.dart';
import '../../../wallet/data/dtos/nfc_dto.dart';
import '../../../wallet/domain/entities/nfc_models.dart';
import '../../domain/entities/delivery_models.dart';
import '../../domain/repositories/delivery_repository.dart';

class DeliveryRepositoryImpl implements DeliveryRepository {
  const DeliveryRepositoryImpl(this._client);
  final NetworkClient _client;

  @override
  Future<Result<DeliveryProfile?>> me() async {
    try {
      final response = await _client.dio.get<dynamic>('/api/delivery/me');
      final value = unwrapApiResponse(response.data);
      return Success(value is Map<String, dynamic> ? _profile(value) : null);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return const Success(null);
      return Failure(ErrorMapper.fromObject(error));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<DeliveryProfile>> apply(Map<String, dynamic> payload) =>
      _profileRequest(
        () => _client.dio.post<dynamic>('/api/delivery/apply', data: payload),
      );
  @override
  Future<Result<DeliveryProfile>> setOnline(bool online) => _guard(() async {
    await _client.dio.post<dynamic>(
      '/api/delivery/${online ? 'online' : 'offline'}',
    );
    return _profile(
      unwrapApiMap((await _client.dio.get<dynamic>('/api/delivery/me')).data),
    );
  });

  @override
  Future<Result<void>> updateLocation(
    double latitude,
    double longitude,
    double? accuracy,
  ) => _guard(() async {
    await _client.dio.put<dynamic>(
      '/api/delivery/location',
      data: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  });

  @override
  Future<Result<List<AvailableDeliveryOrder>>> availableOrders() => _guard(
    () async => unwrapApiList(
      (await _client.dio.get<dynamic>('/api/delivery/available-orders')).data,
    ).whereType<Map<String, dynamic>>().map(_availableOrder).toList(),
  );

  @override
  Future<Result<DeliveryOrder>> claimOrder(String id) async {
    try {
      await _client.dio.post<dynamic>('/api/delivery/orders/$id/claim');
      final response = await _client.dio.get<dynamic>(
        '/api/delivery/orders/$id',
      );
      return Success(_order(unwrapApiMap(response.data)));
    } on DioException catch (error) {
      if (error.response?.statusCode == 409) {
        return const Failure(
          AppException(
            message: 'Este domicilio ya fue tomado por otro domiciliario',
            code: 'delivery_order_claimed',
            statusCode: 409,
          ),
        );
      }
      return Failure(ErrorMapper.fromObject(error));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<DeliveryOrder>>> orders() => _guard(
    () async => unwrapApiList(
      (await _client.dio.get<dynamic>('/api/delivery/orders')).data,
    ).whereType<Map<String, dynamic>>().map(_order).toList(),
  );
  @override
  Future<Result<DeliveryOrder>> order(String id) => _guard(
    () async => _order(
      unwrapApiMap(
        (await _client.dio.get<dynamic>('/api/delivery/orders/$id')).data,
      ),
    ),
  );
  @override
  Future<Result<List<DeliveryOrder>>> customerOrders() => _guard(
    () async => unwrapApiList(
      (await _client.dio.get<dynamic>('/api/delivery/orders')).data,
    ).whereType<Map<String, dynamic>>().map(_order).toList(),
  );
  @override
  Future<Result<DeliveryOrder>> customerOrder(String id) => _guard(
    () async => _order(
      unwrapApiMap(
        (await _client.dio.get<dynamic>('/api/delivery/orders/$id')).data,
      ),
    ),
  );
  @override
  Future<Result<DeliveryOrder>> createCustomerOrder({
    required String businessId,
    required String deliveryAddress,
    required double latitude,
    required double longitude,
    required List<DeliveryOrderItemRequest> items,
    String? notes,
    String? childProfileId,
  }) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/api/businesses/$businessId/delivery-orders',
      data: {
        'deliveryAddress': deliveryAddress,
        'latitude': latitude,
        'longitude': longitude,
        'items': items.map((item) => item.toJson()).toList(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (childProfileId != null && childProfileId.trim().isNotEmpty)
          'childProfileId': int.tryParse(childProfileId) ?? childProfileId,
      },
    );
    return _order(unwrapApiMap(response.data));
  });

  @override
  Future<Result<DeliveryPaymentResult>> payOrder({
    required String orderId,
    required String paymentMethod,
    String? walletCardId,
    String? childWalletCardId,
  }) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/api/delivery/orders/$orderId/pay',
      data: {
        'paymentMethod': paymentMethod,
        'idempotencyKey': _idempotencyKey('pay-order', orderId),
        if (walletCardId != null)
          'walletCardId': int.tryParse(walletCardId) ?? walletCardId,
        if (childWalletCardId != null)
          'childWalletCardId':
              int.tryParse(childWalletCardId) ?? childWalletCardId,
      },
    );
    return _paymentResult(unwrapApiMap(response.data));
  });

  @override
  Future<Result<NfcSession>> createOrderNfcSession({
    required String orderId,
  }) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/api/delivery/orders/$orderId/nfc/session',
      data: {
        'idempotencyKey': _idempotencyKey('delivery-nfc', orderId),
      },
    );
    return NfcSessionDto.fromJson(unwrapApiMap(response.data)).toDomain();
  });

  @override
  Future<Result<void>> addTip({
    required String orderId,
    required double amount,
    String? walletCardId,
  }) => _guard(() async {
    await _client.dio.post<dynamic>(
      '/api/delivery/orders/$orderId/tips',
      data: {
        'amount': amount,
        'currency': 'COP',
        'idempotencyKey': _idempotencyKey('tip', orderId),
        if (walletCardId != null)
          'walletCardId': int.tryParse(walletCardId) ?? walletCardId,
      },
    );
  });

  @override
  Future<Result<void>> createReturn({
    required String orderId,
    required String reason,
    String? notes,
  }) => _guard(() async {
    await _client.dio.post<dynamic>(
      '/api/delivery/orders/$orderId/returns',
      data: {
        'reason': reason,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        'idempotencyKey': _idempotencyKey('return', orderId),
      },
    );
  });

  @override
  Future<Result<void>> rateOrder({
    required String orderId,
    required int rating,
    String? comment,
  }) => _guard(() async {
    await _client.dio.post<dynamic>(
      '/api/delivery/orders/$orderId/rate',
      data: {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
  });

  @override
  Future<Result<Map<String, dynamic>>> tracking(String orderId) => _guard(
    () async => unwrapApiMap(
      (await _client.dio.get<dynamic>(
        '/api/delivery/orders/$orderId/tracking',
      )).data,
    ),
  );
  @override
  Future<Result<DeliveryOrder>> action(
    String id,
    String action, {
    String? pin,
  }) => _guard(() async {
    await _client.dio.post<dynamic>(
      '/api/delivery/orders/$id/$action',
      data: pin == null ? null : {'pin': pin},
    );
    return _order(
      unwrapApiMap(
        (await _client.dio.get<dynamic>('/api/delivery/orders/$id')).data,
      ),
    );
  });
  @override
  Future<Result<List<dynamic>>> conversations() => _guard(
    () async => unwrapApiList(
      (await _client.dio.get<dynamic>('/api/delivery/conversations')).data,
    ),
  );
  @override
  Future<Result<List<dynamic>>> messages(String id, {required int page}) =>
      _guard(
        () async => unwrapApiList(
          (await _client.dio.get<dynamic>(
            '/api/delivery/conversations/$id/messages',
            queryParameters: {'page': page, 'pageSize': 50},
          )).data,
        ),
      );
  @override
  Future<Result<Map<String, dynamic>>> sendMessage(String id, String body) =>
      _guard(
        () async => unwrapApiMap(
          (await _client.dio.post<dynamic>(
            '/api/delivery/conversations/$id/messages',
            data: {
              'messageType': 'Text',
              'body': body,
              'attachmentUrl': null,
              'metadataJson': null,
            },
          )).data,
        ),
      );
  @override
  Future<Result<void>> markRead(String id) => _guard(() async {
    await _client.dio.post<void>('/api/delivery/conversations/$id/read');
  });

  @override
  Future<Result<void>> updateSettlementAccount(
    DeliverySettlementAccount account,
  ) => _guard(() async {
    await _client.dio.put<dynamic>(
      '/api/delivery/settlement-account',
      data: account.toJson(),
    );
  });

  @override
  Future<Result<DeliverySettlementAccountDetails?>> settlementAccount() async {
    try {
      final response =
          await _client.dio.get<dynamic>('/api/delivery/settlement-account');
      final data = unwrapApiMap(response.data);
      if (data.isEmpty) return const Success(null);
      return Success(_settlementAccountDetails(data));
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return const Success(null);
      return Failure(ErrorMapper.fromObject(error));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<DeliverySettlement>>> settlements() => _guard(
    () async => unwrapApiList(
      (await _client.dio.get<dynamic>('/api/delivery/settlements')).data,
    ).whereType<Map<String, dynamic>>().map(_settlement).toList(),
  );

  Future<Result<DeliveryProfile>> _profileRequest(
    Future<Response<dynamic>> Function() request,
  ) => _guard(() async => _profile(unwrapApiMap((await request()).data)));
  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  static DeliveryProfile _profile(Map<String, dynamic> json) {
    final account = json['settlementAccount'] is Map
        ? Map<String, dynamic>.from(json['settlementAccount'] as Map)
        : json['settlement'] is Map
        ? Map<String, dynamic>.from(json['settlement'] as Map)
        : const <String, dynamic>{};
    final verificationStatus =
        _stringOrNull(
          account['verificationStatus'] ??
              account['status'] ??
              json['settlementAccountVerificationStatus'] ??
              json['verificationStatus'],
        ) ??
        (account['isVerified'] == true || json['isVerified'] == true
            ? 'Approved'
            : null);
    final isVerified =
        account['isVerified'] == true ||
        json['isSettlementAccountVerified'] == true ||
        json['settlementAccountIsVerified'] == true ||
        json['isVerified'] == true ||
        verificationStatus == 'Approved' ||
        verificationStatus == 'Verified';
    return DeliveryProfile(
      status: '${json['status'] ?? json['approvalStatus'] ?? 'Pending'}',
      isOnline: json['isOnline'] == true,
      hasSettlementAccount: account.isNotEmpty ||
          json['hasSettlementAccount'] == true ||
          verificationStatus != null,
      isSettlementAccountVerified: isVerified,
      settlementAccountVerificationStatus: verificationStatus,
      settlementAccountRejectionReason: _stringOrNull(
        account['rejectionReason'] ??
            account['rejectedReason'] ??
            account['verificationRejectionReason'] ??
            json['settlementAccountRejectionReason'] ??
            json['rejectionReason'],
      ),
      maskedAccountNumber: _stringOrNull(
        account['maskedAccountNumber'] ??
            account['accountNumberMasked'] ??
            account['accountNumber'],
      ),
      maskedDocumentNumber: _stringOrNull(
        account['maskedDocumentNumber'] ??
            account['documentNumberMasked'] ??
            account['documentNumber'],
      ),
      maskedPhone: _stringOrNull(
        account['maskedPhone'] ?? account['phoneMasked'] ?? account['phone'],
      ),
      maskedMercadoPago: _stringOrNull(
        account['maskedMercadoPago'] ??
            account['mercadoPagoMasked'] ??
            account['mercadoPago'],
      ),
      maskedVehiclePlate: _stringOrNull(
        json['maskedVehiclePlate'] ?? json['vehiclePlateMasked'],
      ),
      vehiclePhotoMediaId: _stringOrNull(
        json['vehiclePhotoMediaId'] ?? json['vehiclePhotoId'],
      ),
      kycApproved: json['kycApproved'] == true || json['isKycApproved'] == true,
      canGoOnline: json['canGoOnline'] is bool ? json['canGoOnline'] as bool : null,
      onlineBlockReason: _stringOrNull(
        json['onlineBlockReason'] ?? json['availabilityBlockReason'],
      ),
      lastLatitude: _double(json['lastLatitude'] ?? json['latitude']),
      lastLongitude: _double(json['lastLongitude'] ?? json['longitude']),
      vehicleType: json['vehicleType']?.toString(),
    );
  }
  static DeliveryOrder _order(Map<String, dynamic> json) {
    final delivery = json['delivery'] is Map
        ? Map<String, dynamic>.from(json['delivery'] as Map)
        : const <String, dynamic>{};
    final pricingJson = json['pricing'] is Map
        ? Map<String, dynamic>.from(json['pricing'] as Map)
        : delivery['pricing'] is Map
        ? Map<String, dynamic>.from(delivery['pricing'] as Map)
        : null;
    final pricing = DeliveryPricing.fromJson(pricingJson, fallback: json);
    return DeliveryOrder(
      id: '${json['id'] ?? json['orderId'] ?? ''}',
      status:
          '${delivery['status'] ?? json['deliveryStatus'] ?? json['status'] ?? ''}',
      businessName:
          '${json['businessName'] ?? json['business']?['name'] ?? 'Negocio'}',
      businessAddress:
          '${json['businessAddress'] ?? json['pickupAddress'] ?? ''}',
      deliveryAddress:
          '${delivery['deliveryAddress'] ?? json['deliveryAddress'] ?? json['customerAddress'] ?? ''}',
      reference:
          (json['reference'] ?? json['confirmationCode'] ?? json['publicCode'])
              ?.toString(),
      userCiervoCode:
          (json['customerCiervoCode'] ??
                  json['userCiervoCode'] ??
                  json['userPublicCode'] ??
                  json['ciervoUserCode'])
              ?.toString(),
      customerName: (json['customerName'] ?? json['clientName'])?.toString(),
      conversationId:
          (delivery['conversationId'] ?? json['conversationId'])?.toString(),
      deliveryPin: (delivery['deliveryPin'] ?? json['deliveryPin'])?.toString(),
      pickupPin: (delivery['pickupPin'] ?? json['pickupPin'])?.toString(),
      pricing: pricing,
      unreadCount:
          int.tryParse(
            '${delivery['unreadCount'] ?? json['unreadCount'] ?? 0}',
          ) ??
          0,
      totalAmount: _num(json['totalAmount'] ?? json['amount']),
      productsSubtotal: _num(
        json['productsSubtotal'] ??
            json['productSubtotal'] ??
            json['subtotalProducts'] ??
            json['subtotal'],
      ),
      deliveryFee: pricing.deliveryFee ??
          _num(json['deliveryFee'] ?? json['deliveryAmount']),
      courierEarning: pricing.courierEarning ??
          _num(json['courierEarning'] ?? json['estimatedCourierEarning']),
      platformFee:
          pricing.platformFee ?? _num(json['platformFee']),
      distanceKm: pricing.distanceKm ??
          _double(json['distanceKm'] ?? json['distance']),
      currency: (json['currency'] ?? json['currencyCode'])?.toString(),
      countryCode: json['countryCode']?.toString(),
      publicUrl: (json['publicUrl'] ?? json['publicReceiptUrl'])?.toString(),
      shareTitle: json['shareTitle']?.toString(),
      shareDescription: json['shareDescription']?.toString(),
      shareImageUrl: json['shareImageUrl']?.toString(),
      items: _items(json['items']),
      paymentStatus: _stringOrNull(
        json['paymentStatus'] ?? json['paymentStatusName'],
      ),
      paymentMethod: _stringOrNull(json['paymentMethod']),
      childProfileId: _stringOrNull(json['childProfileId']),
      businessId: _stringOrNull(json['businessId'] ?? json['business']?['id']),
      confirmation: ActionConfirmation.fromJson(
        json,
        fallbackTitle: 'Pedido creado',
        fallbackCode:
            '${json['reference'] ?? json['confirmationCode'] ?? json['publicCode'] ?? json['id'] ?? ''}',
      ),
    );
  }

  static double? _double(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value');
  static num? _num(dynamic value) =>
      value is num ? value : num.tryParse('$value');
  static String? _stringOrNull(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static AvailableDeliveryOrder _availableOrder(Map<String, dynamic> json) {
    final delivery = json['delivery'] is Map
        ? Map<String, dynamic>.from(json['delivery'] as Map)
        : const <String, dynamic>{};
    final pricingJson = json['pricing'] is Map
        ? Map<String, dynamic>.from(json['pricing'] as Map)
        : null;
    final pricing = DeliveryPricing.fromJson(pricingJson, fallback: json);
    return AvailableDeliveryOrder(
      id: '${json['id'] ?? json['orderId'] ?? delivery['orderId'] ?? ''}',
      businessName:
          '${json['businessName'] ?? json['business']?['name'] ?? 'Negocio'}',
      businessAddress:
          '${json['businessAddress'] ?? json['pickupAddress'] ?? ''}',
      deliveryAddress:
          '${delivery['deliveryAddress'] ?? json['deliveryAddress'] ?? json['customerAddress'] ?? ''}',
      distanceKm: pricing.distanceKm ??
          _double(json['distanceKm'] ?? json['distance']),
      courierEarning: pricing.courierEarning ??
          _num(json['courierEarning'] ?? json['estimatedCourierEarning']),
      currency: (json['currency'] ?? json['currencyCode'])?.toString(),
      pricing: pricing,
    );
  }

  static DeliverySettlement _settlement(Map<String, dynamic> json) =>
      DeliverySettlement(
        id: '${json['id'] ?? json['settlementId'] ?? ''}',
        orderId: '${json['orderId'] ?? json['deliveryOrderId'] ?? ''}',
        status: '${json['status'] ?? json['settlementStatus'] ?? ''}',
        createdAt: DateTime.tryParse(
          '${json['createdAt'] ?? json['date'] ?? json['settledAt'] ?? ''}',
        ),
        amount: _num(
          json['amount'] ?? json['courierEarning'] ?? json['earning'],
        ),
        currency: (json['currency'] ?? json['currencyCode'])?.toString(),
      );

  static DeliverySettlementAccountDetails _settlementAccountDetails(
    Map<String, dynamic> json,
  ) => DeliverySettlementAccountDetails(
    status: '${json['status'] ?? json['verificationStatus'] ?? 'Sin registrar'}',
    settlementMethod: _stringOrNull(json['settlementMethod']),
    maskedAccountNumber: _stringOrNull(
      json['maskedAccountNumber'] ?? json['accountNumberMasked'],
    ),
    maskedDocumentNumber: _stringOrNull(
      json['maskedDocumentNumber'] ?? json['documentNumberMasked'],
    ),
    maskedPhone: _stringOrNull(json['maskedPhone'] ?? json['phoneMasked']),
    maskedMercadoPago: _stringOrNull(
      json['maskedMercadoPago'] ?? json['mercadoPagoMasked'],
    ),
    maskedVehiclePlate: _stringOrNull(json['maskedVehiclePlate']),
    rejectionReason: _stringOrNull(json['rejectionReason']),
    bankName: _stringOrNull(json['bankName'] ?? json['bank']),
    accountType: _stringOrNull(json['accountType']),
  );

  static List<DeliveryOrderItem> _items(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().map((json) {
      return DeliveryOrderItem(
        productId: '${json['productId'] ?? json['id'] ?? ''}',
        productName: '${json['productName'] ?? json['name'] ?? 'Producto'}',
        quantity: int.tryParse('${json['quantity'] ?? 0}') ?? 0,
        unitPrice: _num(json['unitPrice'] ?? json['price']) ?? 0,
        totalPrice: _num(json['totalPrice'] ?? json['total']) ?? 0,
      );
    }).toList();
  }

  static DeliveryPaymentResult _paymentResult(Map<String, dynamic> json) {
    return DeliveryPaymentResult(
      paymentStatus:
          '${json['paymentStatus'] ?? json['paymentStatusName'] ?? json['status'] ?? ''}',
      checkoutUrl: _stringOrNull(
        json['checkoutUrl'] ?? json['initPoint'] ?? json['init_point'],
      ),
      paymentMethod: _stringOrNull(json['paymentMethod']),
      message: _stringOrNull(json['message'] ?? json['msg']),
    );
  }

  static String _idempotencyKey(String prefix, String seed) {
    return '$prefix-$seed-${DateTime.now().microsecondsSinceEpoch}';
  }
}
