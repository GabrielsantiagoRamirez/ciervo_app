import '../../domain/models/movie_models.dart';

enum MovieUiStatus {
  initial,
  loading,
  success,
  empty,
  error,
  forbidden,
  expired,
  conflict,
  offline,
}

class MovieState {
  const MovieState({
    this.status = MovieUiStatus.initial,
    this.movies = const [],
    this.showtimes = const [],
    this.seats = const [],
    this.history = const [],
    this.selectedSeatCodes = const {},
    this.request,
    this.reservation,
    this.qr,
    this.consumption,
    this.errorMessage,
    this.catalogPage = 0,
    this.catalogTotalPages = 1,
    this.historyPage = 0,
    this.historyTotalPages = 1,
    this.isLoadingMoreCatalog = false,
    this.isLoadingMoreHistory = false,
  });

  final MovieUiStatus status;
  final List<MovieSummary> movies;
  final List<MovieShowtime> showtimes;
  final List<MovieSeat> seats;
  final List<MovieHistory> history;
  final Set<String> selectedSeatCodes;
  final MovieRequest? request;
  final MovieReservation? reservation;
  final MovieQr? qr;
  final MovieQrConsumption? consumption;
  final String? errorMessage;
  final int catalogPage;
  final int catalogTotalPages;
  final int historyPage;
  final int historyTotalPages;
  final bool isLoadingMoreCatalog;
  final bool isLoadingMoreHistory;

  bool get hasMoreCatalog => catalogPage < catalogTotalPages;
  bool get hasMoreHistory => historyPage < historyTotalPages;

  MovieState copyWith({
    MovieUiStatus? status,
    List<MovieSummary>? movies,
    List<MovieShowtime>? showtimes,
    List<MovieSeat>? seats,
    List<MovieHistory>? history,
    Set<String>? selectedSeatCodes,
    MovieRequest? request,
    MovieReservation? reservation,
    MovieQr? qr,
    MovieQrConsumption? consumption,
    String? errorMessage,
    bool clearError = false,
    bool clearQr = false,
    int? catalogPage,
    int? catalogTotalPages,
    int? historyPage,
    int? historyTotalPages,
    bool? isLoadingMoreCatalog,
    bool? isLoadingMoreHistory,
  }) => MovieState(
    status: status ?? this.status,
    movies: movies ?? this.movies,
    showtimes: showtimes ?? this.showtimes,
    seats: seats ?? this.seats,
    history: history ?? this.history,
    selectedSeatCodes: selectedSeatCodes ?? this.selectedSeatCodes,
    request: request ?? this.request,
    reservation: reservation ?? this.reservation,
    qr: clearQr ? null : qr ?? this.qr,
    consumption: consumption ?? this.consumption,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    catalogPage: catalogPage ?? this.catalogPage,
    catalogTotalPages: catalogTotalPages ?? this.catalogTotalPages,
    historyPage: historyPage ?? this.historyPage,
    historyTotalPages: historyTotalPages ?? this.historyTotalPages,
    isLoadingMoreCatalog: isLoadingMoreCatalog ?? this.isLoadingMoreCatalog,
    isLoadingMoreHistory: isLoadingMoreHistory ?? this.isLoadingMoreHistory,
  );
}
