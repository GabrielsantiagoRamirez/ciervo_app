import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/result/result.dart';
import '../../domain/models/movie_commands.dart';
import '../../domain/models/movie_models.dart';
import '../../domain/repositories/movie_repository.dart';
import 'movie_state.dart';

class MovieCubit extends Cubit<MovieState> {
  MovieCubit(this._repository) : super(const MovieState());

  final MovieRepository _repository;
  static const _pageSize = 20;
  String? _catalogSearch;
  int? _maximumMinimumAge;

  Future<void> loadCatalog({String? search, int? maximumMinimumAge}) async {
    _catalogSearch = search;
    _maximumMinimumAge = maximumMinimumAge;
    _loading();
    _emitResult(
      await _repository.movies(
        page: 1,
        pageSize: _pageSize,
        search: search,
        maximumMinimumAge: maximumMinimumAge,
      ),
      (page) => state.copyWith(
        status: page.items.isEmpty
            ? MovieUiStatus.empty
            : MovieUiStatus.success,
        movies: page.items,
        catalogPage: page.page,
        catalogTotalPages: page.totalPages,
        isLoadingMoreCatalog: false,
        clearError: true,
      ),
    );
  }

  Future<void> loadMoreCatalog() async {
    if (!state.hasMoreCatalog || state.isLoadingMoreCatalog) return;
    emit(state.copyWith(isLoadingMoreCatalog: true, clearError: true));
    final result = await _repository.movies(
      page: state.catalogPage + 1,
      pageSize: _pageSize,
      search: _catalogSearch,
      maximumMinimumAge: _maximumMinimumAge,
    );
    result.when(
      success: (page) => emit(
        state.copyWith(
          status: MovieUiStatus.success,
          movies: [...state.movies, ...page.items],
          catalogPage: page.page,
          catalogTotalPages: page.totalPages,
          isLoadingMoreCatalog: false,
          clearError: true,
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          isLoadingMoreCatalog: false,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> loadShowtimes(String movieId) async {
    _loading();
    _emitResult(
      await _repository.showtimes(movieId),
      (items) => state.copyWith(
        status: items.isEmpty ? MovieUiStatus.empty : MovieUiStatus.success,
        showtimes: items,
        clearError: true,
      ),
    );
  }

  Future<void> loadSeats(String showtimeId) async {
    _loading();
    _emitResult(
      await _repository.seats(showtimeId),
      (items) => state.copyWith(
        status: items.isEmpty ? MovieUiStatus.empty : MovieUiStatus.success,
        seats: items,
        selectedSeatCodes: const {},
        clearError: true,
      ),
    );
  }

  void toggleSeat(MovieSeat seat, {required int ticketCount}) {
    if (!seat.available) return;
    final selected = {...state.selectedSeatCodes};
    if (!selected.remove(seat.code)) {
      if (selected.length >= ticketCount) return;
      selected.add(seat.code);
    }
    emit(state.copyWith(selectedSeatCodes: selected));
  }

  void setSelectedSeatCodes(Iterable<String> codes) {
    emit(state.copyWith(selectedSeatCodes: Set.unmodifiable(codes)));
  }

  Future<void> createRequest(CreateMovieRequestCommand command) async {
    _loading();
    _emitResult(
      await _repository.createRequest(command),
      (value) => state.copyWith(
        status: MovieUiStatus.success,
        request: value,
        clearError: true,
      ),
    );
  }

  Future<void> loadRequest(String requestId) async {
    _loading();
    _emitResult(
      await _repository.request(requestId),
      (value) => state.copyWith(
        status: MovieUiStatus.success,
        request: value,
        clearError: true,
      ),
    );
  }

  Future<void> approveRequest(String requestId) async {
    _loading();
    _emitResult(
      await _repository.approveRequest(
        requestId,
        const DecideMovieRequestCommand(),
      ),
      (value) => state.copyWith(
        status: MovieUiStatus.success,
        request: value,
        clearError: true,
      ),
    );
  }

  Future<void> rejectRequest(String requestId, String? reason) async {
    _loading();
    _emitResult(
      await _repository.rejectRequest(
        requestId,
        DecideMovieRequestCommand(reason: reason),
      ),
      (value) => state.copyWith(
        status: MovieUiStatus.success,
        request: value,
        clearError: true,
      ),
    );
  }

  Future<void> cancelRequest(String requestId) async {
    _loading();
    _emitResult(
      await _repository.cancelRequest(requestId),
      (value) => state.copyWith(
        status: MovieUiStatus.success,
        request: value,
        clearError: true,
      ),
    );
  }

  Future<void> createReservation(CreateMovieReservationCommand command) async {
    _loading();
    _emitResult(
      await _repository.createReservation(command),
      (value) => state.copyWith(
        status: MovieUiStatus.success,
        reservation: value,
        clearError: true,
      ),
    );
  }

  Future<void> holdSelectedSeats() async {
    final reservation = state.reservation;
    if (reservation == null ||
        state.selectedSeatCodes.length != reservation.ticketCount) {
      emit(
        state.copyWith(
          status: MovieUiStatus.error,
          errorMessage: 'Selecciona exactamente los asientos de la reserva.',
        ),
      );
      return;
    }
    _loading();
    _emitResult(
      await _repository.selectSeats(
        reservation.id,
        SelectMovieSeatsCommand.byCodes(state.selectedSeatCodes.toList()),
      ),
      (value) => state.copyWith(
        status: MovieUiStatus.success,
        reservation: value,
        clearError: true,
      ),
    );
  }

  Future<void> payReservation(PayMovieReservationCommand command) async {
    final reservation = state.reservation;
    if (reservation == null) return;
    _loading();
    _emitResult(
      await _repository.payReservation(reservation.id, command),
      (value) => state.copyWith(
        status: MovieUiStatus.success,
        reservation: value,
        clearError: true,
      ),
    );
  }

  Future<void> payReservationById(
    String reservationId,
    PayMovieReservationCommand command,
  ) async {
    _loading();
    _emitResult(
      await _repository.payReservation(reservationId, command),
      (value) => state.copyWith(
        status: MovieUiStatus.success,
        reservation: value,
        clearError: true,
      ),
    );
  }

  Future<void> issueQr(String reservationId) async {
    final existing = _repository.qrInMemory(reservationId);
    if (existing != null) {
      emit(
        state.copyWith(
          status: MovieUiStatus.success,
          qr: existing,
          clearError: true,
        ),
      );
      return;
    }
    _loading();
    _emitResult(
      await _repository.issueQr(reservationId),
      (value) => state.copyWith(
        status: MovieUiStatus.success,
        qr: value,
        clearError: true,
      ),
    );
  }

  void dismissQr() {
    final reservationId = state.qr?.reservationId;
    if (reservationId != null) _repository.forgetQr(reservationId);
    emit(state.copyWith(clearQr: true));
  }

  Future<void> consumeQr(String token) async {
    _loading();
    _emitResult(
      await _repository.consumeQr(ConsumeMovieQrCommand(token)),
      (value) => state.copyWith(
        status: MovieUiStatus.success,
        consumption: value,
        clearError: true,
      ),
    );
  }

  Future<void> loadHistory() async {
    _loading();
    _emitResult(
      await _repository.history(page: 1, pageSize: _pageSize),
      (page) => state.copyWith(
        status: page.items.isEmpty
            ? MovieUiStatus.empty
            : MovieUiStatus.success,
        history: page.items,
        historyPage: page.page,
        historyTotalPages: page.totalPages,
        isLoadingMoreHistory: false,
        clearError: true,
      ),
    );
  }

  Future<void> loadMoreHistory() async {
    if (!state.hasMoreHistory || state.isLoadingMoreHistory) return;
    emit(state.copyWith(isLoadingMoreHistory: true, clearError: true));
    final result = await _repository.history(
      page: state.historyPage + 1,
      pageSize: _pageSize,
    );
    result.when(
      success: (page) => emit(
        state.copyWith(
          status: MovieUiStatus.success,
          history: [...state.history, ...page.items],
          historyPage: page.page,
          historyTotalPages: page.totalPages,
          isLoadingMoreHistory: false,
          clearError: true,
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          isLoadingMoreHistory: false,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  void _loading() =>
      emit(state.copyWith(status: MovieUiStatus.loading, clearError: true));

  void _emitResult<T>(
    Result<T> result,
    MovieState Function(T value) onSuccess,
  ) {
    result.when(
      success: (value) => emit(onSuccess(value)),
      failure: (error) => emit(
        state.copyWith(
          status: _statusFor(error),
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  MovieUiStatus _statusFor(Object error) {
    if (error is! AppException) return MovieUiStatus.error;
    return switch (error.statusCode) {
      403 => MovieUiStatus.forbidden,
      409 => MovieUiStatus.conflict,
      410 => MovieUiStatus.expired,
      null => MovieUiStatus.offline,
      _ => MovieUiStatus.error,
    };
  }
}
