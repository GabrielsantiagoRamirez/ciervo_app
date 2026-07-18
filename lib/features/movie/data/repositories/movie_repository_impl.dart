import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/models/movie_commands.dart';
import '../../domain/models/movie_models.dart';
import '../../domain/repositories/movie_repository.dart';
import '../datasources/movie_remote_datasource.dart';

class MovieRepositoryImpl implements MovieRepository {
  MovieRepositoryImpl(this._remote);

  final MovieRemoteDataSource _remote;
  final Map<String, MovieQr> _ephemeralQrs = {};

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<MoviePage>> movies({
    int page = 1,
    int pageSize = 20,
    int? maximumMinimumAge,
    String? search,
  }) => _guard(
    () => _remote.movies(
      page: page,
      pageSize: pageSize,
      maximumMinimumAge: maximumMinimumAge,
      search: search,
    ),
  );

  @override
  Future<Result<List<MovieShowtime>>> showtimes(String movieId) =>
      _guard(() => _remote.showtimes(movieId));

  @override
  Future<Result<List<MovieSeat>>> seats(String showtimeId) =>
      _guard(() => _remote.seats(showtimeId));

  @override
  Future<Result<MovieRequest>> createRequest(
    CreateMovieRequestCommand command,
  ) => _guard(() => _remote.createRequest(command));

  @override
  Future<Result<MovieRequest>> request(String requestId) =>
      _guard(() => _remote.request(requestId));

  @override
  Future<Result<MovieRequest>> approveRequest(
    String requestId,
    DecideMovieRequestCommand command,
  ) => _guard(() => _remote.approveRequest(requestId, command));

  @override
  Future<Result<MovieRequest>> rejectRequest(
    String requestId,
    DecideMovieRequestCommand command,
  ) => _guard(() => _remote.rejectRequest(requestId, command));

  @override
  Future<Result<MovieRequest>> cancelRequest(String requestId) =>
      _guard(() => _remote.cancelRequest(requestId));

  @override
  Future<Result<void>> shareMovie(ShareMovieCommand command) =>
      _guard(() => _remote.shareMovie(command));

  @override
  Future<Result<MovieReservation>> createReservation(
    CreateMovieReservationCommand command,
  ) => _guard(() => _remote.createReservation(command));

  @override
  Future<Result<MovieReservation>> selectSeats(
    String reservationId,
    SelectMovieSeatsCommand command,
  ) => _guard(() => _remote.selectSeats(reservationId, command));

  @override
  Future<Result<MovieReservation>> payReservation(
    String reservationId,
    PayMovieReservationCommand command,
  ) => _guard(() => _remote.payReservation(reservationId, command));

  @override
  Future<Result<MovieQr>> issueQr(String reservationId) async {
    final result = await _guard(() => _remote.issueQr(reservationId));
    if (result case Success<MovieQr>(:final value)) {
      _ephemeralQrs[reservationId] = value;
    }
    return result;
  }

  @override
  MovieQr? qrInMemory(String reservationId) => _ephemeralQrs[reservationId];

  @override
  void forgetQr(String reservationId) => _ephemeralQrs.remove(reservationId);

  @override
  Future<Result<MovieQrConsumption>> consumeQr(ConsumeMovieQrCommand command) =>
      _guard(() => _remote.consumeQr(command));

  @override
  Future<Result<MovieHistoryPage>> history({int page = 1, int pageSize = 20}) =>
      _guard(() => _remote.history(page: page, pageSize: pageSize));

  @override
  Future<Result<MovieEventPage>> pollEvents({
    required int cursor,
    int take = 100,
  }) => _guard(() => _remote.pollEvents(cursor: cursor, take: take));

  @override
  Stream<MovieEvent> streamEvents({required int cursor}) =>
      _remote.streamEvents(cursor: cursor);
}
