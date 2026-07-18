import 'dart:convert';

enum CinemaSeatType {
  unknown(0),
  standard(1),
  premium(2),
  accessible(3),
  companion(4);

  const CinemaSeatType(this.value);
  final int value;
  static CinemaSeatType fromJson(Object? value) =>
      values.where((item) => item.value == _int(value)).firstOrNull ?? unknown;
}

enum MovieRequestStatus {
  unknown(0),
  pending(1),
  approved(2),
  rejected(3),
  cancelled(4),
  expired(5),
  reserved(6);

  const MovieRequestStatus(this.value);
  final int value;
  static MovieRequestStatus fromJson(Object? value) =>
      values.where((item) => item.value == _int(value)).firstOrNull ?? unknown;

  String get label => switch (this) {
    pending => 'Pendiente',
    approved => 'Aprobada',
    rejected => 'Rechazada',
    cancelled => 'Cancelada',
    expired => 'Vencida',
    reserved => 'Reservada',
    unknown => 'Desconocido',
  };
}

enum MovieReservationStatus {
  unknown(0),
  draft(1),
  seatsHeld(2),
  pendingPayment(3),
  confirmed(4),
  cancelled(5),
  expired(6),
  refunded(7),
  completed(8);

  const MovieReservationStatus(this.value);
  final int value;
  static MovieReservationStatus fromJson(Object? value) =>
      values.where((item) => item.value == _int(value)).firstOrNull ?? unknown;

  String get label => switch (this) {
    draft => 'Borrador',
    seatsHeld => 'Asientos retenidos',
    pendingPayment => 'Pendiente de pago',
    confirmed => 'Confirmada',
    cancelled => 'Cancelada',
    expired => 'Vencida',
    refunded => 'Reembolsada',
    completed => 'Completada',
    unknown => 'Desconocido',
  };
}

enum MovieAdmissionQrStatus {
  unknown(0),
  active(1),
  consumed(2),
  expired(3),
  revoked(4);

  const MovieAdmissionQrStatus(this.value);
  final int value;
  static MovieAdmissionQrStatus fromJson(Object? value) =>
      values.where((item) => item.value == _int(value)).firstOrNull ?? unknown;
}

enum MoviePaymentMethod {
  unknown(0),
  wallet(1);

  const MoviePaymentMethod(this.value);
  final int value;
  static MoviePaymentMethod fromJson(Object? value) =>
      values.where((item) => item.value == _int(value)).firstOrNull ?? unknown;
}

class MovieSummary {
  const MovieSummary({
    required this.id,
    required this.title,
    required this.minimumAge,
    required this.durationMinutes,
    required this.language,
    this.description,
    this.imageUrl,
  });

  factory MovieSummary.fromJson(Map<String, dynamic> json) => MovieSummary(
    id: _string(json['id']),
    title: _string(json['title']),
    description: _nullableString(json['description']),
    minimumAge: _int(json['minimumAge']),
    durationMinutes: _int(json['durationMinutes']),
    language: _string(json['language']),
    imageUrl: _nullableString(json['imageUrl']),
  );

  final String id;
  final String title;
  final String? description;
  final int minimumAge;
  final int durationMinutes;
  final String language;
  final String? imageUrl;
}

