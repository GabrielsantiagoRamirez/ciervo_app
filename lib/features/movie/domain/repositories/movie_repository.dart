import '../../../../core/result/result.dart';
import '../models/movie_commands.dart';
import '../models/movie_models.dart';

abstract interface class MovieRepository {
  Future<Result<MoviePage>> movies({
    int page,
    int pageSize,
    int? maximumMinimumAge,
    String? search,
  });
  Future<Result<List<MovieShowtime>>> showtimes(String movieId);
  Future<Result<List<MovieSeat>>> seats(String showtimeId);
  Future<Result<MovieRequest>> createRequest(CreateMovieRequestCommand command);
  Future<Result<MovieRequest>> request(String requestId);
  Future<Result<MovieRequest>> approveRequest(
    String requestId,
    DecideMovieRequestCommand command,
  );
  Future<Result<MovieRequest>> rejectRequest(
    String requestId,
    DecideMovieRequestCommand command,
  );
  Future<Result<MovieRequest>> cancelRequest(String requestId);
  Future<Result<void>> shareMovie(ShareMovieCommand command);
  Future<Result<MovieReservation>> createReservation(
    CreateMovieReservationCommand command,
  );
  Future<Result<MovieReservation>> selectSeats(
    String reservationId,
    SelectMovieSeatsCommand command,
  );
  Future<Result<MovieReservation>> payReservation(
    String reservationId,
    PayMovieReservationCommand command,
  );
  Future<Result<MovieQr>> issueQr(String reservationId);
  MovieQr? qrInMemory(String reservationId);
  void forgetQr(String reservationId);
  Future<Result<MovieQrConsumption>> consumeQr(ConsumeMovieQrCommand command);
  Future<Result<MovieHistoryPage>> history({int page, int pageSize});
  Future<Result<MovieEventPage>> pollEvents({required int cursor, int take});
  Stream<MovieEvent> streamEvents({required int cursor});
}
