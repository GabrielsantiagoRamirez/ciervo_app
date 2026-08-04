import '../../../../core/result/result.dart';
import '../entities/marketplace_models.dart';

abstract interface class MarketplaceRepository {
  Future<Result<MarketplaceFeedPage>> feed(MarketplaceFeedQuery query);

  Future<Result<List<MarketplacePromo>>> highlights({int limit = 20});

  Future<Result<List<MarketplacePromo>>> popular({int limit = 20});

  Future<Result<List<MarketplacePromo>>> nearby({
    required double lat,
    required double lng,
    double radio = 10,
    int limit = 20,
  });

  Future<Result<List<MarketplacePromo>>> search(String q, {int limit = 20});

  Future<Result<MarketplaceFiltersCatalog>> filters();

  Future<Result<MarketplacePromo>> promotion(int promotionId);

  Future<Result<List<MarketplacePromo>>> cashbackPromos({int limit = 20});

  Future<Result<List<MarketplacePromo>>> pointsPromos({int limit = 20});

  Future<Result<MarketplaceStore>> scanQr({
    required String qrCode,
    double? latitude,
    double? longitude,
  });

  Future<Result<MarketplaceStore>> storeProfile(
    int storeId, {
    double? lat,
    double? lng,
  });

  Future<Result<MarketplaceStore>> storeByCiervo(
    String ciervoId, {
    double? lat,
    double? lng,
  });

  Future<Result<MarketplaceFeedPage>> storePromotions(
    int storeId, {
    MarketplaceFeedQuery query = const MarketplaceFeedQuery(),
  });

  Future<Result<MarketplaceBenefits>> calculateBenefits({
    required int promotionId,
    int quantity = 1,
    String? paymentMethod,
  });

  Future<Result<void>> recordView(int promotionId);

  Future<Result<void>> recordClick(int promotionId);

  Future<Result<void>> recordShare(int promotionId);

  Future<Result<void>> addFavorite(int promotionId);

  Future<Result<void>> removeFavorite(int promotionId);

  Future<Result<List<MarketplacePromo>>> favorites();

  Future<Result<MarketplaceOrder>> checkout({
    required int promotionId,
    int quantity = 1,
    String paymentMethod = 'CIERVO',
    String? notes,
  });

  Future<Result<MarketplaceOrder>> createOrder({
    required int promotionId,
    int quantity = 1,
    String paymentMethod = 'PENDING',
    String? notes,
  });

  Future<Result<MarketplaceOrder>> payOrder({
    required int orderId,
    String wallet = 'CIERVO',
    String? pin,
  });

  Future<Result<List<MarketplaceOrder>>> orders();

  Future<Result<MarketplaceOrder>> order(int orderId);

  Future<Result<void>> cancelOrder(int orderId);

  Future<Result<MarketplaceReservation>> createReservation({
    required int promotionId,
    required DateTime date,
    String? time,
    int people = 1,
    String? comments,
  });

  Future<Result<void>> confirmReservation(int reservationId);

  Future<Result<void>> cancelReservation(int reservationId);
}
