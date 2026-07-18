import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/permissions/app_permission_service.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../domain/models/movie_commands.dart';
import '../../domain/models/movie_models.dart';
import '../cubit/movie_cubit.dart';
import '../cubit/movie_state.dart';
import '../widgets/movie_share_sheet.dart';

class MovieCatalogPage extends StatefulWidget {
  const MovieCatalogPage({
    super.key,
    required this.onMovieSelected,
    this.maximumMinimumAge,
    this.onHistoryRequested,
    this.chatRepository,
  });
  final ValueChanged<MovieSummary> onMovieSelected;
  final int? maximumMinimumAge;
  final VoidCallback? onHistoryRequested;
  final ChatRepository? chatRepository;

  @override
  State<MovieCatalogPage> createState() => _MovieCatalogPageState();
}

class _MovieCatalogPageState extends State<MovieCatalogPage> {
  final _search = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_loadMore);
    context.read<MovieCubit>().loadCatalog(
      maximumMinimumAge: widget.maximumMinimumAge,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll
      ..removeListener(_loadMore)
      ..dispose();
    super.dispose();
  }

  void _loadMore() {
    if (_scroll.position.extentAfter < 320) {
      context.read<MovieCubit>().loadMoreCatalog();
    }
  }

  void _openHistory() {
    if (widget.onHistoryRequested != null) {
      widget.onHistoryRequested!();
      return;
    }
    final cubit = context.read<MovieCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const MovieHistoryPageWidget(),
        ),
      ),
    );
  }

  Future<void> _share(MovieSummary movie) async {
    final repository = widget.chatRepository ?? getIt<ChatRepository>();
    final shared = await showMovieShareSheet(
      context: context,
      movie: movie,
      repository: repository,
    );
    if (shared == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Película compartida en el chat.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Películas'),
      actions: [
        IconButton(
          tooltip: 'Ver historial',
          onPressed: _openHistory,
          icon: const Icon(Icons.history),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SearchBar(
            controller: _search,
            hintText: 'Buscar película',
            onSubmitted: (value) => context.read<MovieCubit>().loadCatalog(
              search: value,
              maximumMinimumAge: widget.maximumMinimumAge,
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<MovieCubit, MovieState>(
            builder: (context, state) => _MovieBody(
              state: state,
              retry: () => context.read<MovieCubit>().loadCatalog(
                search: _search.text,
                maximumMinimumAge: widget.maximumMinimumAge,
              ),
              child: ListView.builder(
                controller: _scroll,
                itemCount:
                    state.movies.length + (state.isLoadingMoreCatalog ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.movies.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final movie = state.movies[index];
                  return ListTile(
                    leading: const Icon(Icons.movie_outlined),
                    title: Text(movie.title),
                    subtitle: Text(
                      '${movie.durationMinutes} min · +${movie.minimumAge} · ${movie.language}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Compartir película',
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () => _share(movie),
                    ),
                    onTap: () => widget.onMovieSelected(movie),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class MovieShowtimesPage extends StatefulWidget {
  const MovieShowtimesPage({
    super.key,
    required this.movieId,
    required this.onShowtimeSelected,
  });
  final String movieId;
  final ValueChanged<MovieShowtime> onShowtimeSelected;

  @override
  State<MovieShowtimesPage> createState() => _MovieShowtimesPageState();
}

class _MovieShowtimesPageState extends State<MovieShowtimesPage> {
  @override
  void initState() {
    super.initState();
    context.read<MovieCubit>().loadShowtimes(widget.movieId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Funciones'),
      actions: [
        BlocBuilder<MovieCubit, MovieState>(
          buildWhen: (previous, current) =>
              previous.showtimes != current.showtimes,
          builder: (context, state) {
            final showtime = state.showtimes.firstOrNull;
            return IconButton(
              tooltip: 'Compartir película',
              onPressed: showtime == null
                  ? null
                  : () => showMovieShareSheet(
                      context: context,
                      movie: MovieSummary(
                        id: widget.movieId,
                        title: showtime.movieTitle,
                        minimumAge: 0,
                        durationMinutes: 0,
                        language: '',
                      ),
                      repository: getIt<ChatRepository>(),
                    ),
              icon: const Icon(Icons.share_outlined),
            );
          },
        ),
      ],
    ),
    body: BlocBuilder<MovieCubit, MovieState>(
      builder: (context, state) => _MovieBody(
        state: state,
        retry: () => context.read<MovieCubit>().loadShowtimes(widget.movieId),
        child: ListView.builder(
          itemCount: state.showtimes.length,
          itemBuilder: (context, index) {
            final showtime = state.showtimes[index];
            return ListTile(
              title: Text(showtime.cinemaName),
              subtitle: Text(
                '${showtime.hallName} · ${_date(showtime.startsAt)} · '
                '${showtime.currency} ${showtime.basePrice.toStringAsFixed(0)}',
              ),
              trailing: Text('${showtime.availableSeats} cupos'),
              onTap: () => widget.onShowtimeSelected(showtime),
            );
          },
        ),
      ),
    ),
  );
}

class MovieSeatsPage extends StatefulWidget {
  const MovieSeatsPage({
    super.key,
    required this.showtimeId,
    required this.ticketCount,
    required this.onSelectionReady,
  });
  final String showtimeId;
  final int ticketCount;
  final ValueChanged<List<String>> onSelectionReady;

  @override
  State<MovieSeatsPage> createState() => _MovieSeatsPageState();
}

class _MovieSeatsPageState extends State<MovieSeatsPage> {
  @override
  void initState() {
    super.initState();
    context.read<MovieCubit>().loadSeats(widget.showtimeId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Selecciona asientos')),
    body: BlocBuilder<MovieCubit, MovieState>(
      builder: (context, state) => _MovieBody(
        state: state,
        retry: () => context.read<MovieCubit>().loadSeats(widget.showtimeId),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('PANTALLA', textAlign: TextAlign.center),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: state.seats.length,
                itemBuilder: (context, index) {
                  final seat = state.seats[index];
                  final selected = state.selectedSeatCodes.contains(seat.code);
                  return FilterChip(
                    selected: selected,
                    label: Text(seat.code),
                    onSelected: seat.available
                        ? (_) => context.read<MovieCubit>().toggleSeat(
                            seat,
                            ticketCount: widget.ticketCount,
                          )
                        : null,
                  );
                },
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.all(12),
              child: FilledButton(
                onPressed: state.selectedSeatCodes.length == widget.ticketCount
                    ? () => widget.onSelectionReady(
                        state.selectedSeatCodes.toList(growable: false),
                      )
                    : null,
                child: Text(
                  'Continuar (${state.selectedSeatCodes.length}/${widget.ticketCount})',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class MovieRequestPage extends StatefulWidget {
  const MovieRequestPage({
    super.key,
    this.requestId,
    this.createCommand,
    this.canDecide = false,
    this.onApproved,
    this.onPayReservation,
  });
  final String? requestId;
  final CreateMovieRequestCommand? createCommand;
  final bool canDecide;
  final ValueChanged<MovieRequest>? onApproved;
  final ValueChanged<String>? onPayReservation;

  @override
  State<MovieRequestPage> createState() => _MovieRequestPageState();
}

class _MovieRequestPageState extends State<MovieRequestPage> {
  final _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<MovieCubit>();
    if (widget.requestId != null) {
      cubit.loadRequest(widget.requestId!);
    } else if (widget.createCommand != null) {
      cubit.createRequest(widget.createCommand!);
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Solicitud de cine')),
    body: BlocBuilder<MovieCubit, MovieState>(
      builder: (context, state) {
        final request = state.request;
        return _MovieBody(
          state: state,
          retry: () {
            if (widget.requestId != null) {
              context.read<MovieCubit>().loadRequest(widget.requestId!);
            } else if (widget.createCommand != null) {
              context.read<MovieCubit>().createRequest(widget.createCommand!);
            }
          },
          child: request == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Estado: ${request.status.label}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${request.ticketCount} entradas · ${request.currency} ${request.amount.toStringAsFixed(0)}',
                    ),
                    if (request.expiresAt != null)
                      Text('Vence: ${_date(request.expiresAt)}'),
                    if (widget.canDecide &&
                        request.status == MovieRequestStatus.pending) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _reason,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Motivo de rechazo (opcional)',
                        ),
                      ),
                      FilledButton(
                        onPressed: () => context
                            .read<MovieCubit>()
                            .approveRequest(request.id),
                        child: const Text('Aprobar con Wallet'),
                      ),
                      OutlinedButton(
                        onPressed: () => context
                            .read<MovieCubit>()
                            .rejectRequest(request.id, _reason.text),
                        child: const Text('Rechazar'),
                      ),
                    ],
                    if (request.status == MovieRequestStatus.pending ||
                        request.status == MovieRequestStatus.approved)
                      TextButton(
                        onPressed: () => context
                            .read<MovieCubit>()
                            .cancelRequest(request.id),
                        child: const Text('Cancelar solicitud'),
                      ),
                    if (request.status == MovieRequestStatus.approved &&
                        widget.onApproved != null)
                      FilledButton.icon(
                        icon: const Icon(Icons.event_seat_outlined),
                        onPressed: () => widget.onApproved!(request),
                        label: const Text('Continuar y elegir asientos'),
                      ),
                    if (request.status == MovieRequestStatus.reserved &&
                        request.reservationId != null &&
                        widget.onPayReservation != null)
                      FilledButton.icon(
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                        onPressed: () =>
                            widget.onPayReservation!(request.reservationId!),
                        label: const Text('Pagar reserva con Wallet'),
                      ),
                  ],
                ),
        );
      },
    ),
  );
}

class MovieReservationPage extends StatefulWidget {
  const MovieReservationPage({
    super.key,
    required this.createCommand,
    this.selectedSeatCodes = const [],
    this.allowWalletPayment = false,
    this.onConfirmed,
  });
  final CreateMovieReservationCommand createCommand;
  final List<String> selectedSeatCodes;
  final bool allowWalletPayment;
  final ValueChanged<String>? onConfirmed;

  @override
  State<MovieReservationPage> createState() => _MovieReservationPageState();
}

class _MovieReservationPageState extends State<MovieReservationPage> {
  late final String _paymentKey =
      'movie-wallet-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    final cubit = context.read<MovieCubit>();
    cubit.setSelectedSeatCodes(widget.selectedSeatCodes);
    cubit.createReservation(widget.createCommand);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reserva')),
    body: BlocBuilder<MovieCubit, MovieState>(
      builder: (context, state) {
        final reservation = state.reservation;
        return _MovieBody(
          state: state,
          retry: () => context.read<MovieCubit>().createReservation(
            widget.createCommand,
          ),
          child: reservation == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      reservation.movieTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text('${reservation.cinemaName} · ${reservation.hallName}'),
                    Text('Estado: ${reservation.status.label}'),
                    Text(
                      '${reservation.currency} ${reservation.totalAmount.toStringAsFixed(0)}',
                    ),
                    if (reservation.seats.isNotEmpty)
                      Text(
                        'Asientos: ${reservation.seats.map((e) => e.code).join(', ')}',
                      ),
                    if (reservation.expiresAt != null &&
                        (reservation.status == MovieReservationStatus.draft ||
                            reservation.status ==
                                MovieReservationStatus.seatsHeld ||
                            reservation.status ==
                                MovieReservationStatus.pendingPayment))
                      Text(
                        'Retención vigente hasta: '
                        '${_date(reservation.expiresAt)}',
                      ),
                    if (reservation.status == MovieReservationStatus.draft)
                      FilledButton(
                        onPressed: context.read<MovieCubit>().holdSelectedSeats,
                        child: const Text('Reservar asientos seleccionados'),
                      ),
                    if (widget.allowWalletPayment &&
                        (reservation.status ==
                                MovieReservationStatus.seatsHeld ||
                            reservation.status ==
                                MovieReservationStatus.pendingPayment))
                      FilledButton.icon(
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                        onPressed: () =>
                            context.read<MovieCubit>().payReservation(
                              PayMovieReservationCommand(
                                idempotencyKey: _paymentKey,
                              ),
                            ),
                        label: const Text('Pagar con Wallet'),
                      ),
                    if (reservation.status ==
                            MovieReservationStatus.confirmed &&
                        widget.onConfirmed != null)
                      FilledButton.icon(
                        icon: const Icon(Icons.qr_code_2),
                        onPressed: () => widget.onConfirmed!(reservation.id),
                        label: const Text('Emitir QR de entrada'),
                      ),
                  ],
                ),
        );
      },
    ),
  );
}

class MovieRequestPaymentPage extends StatefulWidget {
  const MovieRequestPaymentPage({
    super.key,
    required this.reservationId,
    this.onConfirmed,
  });

  final String reservationId;
  final ValueChanged<String>? onConfirmed;

  @override
  State<MovieRequestPaymentPage> createState() =>
      _MovieRequestPaymentPageState();
}

class _MovieRequestPaymentPageState extends State<MovieRequestPaymentPage> {
  late final String _idempotencyKey =
      'movie-wallet-${DateTime.now().microsecondsSinceEpoch}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pagar entradas')),
    body: BlocBuilder<MovieCubit, MovieState>(
      builder: (context, state) {
        final reservation = state.reservation;
        return _MovieBody(
          state: state,
          retry: () => _pay(context),
          child: reservation == null
              ? Center(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    onPressed: () => _pay(context),
                    label: const Text('Pagar con Wallet'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      reservation.movieTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${reservation.currency} '
                      '${reservation.totalAmount.toStringAsFixed(0)}',
                    ),
                    Text('Estado: ${reservation.status.label}'),
                    if (reservation.status ==
                            MovieReservationStatus.confirmed &&
                        widget.onConfirmed != null)
                      FilledButton.icon(
                        icon: const Icon(Icons.qr_code_2),
                        onPressed: () => widget.onConfirmed!(reservation.id),
                        label: const Text('Emitir QR de entrada'),
                      ),
                  ],
                ),
        );
      },
    ),
  );

  void _pay(BuildContext context) {
    context.read<MovieCubit>().payReservationById(
      widget.reservationId,
      PayMovieReservationCommand(idempotencyKey: _idempotencyKey),
    );
  }
}

class MovieWalletQrPage extends StatefulWidget {
  const MovieWalletQrPage({super.key, required this.reservationId});
  final String reservationId;

  @override
  State<MovieWalletQrPage> createState() => _MovieWalletQrPageState();
}

class _MovieWalletQrPageState extends State<MovieWalletQrPage> {
  @override
  void dispose() {
    context.read<MovieCubit>().dismissQr();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Entrada QR')),
    body: BlocBuilder<MovieCubit, MovieState>(
      builder: (context, state) => _MovieBody(
        state: state,
        retry: () => context.read<MovieCubit>().issueQr(widget.reservationId),
        child: state.qr == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 52),
                      const SizedBox(height: 12),
                      const Text(
                        'El QR se emite una sola vez y no puede recuperarse. '
                        'Emítelo únicamente cuando puedas mostrarlo de inmediato.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.qr_code_2),
                        onPressed: () => context.read<MovieCubit>().issueQr(
                          widget.reservationId,
                        ),
                        label: const Text('Emitir y mostrar ahora'),
                      ),
                    ],
                  ),
                ),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.memory(
                        _qrBytes(state.qr!),
                        width: 260,
                        semanticLabel: 'Código QR de entrada',
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.qr_code_2, size: 220),
                      ),
                      const SizedBox(height: 12),
                      Text('Vence: ${_date(state.qr!.expiresAt)}'),
                      const Text(
                        'Este QR se muestra una sola vez y no se guarda.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    ),
  );
}

class MovieHistoryPageWidget extends StatefulWidget {
  const MovieHistoryPageWidget({super.key});

  @override
  State<MovieHistoryPageWidget> createState() => _MovieHistoryPageWidgetState();
}

class _MovieHistoryPageWidgetState extends State<MovieHistoryPageWidget> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_loadMore);
    context.read<MovieCubit>().loadHistory();
  }

  void _loadMore() {
    if (_scroll.position.extentAfter < 320) {
      context.read<MovieCubit>().loadMoreHistory();
    }
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_loadMore)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Historial de cine')),
    body: BlocBuilder<MovieCubit, MovieState>(
      builder: (context, state) => _MovieBody(
        state: state,
        retry: context.read<MovieCubit>().loadHistory,
        child: ListView.builder(
          controller: _scroll,
          itemCount:
              state.history.length + (state.isLoadingMoreHistory ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.history.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final item = state.history[index];
            return ListTile(
              leading: Icon(
                item.admissionConsumed
                    ? Icons.check_circle_outline
                    : Icons.confirmation_num_outlined,
              ),
              title: Text(item.reservation.movieTitle),
              subtitle: Text(
                '${_date(item.reservation.showtimeStartsAt)} · '
                '${item.reservation.status.label}',
              ),
            );
          },
        ),
      ),
    ),
  );
}

