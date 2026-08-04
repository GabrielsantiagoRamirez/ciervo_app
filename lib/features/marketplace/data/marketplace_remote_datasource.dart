import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../domain/entities/marketplace_models.dart';
import 'marketplace_json.dart';

class MarketplaceRemoteDataSource {
  const MarketplaceRemoteDataSource(this._client);

  final NetworkClient _client;

  Future<MarketplaceFeedPage> feed(MarketplaceFeedQuery query) async {
    final response = await _client.dio.get<dynamic>(
      '/api/marketplace',
      queryParameters: query.toQueryParameters(),
    );
    return MarketplaceJson.feedFromJson(unwrapApiResponse(response.data));
  }

  Future<List<MarketplacePromo>> highlights({int limit = 20}) async {
    final response = await _client.dio.get<dynamic>(
      '/api/marketplace/highlights',
      queryParameters: {'limit': limit},
    );
    return MarketplaceJson.promoListFromJson(unwrapApiResponse(response.data));
  }

  Future<List<MarketplacePromo>> popular({int limit = 20}) async {
    final response = await _client.dio.get<dynamic>(
      '/api/marketplace/popular',
      queryParameters: {'limit': limit},
    );
    return MarketplaceJson.promoListFromJson(unwrapApiResponse(response.data));
  }

  Future<List<MarketplacePromo>> nearby({
    required double lat,
    required double lng,
    double radio = 10,
    int limit = 20,
  }) async {
    final response = await _client.dio.get<dynamic>(
      '/api/marketplace/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'radio': radio, 'limit': limit},
    );
    return MarketplaceJson.promoListFromJson(unwrapApiResponse(response.data));
  }

  Future<List<MarketplacePromo>> search(String q, {int limit = 20}) async {
    final response = await _client.dio.get<dynamic>(
      '/api/marketplace/search',
      queryParameters: {'q': q, 'limit': limit},
    );
    return MarketplaceJson.promoListFromJson(unwrapApiResponse(response.data));
  }

  Future<MarketplaceFiltersCatalog> filters() async {
    final response = await _client.dio.get<dynamic>('/api/marketplace/filters');
    return MarketplaceJson.filtersFromJson(unwrapApiResponse(response.data));
  }

  Future<MarketplacePromo> promotion(int promotionId) async {
    final response = await _client.dio.get<dynamic>(
      '/api/marketplace/promotions/$promotionId',
    );
    return MarketplaceJson.promoFromJson(
      _map(unwrapApiResponse(response.data)),
    );
  }

  Future<List<MarketplacePromo>> cashbackPromos({int limit = 20}) async {
    final response = await _client.dio.get<dynamic>(
      '/api/marketplace/promotions/cashback',
      queryParameters: {'limit': limit},
    );
    return MarketplaceJson.promoListFromJson(unwrapApiResponse(response.data));
  }

  Future<List<MarketplacePromo>> pointsPromos({int limit = 20}) async {
    final response = await _client.dio.get<dynamic>(
      '/api/marketplace/promotions/points',
      queryParameters: {'limit': limit},
    );
    return MarketplaceJson.promoListFromJson(unwrapApiResponse(response.data));
  }

