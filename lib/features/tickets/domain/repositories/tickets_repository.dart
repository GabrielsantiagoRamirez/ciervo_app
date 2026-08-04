import '../../../../core/result/result.dart';
import '../models/ticket_models.dart';

abstract interface class TicketsRepository {
  Future<Result<TicketEventsPage>> events({
    String? city,
    String? category,
    String? date,
    int page,
    int pageSize,
    double? precioMin,
    double? precioMax,
    String? organizer,
    double? latitude,
    double? longitude,
    double? radiusKm,
  });

  Future<Result<List<TicketEventSummary>>> highlights({int limit});
  Future<Result<List<TicketEventSummary>>> nearby({
    required double lat,
    required double lng,
    double radiusKm,
    int limit,
  });
  Future<Result<List<TicketEventSummary>>> recommend({
    double? lat,
    double? lng,
    int limit,
  });
  Future<Result<TicketEventDetail>> eventDetail(String eventId);
  Future<Result<List<TicketSeat>>> seats(String eventId);
  Future<Result<SeatHold>> reserveSeats(String eventId, List<String> seats);
  Future<Result<void>> releaseSeats(String eventId, String holdId);
  Future<Result<TicketOrder>> createTicket(CreateTicketCommand command);
  Future<Result<TicketOrder>> payTicket(PayTicketCommand command);
  Future<Result<TicketOrder>> refundTicket(String ticketId);
  Future<Result<TicketOrder>> cancelTicket(String ticketId);
  Future<Result<List<WalletTicket>>> walletTickets();
  Future<Result<List<WalletTicket>>> walletHistory();
  Future<Result<WalletTicket>> walletTicket(String ticketId);
}