class MovieQrConsumePage extends StatefulWidget {
  const MovieQrConsumePage({super.key});

  @override
  State<MovieQrConsumePage> createState() => _MovieQrConsumePageState();
}

class _MovieQrConsumePageState extends State<MovieQrConsumePage> {
  final _scanner = MobileScannerController();
  bool _cameraReady = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _requestCamera();
  }

  Future<void> _requestCamera() async {
    final granted = await getIt<AppPermissionService>().requestCameraIfNeeded();
    if (mounted) setState(() => _cameraReady = granted);
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final token = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .where((value) => value.length >= 20)
        .firstOrNull;
    if (token == null) return;
    setState(() => _busy = true);
    await _scanner.stop();
    if (!mounted) return;
    try {
      await context.read<MovieCubit>().consumeQr(token);
    } on ArgumentError {
      if (mounted) {
        setState(() => _busy = false);
        await _scanner.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Consumir entrada')),
    body: BlocConsumer<MovieCubit, MovieState>(
      listener: (context, state) {
        if (state.consumption != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entrada consumida correctamente.')),
          );
        } else if (_busy &&
            state.status != MovieUiStatus.loading &&
            state.errorMessage != null) {
          setState(() => _busy = false);
          _scanner.start();
        }
      },
      builder: (context, state) => Column(
        children: [
          Expanded(
            child: _cameraReady
                ? MobileScanner(controller: _scanner, onDetect: _onDetect)
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Se requiere cámara para consumir la entrada Movie.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _requestCamera,
                            child: const Text('Solicitar acceso'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          if (_busy || state.status == MovieUiStatus.loading)
            const LinearProgressIndicator(),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'El token se procesa en memoria y no se guarda.',
              textAlign: TextAlign.center,
            ),
          ),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                state.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    ),
  );
}

class _MovieBody extends StatelessWidget {
  const _MovieBody({
    required this.state,
    required this.retry,
    required this.child,
  });

  final MovieState state;
  final VoidCallback retry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (state.status == MovieUiStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == MovieUiStatus.empty) {
      return const Center(child: Text('No hay resultados.'));
    }
    if (state.status
        case MovieUiStatus.error ||
            MovieUiStatus.forbidden ||
            MovieUiStatus.expired ||
            MovieUiStatus.conflict ||
            MovieUiStatus.offline) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.errorMessage ?? 'No pudimos completar la operación.'),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: retry, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    return child;
  }
}

Uint8List _qrBytes(MovieQr qr) {
  try {
    final raw = qr.imageBase64.isNotEmpty
        ? qr.imageBase64
        : qr.imageDataUrl.split(',').last;
    return base64Decode(raw);
  } on FormatException {
    return Uint8List(0);
  }
}

String _date(DateTime? value) {
  if (value == null) return 'Sin fecha';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
