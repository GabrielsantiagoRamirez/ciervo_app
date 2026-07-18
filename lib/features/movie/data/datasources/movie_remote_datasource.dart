import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../domain/models/movie_commands.dart';
import '../../domain/models/movie_models.dart';

abstract interface class MovieRemoteDataSource {
  Future<MoviePage> movies({
    int page,
    int pageSize,
    int? maximumMinimumAge,
    String? search,
  });
  Future<List<MovieShowtime>> showtimes(String movieId);
  Future<List<MovieSeat>> seats(String showtimeId);
  Future<MovieRequest> createRequest(CreateMovieRequestCommand command);
  Future<MovieRequest> request(String requestId);
  Future<MovieRequest> approveRequest(
    String requestId,
    DecideMovieRequestCommand command,
  );
  Future<MovieRequest> rejectRequest(
    String requestId,
    DecideMovieRequestCommand command,
  );
  Future<MovieRequest> cancelRequest(String requestId);
  Future<void> shareMovie(ShareMovieCommand command);
  Future<MovieReservation> createReservation(
    CreateMovieReservationCommand command,
  );
  Future<MovieReservation> selectSeats(
    String reservationId,
    SelectMovieSeatsCommand command,
  );
  Future<MovieReservation> payReservation(
    String reservationId,
    PayMovieReservationCommand command,
  );
  Future<MovieQr> issueQr(String reservationId);
  Future<MovieQrConsumption> consumeQr(ConsumeMovieQrCommand command);
  Future<MovieHistoryPage> history({int page, int pageSize});
  Future<MovieEventPage> pollEvents({required int cursor, int take});
  Stream<MovieEvent> streamEvents({required int cursor});
}

class DioMovieRemoteDataSource implements MovieRemoteDataSource {
  const DioMovieRemoteDataSource(this._client);

  final NetworkClient _client;
  static const _movie = '/api/v1/movie';
  static const _chatMovie = '/api/v1/chat/movie';

