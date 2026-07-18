import 'package:ciervo_clud/core/errors/app_exception.dart';
import 'package:ciervo_clud/core/result/result.dart';
import 'package:ciervo_clud/features/movie/domain/models/movie_commands.dart';
import 'package:ciervo_clud/features/movie/domain/models/movie_models.dart';
import 'package:ciervo_clud/features/movie/domain/repositories/movie_repository.dart';
import 'package:ciervo_clud/features/movie/presentation/cubit/movie_cubit.dart';
import 'package:ciervo_clud/features/movie/presentation/cubit/movie_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'pagina catálogo e historial incrementalmente y conserva filtro Kid',
    () async {
      final repository = _PagingRepository();
      final cubit = MovieCubit(repository);

      await cubit.loadCatalog(maximumMinimumAge: 12);
      await cubit.loadMoreCatalog();
      await cubit.loadHistory();
      await cubit.loadMoreHistory();

      expect(cubit.state.movies.map((item) => item.title), [
        'Película 1',
        'Película 2',
      ]);
      expect(cubit.state.history, hasLength(2));
      expect(repository.catalogCalls, [(1, 12), (2, 12)]);
      expect(repository.historyPages, [1, 2]);
    },
  );

  test('retry de creación reutiliza el mismo comando idempotente', () async {
    final repository = _RetryRepository();
    final cubit = MovieCubit(repository);
    final command = CreateMovieRequestCommand(
      conversationId: 44,
      showtimeId: '33333333-3333-3333-3333-333333333333',
      ticketCount: 2,
      idempotencyKey: 'movie-request-stable-0001',
    );

    await cubit.createRequest(command);
    expect(cubit.state.status, MovieUiStatus.error);
    await cubit.createRequest(command);

    expect(cubit.state.request?.status, MovieRequestStatus.pending);
    expect(repository.keys, [
      'movie-request-stable-0001',
      'movie-request-stable-0001',
    ]);
  });

  test('expone estados UI diferenciados para 409 y 410', () async {
    final conflict = MovieCubit(_QrErrorRepository(409));
    final expired = MovieCubit(_QrErrorRepository(410));
    final token = List.filled(20, 'x').join();

    await conflict.consumeQr(token);
    await expired.consumeQr(token);

    expect(conflict.state.status, MovieUiStatus.conflict);
    expect(expired.state.status, MovieUiStatus.expired);
  });
}

class _PagingRepository implements MovieRepository {
  final List<(int, int?)> catalogCalls = [];
  final List<int> historyPages = [];

  @override
  Future<Result<MoviePage>> movies({
    int page = 1,
    int pageSize = 20,
    int? maximumMinimumAge,
    String? search,
  }) async {
    catalogCalls.add((page, maximumMinimumAge));
    return Success(
      MoviePage(
        page: page,
        pageSize: pageSize,
        total: 2,
        totalPages: 2,
        items: [
          MovieSummary(
            id: '$page',
            title: 'Película $page',
            minimumAge: 7,
            durationMinutes: 90,
            language: 'ES',
          ),
        ],
      ),
    );
  }

  @override
  Future<Result<MovieHistoryPage>> history({
    int page = 1,
    int pageSize = 20,
  }) async {
    historyPages.add(page);
    return Success(
      MovieHistoryPage(
        page: page,
        pageSize: pageSize,
        total: 2,
        totalPages: 2,
        items: [_history('$page')],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RetryRepository implements MovieRepository {
  final List<String> keys = [];

  @override
  Future<Result<MovieRequest>> createRequest(
    CreateMovieRequestCommand command,
  ) async {
    keys.add(command.idempotencyKey);
    if (keys.length == 1) {
      return const Failure(
        AppException(message: 'Error temporal', statusCode: 500),
      );
    }
    return Success(_request());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _QrErrorRepository implements MovieRepository {
  _QrErrorRepository(this.statusCode);
  final int statusCode;

  @override
  Future<Result<MovieQrConsumption>> consumeQr(
    ConsumeMovieQrCommand command,
  ) async => Failure(
    AppException(
      message: statusCode == 409 ? 'QR ya consumido' : 'QR vencido',
      statusCode: statusCode,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MovieRequest _request() => const MovieRequest(
  id: 'request-1',
  movieId: 'movie-1',
  cinemaId: 'cinema-1',
  showtimeId: '33333333-3333-3333-3333-333333333333',
  ticketCount: 2,
  amount: 20000,
  currency: 'COP',
  status: MovieRequestStatus.pending,
);

MovieHistory _history(String id) => MovieHistory(
  reservation: MovieReservation(
    id: id,
    movieId: 'movie-$id',
    movieTitle: 'Película $id',
    cinemaId: 'cinema',
    cinemaName: 'Cine',
    hallId: 'hall',
    hallName: 'Sala',
    ticketCount: 1,
    totalAmount: 10000,
    currency: 'COP',
    status: MovieReservationStatus.confirmed,
    seats: const [],
  ),
  admissionQrIssued: true,
  admissionConsumed: false,
);
