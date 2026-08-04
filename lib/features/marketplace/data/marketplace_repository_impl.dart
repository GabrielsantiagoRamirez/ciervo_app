import '../../../core/errors/error_mapper.dart';
import '../../../core/result/result.dart';
import '../domain/entities/marketplace_models.dart';
import '../domain/repositories/marketplace_repository.dart';
import 'marketplace_remote_datasource.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  const MarketplaceRepositoryImpl(this._remote);

  final MarketplaceRemoteDataSource _remote;

  @override
  Future<Result<MarketplaceFeedPage>> feed(MarketplaceFeedQuery query) =>
      _guard(() => _remote.feed(query));

  @override
  Future<Result<List<MarketplacePromo>>> highlights({int limit = 20}) =>
      _guard(() => _remote.highlights(limit: limit));

  @override
  Future<Result<List<MarketplacePromo>>> popular({int limit = 20}) =>
      _guard(() => _remote.popular(limit: limit));

  @override
  Future<Result<List<MarketplacePromo>>> nearby({
    required double lat,
    required double lng,
    double radio = 10,
    int limit = 20,
  }) =>
      _guard(
        () => _remote.nearby(lat: lat, lng: lng, radio: radio, limit: limit),
      );

  @override
  Future<Result<List<MarketplacePromo>>> search(String q, {int limit = 20}) =>
      _guard(() => _remote.search(q, limit: limit));

  @override
  Future<Result<MarketplaceFiltersCatalog>> filters() =>
      _guard(_remote.filters);

  @override
  Future<Result<MarketplacePromo>> promotion(int promotionId) =>
      _guard(() => _remote.promotion(promotionId));

  @override
  Future<Result<List<MarketplacePromo>>> cashbackPromos({int limit = 20}) =>
      _guard(() => _remote.cashbackPromos(limit: limit));

  @override
  Future<Result<List<MarketplacePromo>>> pointsPromos({int limit = 20}) =>
      _guard(() => _remote.pointsPromos(limit: limit));

  @override
  Future<Result<MarketplaceStore>> scanQr({
    required String qrCode,
    double? latitude,
    double? longitude,
  }) =>
      _guard(
        () => _remote.scanQr(
          qrCode: qrCode,
          latitude: latitude,
          longitude: longitude,
        ),
      );

  @override
  Future<Result<MarketplaceStore>> storeProfile(
    int storeId, {
    double? lat,
    double? lng,
  }) =>
      _guard(() => _remote.storeProfile(storeId, lat: lat, lng: lng));

  @override
  Future<Result<MarketplaceStore>> storeByCiervo(
    String ciervoId, {
    double? lat,
    double? lng,
  }) =>
      _guard(() => _remote.storeByCiervo(ciervoId, lat: lat, lng: lng));

  @override
  Future<Result<MarketplaceFeedPage>> storePromotions(
    int storeId, {
    MarketplaceFeedQuery query = const MarketplaceFeedQuery(),
  }) =>
      _guard(() => _remote.storePromotions(storeId, query: query));

  @override
  Future<Result<MarketplaceBenefits>> calculateBenefits({
    required int promotionId,
    int quantity = 1,
    String? paymentMethod,
  }) =>
      _guard(
        () => _remote.calculateBenefits(
          promotionId: promotionId,
          quantity: quantity,
          paymentMethod: paymentMethod,
        ),
      );

  @override
  Future<Result<void>> recordView(int promotionId) =>
      _guard(() => _remote.recordView(promotionId));

  @override
  Future<Result<void>> recordClick(int promotionId) =>
      _guard(() => _remote.recordClick(promotionId));

  @override
  Future<Result<void>> recordShare(int promotionId) =>
      _guard(() => _remote.recordShare(promotionId));

  @override
  Future<Result<void>> addFavorite(int promotionId) =>
      _guard(() => _remote.addFavorite(promotionId));

  @override
  Future<Result<void>> removeFavorite(int promotionId) =>
      _guard(() => _remote.removeFavorite(promotionId));

  @override
  Future<Result<List<MarketplacePromo>>> favorites() =>
      _guard(_remote.favorites);

  @override
  Future<Result<MarketplaceOrder>> checkout({
    required int promotionId,
    int quantity = 1,
    String paymentMethod = 'CIERVO',
    String? notes,
  }) =>
      _guard(
        () => _remote.checkout(
          promotionId: promotionId,
          quantity: quantity,
          paymentMethod: paymentMethod,
          notes: notes,
        ),
      );

  @override
  Future<Result<MarketplaceOrder>> createOrder({
    required int promotionId,
    int quantity = 1,
    String paymentMethod = 'PENDING',
    String? notes,
  }) =>
      _guard(
        () => _remote.createOrder(
          promotionId: promotionId,
          quantity: quantity,
          paymentMethod: paymentMethod,
          notes: notes,
        ),
      );

  @override
  Future<Result<MarketplaceOrder>> payOrder({
    required int orderId,
    String wallet = 'CIERVO',
    String? pin,
  }) =>
      _guard(
        () => _remote.payOrder(orderId: orderId, wallet: wallet, pin: pin),
      );

  @override
  Future<Result<List<MarketplaceOrder>>> orders() => _guard(_remote.orders);

  @override
  Future<Result<MarketplaceOrder>> order(int orderId) =>
      _guard(() => _remote.order(orderId));

  @override
  Future<Result<void>> cancelOrder(int orderId) =>
      _guard(() => _remote.cancelOrder(orderId));

  @override
  Future<Result<MarketplaceReservation>> createReservation({
    required int promotionId,
    required DateTime date,
    String? time,
    int people = 1,
    String? comments,
  }) =>
      _guard(
        () => _remote.createReservation(
          promotionId: promotionId,
          date: date,
          time: time,
          people: people,
          comments: comments,
        ),
      );

  @override
  Future<Result<void>> confirmReservation(int reservationId) =>
      _guard(() => _remote.confirmReservation(reservationId));

  @override
  Future<Result<void>> cancelReservation(int reservationId) =>
      _guard(() => _remote.cancelReservation(reservationId));

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