  @override
  Future<MoviePage> movies({
    int page = 1,
    int pageSize = 20,
    int? maximumMinimumAge,
    String? search,
  }) async {
    final response = await _client.dio.get<dynamic>(
      '$_movie/movies',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'maximumMinimumAge': ?maximumMinimumAge,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return MoviePage.fromJson(_valueMap(response.data));
  }

  @override
  Future<List<MovieShowtime>> showtimes(String movieId) async {
    final response = await _client.dio.get<dynamic>(
      '$_movie/movies/$movieId/showtimes',
    );
    return _valueList(response.data).map(MovieShowtime.fromJson).toList();
  }

  @override
  Future<List<MovieSeat>> seats(String showtimeId) async {
    final response = await _client.dio.get<dynamic>(
      '$_movie/showtimes/$showtimeId/seats',
    );
    return _valueList(response.data).map(MovieSeat.fromJson).toList();
  }

  @override
  Future<MovieRequest> createRequest(CreateMovieRequestCommand command) async {
    final response = await _client.dio.post<dynamic>(
      '$_chatMovie/requests',
      data: command.toJson(),
    );
    return MovieRequest.fromJson(_valueMap(response.data));
  }

  @override
  Future<MovieRequest> request(String requestId) async {
    final response = await _client.dio.get<dynamic>(
      '$_chatMovie/requests/$requestId',
    );
    return MovieRequest.fromJson(_valueMap(response.data));
  }

  @override
  Future<MovieRequest> approveRequest(
    String requestId,
    DecideMovieRequestCommand command,
  ) => _decide(requestId, 'approve', command.toJson());

  @override
  Future<MovieRequest> rejectRequest(
    String requestId,
    DecideMovieRequestCommand command,
  ) => _decide(requestId, 'reject', command.toJson());

  @override
  Future<MovieRequest> cancelRequest(String requestId) =>
      _decide(requestId, 'cancel', const <String, dynamic>{});

  Future<MovieRequest> _decide(
    String requestId,
    String action,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.dio.post<dynamic>(
      '$_chatMovie/requests/$requestId/$action',
      data: body,
    );
    return MovieRequest.fromJson(_valueMap(response.data));
  }

  @override
  Future<void> shareMovie(ShareMovieCommand command) async {
    await _client.dio.post<dynamic>(
      '$_chatMovie/share',
      data: command.toJson(),
    );
  }

  @override
  Future<MovieReservation> createReservation(
    CreateMovieReservationCommand command,
  ) async {
    final response = await _client.dio.post<dynamic>(
      '$_movie/reservations',
      data: command.toJson(),
    );
    return MovieReservation.fromJson(_valueMap(response.data));
  }

  @override
  Future<MovieReservation> selectSeats(
    String reservationId,
    SelectMovieSeatsCommand command,
  ) async {
    final response = await _client.dio.put<dynamic>(
      '$_movie/reservations/$reservationId/seats',
      data: command.toJson(),
    );
    return MovieReservation.fromJson(_valueMap(response.data));
  }

  @override
  Future<MovieReservation> payReservation(
    String reservationId,
    PayMovieReservationCommand command,
  ) async {
    final response = await _client.dio.post<dynamic>(
      '$_movie/reservations/$reservationId/payment',
      data: command.toJson(),
    );
    return MovieReservation.fromJson(_valueMap(response.data));
  }

  @override
  Future<MovieQr> issueQr(String reservationId) async {
    final response = await _client.dio.post<dynamic>(
      '$_movie/reservations/$reservationId/qr',
    );
    return MovieQr.fromJson(_valueMap(response.data));
  }

  @override
  Future<MovieQrConsumption> consumeQr(ConsumeMovieQrCommand command) async {
    final response = await _client.dio.post<dynamic>(
      '$_movie/qr/consume',
      data: command.toJson(),
    );
    return MovieQrConsumption.fromJson(_valueMap(response.data));
  }

  @override
  Future<MovieHistoryPage> history({int page = 1, int pageSize = 20}) async {
    final response = await _client.dio.get<dynamic>(
      '$_movie/history',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return MovieHistoryPage.fromJson(_valueMap(response.data));
  }

  @override
  Future<MovieEventPage> pollEvents({
    required int cursor,
    int take = 100,
  }) async {
    final response = await _client.dio.get<dynamic>(
      '$_movie/events',
      queryParameters: {'cursor': cursor, 'take': take.clamp(1, 200)},
    );
    final value = unwrapApiResponse(response.data);
    if (value is List) {
      final items = value
          .whereType<Map>()
          .map((item) => MovieEvent.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      return MovieEventPage(
        nextCursor: items.isEmpty ? cursor : items.last.cursor,
        hasMore: items.length >= take,
        items: items,
      );
    }
    return MovieEventPage.fromJson(_asMap(value));
  }

  @override
  Stream<MovieEvent> streamEvents({required int cursor}) async* {
    final response = await _client.dio.get<ResponseBody>(
      '$_movie/events/stream',
      queryParameters: {'cursor': cursor},
      options: Options(
        responseType: ResponseType.stream,
        headers: const {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ),
    );
    final body = response.data;
    if (body == null) return;

    final lines = body.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    final data = StringBuffer();
    await for (final line in lines) {
      if (line.startsWith('data:')) {
        if (data.isNotEmpty) data.write('\n');
        data.write(line.substring(5).trimLeft());
      } else if (line.isEmpty && data.isNotEmpty) {
        final raw = data.toString();
        data.clear();
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          yield MovieEvent.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
    }
    if (data.isNotEmpty) {
      final decoded = jsonDecode(data.toString());
      if (decoded is Map) {
        yield MovieEvent.fromJson(Map<String, dynamic>.from(decoded));
      }
    }
  }
}

Map<String, dynamic> _valueMap(Object? raw) => _asMap(unwrapApiResponse(raw));

List<Map<String, dynamic>> _valueList(Object? raw) {
  final value = unwrapApiResponse(raw);
  final list = value is List
      ? value
      : value is Map && value['items'] is List
      ? value['items'] as List
      : const <dynamic>[];
  return list
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

Map<String, dynamic> _asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
