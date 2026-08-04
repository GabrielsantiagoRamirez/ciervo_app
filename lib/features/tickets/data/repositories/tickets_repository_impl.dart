import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/models/ticket_models.dart';
import '../../domain/repositories/tickets_repository.dart';
import '../datasources/tickets_remote_datasource.dart';

class TicketsRepositoryImpl implements TicketsRepository {
  TicketsRepositoryImpl(this._remote);

  final TicketsRemoteDataSource _remote;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<TicketEventsPage>> events({
    String? city,
    String? category,
    String? date,
    int page = 1,
    int pageSize = 20,
    double? precioMin,
    double? precioMax,
    String? organizer,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) => _guard(
    () => _remote.events(
      city: city,
      category: category,
      date: date,
      page: page,
      pageSize: pageSize,
      precioMin: precioMin,
      precioMax: precioMax,
      organizer: organizer,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    ),
  );

  @override
  Future<Result<List<TicketEventSummary>>> highlights({int limit = 20}) =>
      _guard(() => _remote.highlights(limit: limit));

  @override
  Future<Result<List<TicketEventSummary>>> nearby({
    required double lat,
    required double lng,
    double radiusKm = 25,
    int limit = 20,
  }) => _guard(
    () => _remote.nearby(lat: lat, lng: lng, radiusKm: radiusKm, limit: limit),
  );

  @override
  Future<Result<List<TicketEventSummary>>> recommend({
    double? lat,
    double? lng,
    int limit = 20,
  }) => _guard(() => _remote.recommend(lat: lat, lng: lng, limit: limit));

  @override
  Future<Result<TicketEventDetail>> eventDetail(String eventId) =>
      _guard(() => _remote.eventDetail(eventId));

  @override
  Future<Result<List<TicketSeat>>> seats(String eventId) =>
      _guard(() => _remote.seats(eventId));

  @override
  Future<Result<SeatHold>> reserveSeats(String eventId, List<String> seats) =>
      _guard(() => _remote.reserveSeats(eventId, seats));

  @override
  Future<Result<void>> releaseSeats(String eventId, String holdId) =>
      _guard(() => _remote.releaseSeats(eventId, holdId));

  @override
  Future<Result<TicketOrder>> createTicket(CreateTicketCommand command) =>
      _guard(() => _remote.createTicket(command));

  @override
  Future<Result<TicketOrder>> payTicket(PayTicketCommand command) =>
      _guard(() => _remote.payTicket(command));

  @override
  Future<Result<TicketOrder>> refundTicket(String ticketId) =>
      _guard(() => _remote.refundTicket(ticketId));

  @override
  Future<Result<TicketOrder>> cancelTicket(String ticketId) =>
      _guard(() => _remote.cancelTicket(ticketId));

  @override
  Future<Result<List<WalletTicket>>> walletTickets() =>
      _guard(() => _remote.walletTickets());

  @override
  Future<Result<List<WalletTicket>>> walletHistory() =>
      _guard(() => _remote.walletHistory());

  @override
  Future<Result<WalletTicket>> walletTicket(String ticketId) =>
      _guard(() => _remote.walletTicket(ticketId));
}