class MoviePage {
  const MoviePage({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory MoviePage.fromJson(Map<String, dynamic> json) => MoviePage(
    page: _int(json['page'], 1),
    pageSize: _int(json['pageSize'], 20),
    total: _int(json['total']),
    totalPages: _int(json['totalPages']),
    items: _maps(json['items']).map(MovieSummary.fromJson).toList(),
  );

  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final List<MovieSummary> items;
}

class MovieShowtime {
  const MovieShowtime({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    required this.cinemaId,
    required this.cinemaName,
    required this.hallId,
    required this.hallName,
    required this.startsAt,
    required this.endsAt,
    required this.basePrice,
    required this.currency,
    required this.availableSeats,
  });

  factory MovieShowtime.fromJson(Map<String, dynamic> json) => MovieShowtime(
    id: _string(json['id']),
    movieId: _string(json['movieId']),
    movieTitle: _string(json['movieTitle']),
    cinemaId: _string(json['cinemaId']),
    cinemaName: _string(json['cinemaName']),
    hallId: _string(json['hallId']),
    hallName: _string(json['hallName']),
    startsAt: _date(json['startsAt']),
    endsAt: _date(json['endsAt']),
    basePrice: _double(json['basePrice']),
    currency: _string(json['currency']),
    availableSeats: _int(json['availableSeats']),
  );

  final String id;
  final String movieId;
  final String movieTitle;
  final String cinemaId;
  final String cinemaName;
  final String hallId;
  final String hallName;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final double basePrice;
  final String currency;
  final int availableSeats;
}

class MovieSeat {
  const MovieSeat({
    required this.seatId,
    required this.code,
    required this.row,
    required this.number,
    required this.type,
    required this.price,
    required this.available,
  });

  factory MovieSeat.fromJson(Map<String, dynamic> json) => MovieSeat(
    seatId: _string(json['seatId']),
    code: _string(json['code']),
    row: _string(json['row']),
    number: _int(json['number']),
    type: CinemaSeatType.fromJson(json['type']),
    price: _double(json['price']),
    available: _bool(json['available']),
  );

  final String seatId;
  final String code;
  final String row;
  final int number;
  final CinemaSeatType type;
  final double price;
  final bool available;
}

class MovieRequest {
  const MovieRequest({
    required this.id,
    required this.movieId,
    required this.cinemaId,
    required this.showtimeId,
    required this.ticketCount,
    required this.amount,
    required this.currency,
    required this.status,
    this.requesterUserId,
    this.requesterRole,
    this.approverUserId,
    this.approverRole,
    this.childProfileId,
    this.decisionReason,
    this.createdAt,
    this.expiresAt,
    this.reservationId,
    this.paymentMethod,
  });

  factory MovieRequest.fromJson(Map<String, dynamic> json) => MovieRequest(
    id: _string(json['id'] ?? json['requestId']),
    movieId: _string(json['movieId']),
    cinemaId: _string(json['cinemaId']),
    showtimeId: _string(json['showtimeId']),
    requesterUserId: _nullableString(json['requesterUserId']),
    requesterRole: _nullableInt(json['requesterRole']),
    approverUserId: _nullableString(json['approverUserId']),
    approverRole: _nullableInt(json['approverRole']),
    childProfileId: _nullableString(json['childProfileId']),
    ticketCount: _int(json['ticketCount']),
    amount: _double(json['amount']),
    currency: _string(json['currency']),
    status: MovieRequestStatus.fromJson(json['status']),
    decisionReason: _nullableString(json['decisionReason']),
    createdAt: _date(json['createdAt']),
    expiresAt: _date(json['expiresAt']),
    reservationId: _nullableString(json['reservationId']),
    paymentMethod: json['paymentMethod'] == null
        ? null
        : MoviePaymentMethod.fromJson(json['paymentMethod']),
  );

  final String id;
  final String movieId;
  final String cinemaId;
  final String showtimeId;
  final String? requesterUserId;
  final int? requesterRole;
  final String? approverUserId;
  final int? approverRole;
  final String? childProfileId;
  final int ticketCount;
  final double amount;
  final String currency;
  final MovieRequestStatus status;
  final String? decisionReason;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final String? reservationId;
  final MoviePaymentMethod? paymentMethod;
}

class ReservedMovieSeat {
  const ReservedMovieSeat({
    required this.seatId,
    required this.code,
    this.type = CinemaSeatType.unknown,
    this.price = 0,
  });

  factory ReservedMovieSeat.fromJson(Map<String, dynamic> json) =>
      ReservedMovieSeat(
        seatId: _string(json['seatId'] ?? json['showtimeSeatId']),
        code: _string(json['code']),
        type: CinemaSeatType.fromJson(json['type']),
        price: _double(json['price']),
      );

  final String seatId;
  final String code;
  final CinemaSeatType type;
  final double price;
}

class MovieReservation {
  const MovieReservation({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    required this.cinemaId,
    required this.cinemaName,
    required this.hallId,
    required this.hallName,
    required this.ticketCount,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.seats,
    this.showtimeId,
    this.showtimeStartsAt,
    this.movieRequestId,
    this.ownerUserId,
    this.ownerRole,
    this.payerUserId,
    this.payerRole,
    this.childProfileId,
    this.expiresAt,
    this.paidAt,
    this.paymentMethod,
    this.paymentReference,
  });

  factory MovieReservation.fromJson(Map<String, dynamic> json) =>
      MovieReservation(
        id: _string(json['id'] ?? json['reservationId']),
        movieId: _string(json['movieId']),
        movieTitle: _string(json['movieTitle']),
        cinemaId: _string(json['cinemaId']),
        cinemaName: _string(json['cinemaName']),
        hallId: _string(json['hallId']),
        hallName: _string(json['hallName']),
        showtimeId: _nullableString(json['showtimeId']),
        showtimeStartsAt: _date(json['showtimeStartsAt']),
        movieRequestId: _nullableString(json['movieRequestId']),
        ownerUserId: _nullableString(json['ownerUserId']),
        ownerRole: _nullableInt(json['ownerRole']),
        payerUserId: _nullableString(json['payerUserId']),
        payerRole: _nullableInt(json['payerRole']),
        childProfileId: _nullableString(json['childProfileId']),
        ticketCount: _int(json['ticketCount']),
        totalAmount: _double(json['totalAmount']),
        currency: _string(json['currency']),
        status: MovieReservationStatus.fromJson(json['status']),
        expiresAt: _date(json['expiresAt']),
        paidAt: _date(json['paidAt']),
        paymentMethod: json['paymentMethod'] == null
            ? null
            : MoviePaymentMethod.fromJson(json['paymentMethod']),
        paymentReference: _nullableString(json['paymentReference']),
        seats: _maps(json['seats']).map(ReservedMovieSeat.fromJson).toList(),
      );

  final String id;
  final String movieId;
  final String movieTitle;
  final String cinemaId;
  final String cinemaName;
  final String hallId;
  final String hallName;
  final String? showtimeId;
  final DateTime? showtimeStartsAt;
  final String? movieRequestId;
  final String? ownerUserId;
  final int? ownerRole;
  final String? payerUserId;
  final int? payerRole;
  final String? childProfileId;
  final int ticketCount;
  final double totalAmount;
  final String currency;
  final MovieReservationStatus status;
  final DateTime? expiresAt;
  final DateTime? paidAt;
  final MoviePaymentMethod? paymentMethod;
  final String? paymentReference;
  final List<ReservedMovieSeat> seats;
}

/// Secreto efímero: el repositorio lo conserva únicamente en memoria.
class MovieQr {
  const MovieQr({
    required this.qrId,
    required this.reservationId,
    required this.token,
    required this.expiresAt,
    required this.imageBase64,
    required this.imageDataUrl,
  });

  factory MovieQr.fromJson(Map<String, dynamic> json) => MovieQr(
    qrId: _string(json['qrId']),
    reservationId: _string(json['reservationId']),
    token: _string(json['token']),
    expiresAt: _date(json['expiresAt']),
    imageBase64: _string(json['imageBase64']),
    imageDataUrl: _string(json['imageDataUrl']),
  );

  final String qrId;
  final String reservationId;
  final String token;
  final DateTime? expiresAt;
  final String imageBase64;
  final String imageDataUrl;
}

class MovieQrConsumption {
  const MovieQrConsumption({
    required this.qrId,
    required this.reservationId,
    required this.consumedAt,
  });

  factory MovieQrConsumption.fromJson(Map<String, dynamic> json) =>
      MovieQrConsumption(
        qrId: _string(json['qrId']),
        reservationId: _string(json['reservationId']),
        consumedAt: _date(json['consumedAt']),
      );

  final String qrId;
  final String reservationId;
  final DateTime? consumedAt;
}

class MovieHistory {
  const MovieHistory({
    required this.reservation,
    required this.admissionQrIssued,
    required this.admissionConsumed,
  });

  factory MovieHistory.fromJson(Map<String, dynamic> json) => MovieHistory(
    reservation: MovieReservation.fromJson(_map(json['reservation'])),
    admissionQrIssued: _bool(json['admissionQrIssued']),
    admissionConsumed: _bool(json['admissionConsumed']),
  );

  final MovieReservation reservation;
  final bool admissionQrIssued;
  final bool admissionConsumed;
}

class MovieHistoryPage {
  const MovieHistoryPage({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory MovieHistoryPage.fromJson(Map<String, dynamic> json) =>
      MovieHistoryPage(
        page: _int(json['page'], 1),
        pageSize: _int(json['pageSize'], 20),
        total: _int(json['total']),
        totalPages: _int(json['totalPages']),
        items: _maps(json['items']).map(MovieHistory.fromJson).toList(),
      );

  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final List<MovieHistory> items;
}

class MovieEvent {
  const MovieEvent({
    required this.cursor,
    required this.aggregateId,
    required this.aggregateType,
    required this.eventType,
    required this.payloadJson,
    required this.createdAt,
  });

  factory MovieEvent.fromJson(Map<String, dynamic> json) => MovieEvent(
    cursor: _int(json['cursor']),
    aggregateId: _string(json['aggregateId']),
    aggregateType: _string(json['aggregateType']),
    eventType: _string(json['eventType']),
    payloadJson: _nullableString(json['payloadJson']),
    createdAt: _date(json['createdAt']),
  );

  final int cursor;
  final String aggregateId;
  final String aggregateType;
  final String eventType;
  final String? payloadJson;
  final DateTime? createdAt;

  Map<String, dynamic>? get payload {
    final raw = payloadJson;
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }
}

class MovieEventPage {
  const MovieEventPage({
    required this.nextCursor,
    required this.hasMore,
    required this.items,
  });

  factory MovieEventPage.fromJson(Map<String, dynamic> json) => MovieEventPage(
    nextCursor: _int(json['nextCursor']),
    hasMore: _bool(json['hasMore']),
    items: _maps(json['items']).map(MovieEvent.fromJson).toList(),
  );

  final int nextCursor;
  final bool hasMore;
  final List<MovieEvent> items;
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
List<Map<String, dynamic>> _maps(Object? value) =>
    value is Iterable ? value.map(_map).toList(growable: false) : const [];
String _string(Object? value) => value?.toString() ?? '';
String? _nullableString(Object? value) {
  final result = value?.toString().trim();
  return result == null || result.isEmpty ? null : result;
}

int _int(Object? value, [int fallback = 0]) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;
int? _nullableInt(Object? value) {
  if (value == null) return null;
  return value is num ? value.toInt() : int.tryParse(value.toString());
}

double _double(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
bool _bool(Object? value) =>
    value == true || value == 1 || value?.toString().toLowerCase() == 'true';
DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString())?.toUtc();