  Future<MarketplaceStore> scanQr({
    required String qrCode,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _client.dio.post<dynamic>(
      '/api/marketplace/store/scan-qr',
      data: {
        'qrCode': qrCode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
    return MarketplaceJson.storeFromJson(unwrapApiResponse(response.data));
  }

  Future<MarketplaceStore> storeProfile(
    int storeId, {
    double? lat,
    double? lng,
  }) async {
    final response = await _client.dio.get<dynamic>(
      '/api/marketplace/store/$storeId/profile',
      queryParameters: {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
    );
    return MarketplaceJson.storeFromJson(unwrapApiResponse(response.data));
  }

  Future<MarketplaceStore> storeByCiervo(
    String ciervoId, {
    double? lat,
    double? lng,
  }) async {
    final response = await _client.dio.get<dynamic>(
      '/api/marketplace/store/by-ciervo/$ciervoId',
      queryParameters: {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
    );
    return MarketplaceJson.storeFromJson(unwrapApiResponse(response.data));
  }

  Future<MarketplaceFeedPage> storePromotions(
    int storeId, {
    MarketplaceFeedQuery query = const MarketplaceFeedQuery(),
  }) async {
    final response = await _client.dio.get<dynamic>(
      '/api/marketplace/store/$storeId/promotions',
      queryParameters: query.toQueryParameters(),
    );
    return MarketplaceJson.feedFromJson(unwrapApiResponse(response.data));
  }

  Future<MarketplaceBenefits> calculateBenefits({
    required int promotionId,
    int quantity = 1,
    String? paymentMethod,
  }) async {
    final response = await _client.dio.post<dynamic>(
      '/api/marketplace/promotion/calculate-benefits',
      data: {
        'promotionId': promotionId,
        'quantity': quantity,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
      },
    );
    return MarketplaceJson.benefitsFromJson(unwrapApiResponse(response.data));
  }

  Future<void> recordView(int promotionId) async {
    await _client.dio.post<dynamic>(
      '/api/marketplace/promotion/view',
      data: {'promotionId': promotionId},
    );
  }

  Future<void> recordClick(int promotionId) async {
    await _client.dio.post<dynamic>(
      '/api/marketplace/promotion/click',
      data: {'promotionId': promotionId},
    );
  }

  Future<void> recordShare(int promotionId) async {
    await _client.dio.post<dynamic>(
      '/api/marketplace/promotion/share',
      data: {'promotionId': promotionId},
    );
  }

  Future<void> addFavorite(int promotionId) async {
    await _client.dio.post<dynamic>(
      '/api/marketplace/favorites',
      data: {'promotionId': promotionId},
    );
  }

  Future<void> removeFavorite(int promotionId) async {
    await _client.dio.delete<dynamic>(
      '/api/marketplace/favorites/$promotionId',
    );
  }

  Future<List<MarketplacePromo>> favorites() async {
    final response = await _client.dio.get<dynamic>(
      '/api/marketplace/favorites',
    );
    return MarketplaceJson.promoListFromJson(unwrapApiResponse(response.data));
  }

  Future<MarketplaceOrder> checkout({
    required int promotionId,
    int quantity = 1,
    String paymentMethod = 'CIERVO',
    String? notes,
  }) async {
    final response = await _client.dio.post<dynamic>(
      '/api/marketplace/checkout',
      data: {
        'promotionId': promotionId,
        'cantidad': quantity,
        'metodoPago': paymentMethod,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return MarketplaceJson.orderFromJson(unwrapApiResponse(response.data));
  }

  Future<MarketplaceOrder> createOrder({
    required int promotionId,
    int quantity = 1,
    String paymentMethod = 'PENDING',
    String? notes,
  }) async {
    final response = await _client.dio.post<dynamic>(
      '/api/marketplace/order',
      data: {
        'promotionId': promotionId,
        'cantidad': quantity,
        'metodoPago': paymentMethod,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return MarketplaceJson.orderFromJson(unwrapApiResponse(response.data));
  }

  Future<MarketplaceOrder> payOrder({
    required int orderId,
    String wallet = 'CIERVO',
    String? pin,
  }) async {
    final response = await _client.dio.post<dynamic>(
      '/api/marketplace/payment',
      data: {
        'orderId': orderId,
        'wallet': wallet,
        if (pin != null && pin.isNotEmpty) 'pin': pin,
      },
    );
    return MarketplaceJson.orderFromJson(unwrapApiResponse(response.data));
  }

  Future<List<MarketplaceOrder>> orders() async {
    final response = await _client.dio.get<dynamic>('/api/marketplace/orders');
    return MarketplaceJson.orderListFromJson(unwrapApiResponse(response.data));
  }

  Future<MarketplaceOrder> order(int orderId) async {
    final response = await _client.dio.get<dynamic>(
      '/api/marketplace/orders/$orderId',
    );
    return MarketplaceJson.orderFromJson(unwrapApiResponse(response.data));
  }

  Future<void> cancelOrder(int orderId) async {
    await _client.dio.patch<dynamic>('/api/marketplace/orders/$orderId/cancel');
  }

  Future<MarketplaceReservation> createReservation({
    required int promotionId,
    required DateTime date,
    String? time,
    int people = 1,
    String? comments,
  }) async {
    final response = await _client.dio.post<dynamic>(
      '/api/marketplace/reservation',
      data: {
        'promotionId': promotionId,
        'date': date.toIso8601String().split('T').first,
        if (time != null && time.isNotEmpty) 'time': time,
        'people': people,
        if (comments != null && comments.isNotEmpty) 'comments': comments,
      },
    );
    return MarketplaceJson.reservationFromJson(
      unwrapApiResponse(response.data),
    );
  }

  Future<void> confirmReservation(int reservationId) async {
    await _client.dio.put<dynamic>(
      '/api/marketplace/reservation/$reservationId/confirm',
    );
  }

  Future<void> cancelReservation(int reservationId) async {
    await _client.dio.delete<dynamic>(
      '/api/marketplace/reservation/$reservationId',
    );
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}
