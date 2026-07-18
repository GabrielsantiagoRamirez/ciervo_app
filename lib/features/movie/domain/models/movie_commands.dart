import 'movie_models.dart';

abstract interface class MovieCommand {
  Map<String, dynamic> toJson();
}

class CreateMovieRequestCommand implements MovieCommand {
  CreateMovieRequestCommand({
    required this.conversationId,
    required this.showtimeId,
    required this.ticketCount,
    required this.idempotencyKey,
    this.movieId,
    this.cinemaId,
    this.ciervoId,
    this.seatType,
  }) {
    _requireId(conversationId, 'conversationId');
    _requireGuid(showtimeId, 'showtimeId');
    _tickets(ticketCount);
    _key(idempotencyKey);
  }

  final int conversationId;
  final String showtimeId;
  final int ticketCount;
  final String idempotencyKey;
  final String? movieId;
  final String? cinemaId;
  final String? ciervoId;
  final CinemaSeatType? seatType;

  @override
  Map<String, dynamic> toJson() => {
    'conversationId': conversationId,
    'movieId': movieId,
    'cinemaId': cinemaId,
    'showtimeId': showtimeId,
    'ticketCount': ticketCount,
    'seatType': seatType?.value,
    'ciervoId': ciervoId,
    'idempotencyKey': idempotencyKey,
  };
}

class DecideMovieRequestCommand implements MovieCommand {
  const DecideMovieRequestCommand({
    this.reason,
    this.paymentMethod = MoviePaymentMethod.wallet,
  });

  final String? reason;
  final MoviePaymentMethod paymentMethod;

  @override
  Map<String, dynamic> toJson() => {
    if (reason != null && reason!.trim().isNotEmpty) 'reason': reason!.trim(),
    'paymentMethod': paymentMethod.value,
  };
}

class ShareMovieCommand implements MovieCommand {
  ShareMovieCommand({
    required this.conversationId,
    required this.movieId,
    this.ciervoId,
    this.message,
  }) {
    _requireId(conversationId, 'conversationId');
    _requireGuid(movieId, 'movieId');
    if ((message?.length ?? 0) > 500) {
      throw ArgumentError.value(message, 'message', 'máximo 500 caracteres');
    }
  }

  final int conversationId;
  final String movieId;
  final String? ciervoId;
  final String? message;

  @override
  Map<String, dynamic> toJson() => {
    'conversationId': conversationId,
    'movieId': movieId,
    'ciervoId': ciervoId,
    'message': message,
  };
}

class CreateMovieReservationCommand implements MovieCommand {
  CreateMovieReservationCommand({
    required this.showtimeId,
    required this.ticketCount,
    required this.idempotencyKey,
    this.movieId,
    this.cinemaId,
    this.movieRequestId,
    this.seatType,
    this.ciervoId,
  }) {
    _requireGuid(showtimeId, 'showtimeId');
    _tickets(ticketCount);
    _key(idempotencyKey);
  }

  final String showtimeId;
  final String? movieId;
  final String? cinemaId;
  final String? movieRequestId;
  final int ticketCount;
  final CinemaSeatType? seatType;
  final String? ciervoId;
  final String idempotencyKey;

  @override
  Map<String, dynamic> toJson() => {
    'showtimeId': showtimeId,
    'movieId': movieId,
    'cinemaId': cinemaId,
    'movieRequestId': movieRequestId,
    'ticketCount': ticketCount,
    'seatType': seatType?.value,
    'ciervoId': ciervoId,
    'idempotencyKey': idempotencyKey,
  };
}

class SelectMovieSeatsCommand implements MovieCommand {
  SelectMovieSeatsCommand.byCodes(List<String> values)
    : codes = List.unmodifiable(values),
      showtimeSeatIds = const [] {
    _validate();
  }

  SelectMovieSeatsCommand.byIds(List<String> values)
    : showtimeSeatIds = List.unmodifiable(values),
      codes = const [] {
    _validate();
  }

  final List<String> showtimeSeatIds;
  final List<String> codes;

  void _validate() {
    final selected = showtimeSeatIds.isNotEmpty ? showtimeSeatIds : codes;
    if (selected.isEmpty || selected.length > 20) {
      throw ArgumentError('Selecciona entre 1 y 20 asientos.');
    }
    if (selected.any((value) => value.trim().isEmpty) ||
        selected.map((value) => value.trim().toUpperCase()).toSet().length !=
            selected.length) {
      throw ArgumentError('Los asientos deben ser únicos y no vacíos.');
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    'showtimeSeatIds': showtimeSeatIds,
    'codes': codes,
  };
}

class PayMovieReservationCommand implements MovieCommand {
  PayMovieReservationCommand({
    required this.idempotencyKey,
    this.walletCardId,
  }) {
    _key(idempotencyKey);
  }

  final String? walletCardId;
  final String idempotencyKey;

  @override
  Map<String, dynamic> toJson() => {
    'paymentMethod': MoviePaymentMethod.wallet.value,
    'walletCardId': walletCardId,
    'idempotencyKey': idempotencyKey,
  };
}

class ConsumeMovieQrCommand implements MovieCommand {
  ConsumeMovieQrCommand(this.token) {
    if (token.trim().length < 20) {
      throw ArgumentError.value(token, 'token', 'mínimo 20 caracteres');
    }
  }

  final String token;

  @override
  Map<String, dynamic> toJson() => {'token': token.trim()};
}

void _tickets(int value) {
  if (value < 1 || value > 20) {
    throw ArgumentError.value(value, 'ticketCount', 'debe estar entre 1 y 20');
  }
}

void _key(String value) {
  if (value.length < 8 || value.length > 100) {
    throw ArgumentError.value(
      value,
      'idempotencyKey',
      'debe tener entre 8 y 100 caracteres',
    );
  }
}

void _requireId(int value, String name) {
  if (value <= 0) throw ArgumentError.value(value, name, 'debe ser positivo');
}

void _requireGuid(String value, String name) {
  final guid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  if (!guid.hasMatch(value)) {
    throw ArgumentError.value(value, name, 'GUID inválido');
  }
}
