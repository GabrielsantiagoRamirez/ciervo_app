import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../core/di/service_locator.dart';
import '../core/device/device_installation_service.dart';
import '../core/session/auth_token_claims.dart';
import '../core/session/session_manager.dart';
import '../core/session/session_state.dart';
import '../core/storage/secure_storage.dart';
import '../core/utils/idempotency_key.dart';
import '../core/experience/experience_mode_cubit.dart';
import '../features/kid_auth/presentation/pages/kid_login_page.dart';
import '../features/kid_me/data/kid_me_repository.dart';
import '../features/kids_v2/data/repositories/kids_v2_repositories.dart'
    as kids_v2;
import '../features/kids_v2/data/realtime/kids_realtime_controller.dart';
import '../features/kids_v2/presentation/pages/kids_qr_page.dart';
import '../features/master_kids/data/repositories/master_kids_repository.dart';
import '../features/master_kids/domain/models/master_kids_models.dart';
import '../features/master_kids/presentation/pages/master_kid_devices_page.dart';
import '../features/master_kids/presentation/pages/master_kids_security_page.dart';
import '../features/master_kids/presentation/pages/master_payment_requests_page.dart';
import '../features/master_kids/presentation/pages/business_kids_payment_page.dart';
import '../features/master_kids/presentation/pages/master_kid_rules_page.dart';
import '../features/master_kids/presentation/pages/create_master_kid_page.dart';
import '../features/business_nfc/data/business_nfc_repository.dart';
import '../features/business_nfc/presentation/business_nfc_charge_page.dart';
import '../features/movie/domain/models/movie_commands.dart';
import '../features/movie/presentation/cubit/movie_cubit.dart';
import '../features/movie/presentation/cubit/movie_realtime_cubit.dart';
import '../features/movie/presentation/pages/movie_pages.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/password_recovery_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/experience/presentation/pages/experience_mode_page.dart';
import 'account_route_gate.dart';
import 'app_router_refresh_stream.dart';
import 'realtime_lifecycle_scope.dart';
import 'route_access_policy.dart';

abstract final class AppRoutePaths {
  static const root = '/';
  static const splash = '/splash';
  static const login = '/login';
  static const kidLogin = '/kid-login';
  static const kidRegister = '/kid-register';
  static const passwordRecovery = '/password-recovery';
  static const firebaseLogin = '/firebase-login';
  static const firebaseRegister = '/firebase-register';
  static const register = '/register';
  static const experienceMode = '/experience-mode';
  static const movies = '/movies';
  static const movieHistory = '/movie/history';
  static const movieConsume = '/movie/consume';
  static const kidsQr = '/kids-v2/qr';
}

GoRouter createAppRouter(
  SessionManager sessionManager,
  ExperienceModeCubit experienceModeCubit, {
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutePaths.splash,
    refreshListenable: AppRouterRefreshStream(
      sessionManager.stream,
      extraListenable: experienceModeCubit.stream,
    ),
    redirect: (context, state) async {
      final status = sessionManager.state.status;
      final location = state.matchedLocation;
      final isAuthRoute =
          location == AppRoutePaths.login ||
          location == AppRoutePaths.kidLogin ||
          location == AppRoutePaths.kidRegister ||
          location == AppRoutePaths.passwordRecovery ||
          location == AppRoutePaths.firebaseLogin ||
          location == AppRoutePaths.firebaseRegister ||
          location == AppRoutePaths.register;
      final isSplash = location == AppRoutePaths.splash;

      if (status == SessionStatus.unknown) {
        return isSplash ? null : AppRoutePaths.splash;
      }

      if (status == SessionStatus.unauthenticated) {
        return isAuthRoute ? null : AppRoutePaths.login;
      }

      if (isAuthRoute || isSplash) {
        return AppRoutePaths.root;
      }

      final token = await sessionManager.accessToken();
      final role = RouteAccessPolicy.roleFromRouteKind(
        token == null ? 'Client' : AuthTokenClaims.fromJwt(token).routeKind,
      );
      if (!RouteAccessPolicy.canAccess(state.uri.path, role)) {
        return AppRoutePaths.root;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutePaths.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutePaths.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutePaths.passwordRecovery,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return PasswordRecoveryPage(initialEmail: email);
        },
      ),
      GoRoute(
        path: AppRoutePaths.kidLogin,
        builder: (context, state) => const KidLoginPage(),
      ),
      GoRoute(
        path: AppRoutePaths.kidRegister,
        redirect: (_, _) => AppRoutePaths.kidLogin,
      ),
      GoRoute(
        path: AppRoutePaths.firebaseLogin,
        redirect: (_, state) => AppRoutePaths.login,
      ),
      GoRoute(
        path: AppRoutePaths.firebaseRegister,
        redirect: (_, state) => AppRoutePaths.register,
      ),
      GoRoute(
        path: AppRoutePaths.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutePaths.experienceMode,
        builder: (context, state) => const ExperienceModePage(),
      ),
      GoRoute(
        path: AppRoutePaths.movies,
        builder: (context, state) => const _MovieCatalogRoute(),
      ),
      GoRoute(
        path: '/movies/:movieId/showtimes',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<MovieCubit>(),
          child: MovieShowtimesPage(
            movieId: state.pathParameters['movieId']!,
            onShowtimeSelected: (showtime) async {
              final ticketCount = await _selectTicketCount(context);
              if (ticketCount == null || !context.mounted) return;
              await _startMovieShowtimeFlow(
                context,
                showtimeId: showtime.id,
                movieId: showtime.movieId,
                cinemaId: showtime.cinemaId,
                ticketCount: ticketCount,
              );
            },
          ),
        ),
      ),
      GoRoute(
        path: '/movies/showtimes/:showtimeId/seats',
        builder: (context, state) {
          final showtimeId = state.pathParameters['showtimeId']!;
          final movieId = state.uri.queryParameters['movieId'];
          final cinemaId = state.uri.queryParameters['cinemaId'];
          final requestId = state.uri.queryParameters['requestId'];
          final ticketCount =
              int.tryParse(state.uri.queryParameters['tickets'] ?? '') ?? 1;
          return BlocProvider(
            create: (_) => getIt<MovieCubit>(),
            child: MovieSeatsPage(
              showtimeId: showtimeId,
              ticketCount: ticketCount.clamp(1, 20),
              onSelectionReady: (codes) => _continueMovieFlow(
                context,
                showtimeId: showtimeId,
                movieId: movieId,
                cinemaId: cinemaId,
                requestId: requestId,
                ticketCount: ticketCount.clamp(1, 20),
                seatCodes: codes,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/movie-requests/new',
        builder: (context, state) => _MovieRequestRoute(
          createCommand: state.extra is CreateMovieRequestCommand
              ? state.extra! as CreateMovieRequestCommand
              : null,
        ),
      ),
      GoRoute(
        path: '/movie-requests/:requestId',
        builder: (context, state) =>
            _MovieRequestRoute(requestId: state.pathParameters['requestId']),
      ),
      GoRoute(
        path: '/movie/reservation',
        builder: (context, state) {
          final args = state.extra;
          if (args is! _MovieReservationArgs) {
            return const _InvalidMovieRoute(
              message: 'No hay una reserva Movie activa para continuar.',
            );
          }
          return BlocProvider(
            create: (_) => getIt<MovieCubit>(),
            child: MovieReservationPage(
              createCommand: args.command,
              selectedSeatCodes: args.seatCodes,
              allowWalletPayment: args.allowWalletPayment,
              onConfirmed: (reservationId) =>
                  context.push('/movie/qr/$reservationId'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/movie/qr/:reservationId',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<MovieCubit>(),
          child: MovieWalletQrPage(
            reservationId: state.pathParameters['reservationId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/movie/reservations/:reservationId/payment',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<MovieCubit>(),
          child: MovieRequestPaymentPage(
            reservationId: state.pathParameters['reservationId']!,
            onConfirmed: (reservationId) =>
                context.push('/movie/qr/$reservationId'),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutePaths.movieHistory,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<MovieCubit>(),
          child: const MovieHistoryPageWidget(),
        ),
      ),
      GoRoute(
        path: AppRoutePaths.movieConsume,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<MovieCubit>(),
          child: const MovieQrConsumePage(),
        ),
      ),
      GoRoute(
        path: AppRoutePaths.kidsQr,
        builder: (context, state) => const _KidsQrRoute(),
      ),
      GoRoute(
        path: '/master/kids/:kidId/devices',
        builder: (context, state) {
          final kidId = int.tryParse(state.pathParameters['kidId'] ?? '');
          if (kidId == null || kidId <= 0) {
            return const _InvalidMovieRoute(
              message: 'Identificador Kids inválido.',
            );
          }
          return MasterKidDevicesPage(
            repository: getIt<MasterKidsRepository>(),
            kidId: kidId,
          );
        },
      ),
      GoRoute(
        path: '/master/payment-requests',
        builder: (context, state) => MasterPaymentRequestsPage(
          masterRepository: getIt<MasterKidsRepository>(),
          kidsRepository: getIt<kids_v2.KidsRepository>(),
        ),
      ),
      GoRoute(
        path: '/master/kids/create',
        builder: (context, state) =>
            CreateMasterKidPage(repository: getIt<MasterKidsRepository>()),
      ),
      GoRoute(
        path: '/business/kids-payment',
        builder: (context, state) =>
            BusinessKidsPaymentPage(repository: getIt<MasterKidsRepository>()),
      ),
      GoRoute(
        path: '/business/nfc',
        builder: (context, state) =>
            BusinessNfcChargePage(repository: getIt<BusinessNfcRepository>()),
      ),
      GoRoute(
        path: '/master/kids/:kidId/security',
        builder: (context, state) {
          final kidId = int.tryParse(state.pathParameters['kidId'] ?? '');
          if (kidId == null || kidId <= 0) {
            return const _InvalidMovieRoute(
              message: 'Identificador Kids inválido.',
            );
          }
          return MasterKidsSecurityPage(
            repository: getIt<MasterKidsRepository>(),
            kidId: kidId,
            onExport: _shareAuditExport,
          );
        },
      ),
      GoRoute(
        path: '/master/kids/:kidId/rules',
        builder: (context, state) {
          final kidId = int.tryParse(state.pathParameters['kidId'] ?? '');
          if (kidId == null || kidId <= 0) {
            return const _InvalidMovieRoute(
              message: 'Identificador Kids inválido.',
            );
          }
          return MasterKidRulesPage(
            repository: getIt<MasterKidsRepository>(),
            kidId: kidId,
          );
        },
      ),
      GoRoute(
        path: AppRoutePaths.root,
        builder: (context, state) => const AccountRouteGate(),
      ),
    ],
  );
}

Future<void> _shareAuditExport(AuditExport export) {
  final bytes = Uint8List.fromList(export.bytes);
  return SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          bytes,
          mimeType: export.contentType,
          name: export.fileName,
        ),
      ],
      fileNameOverrides: [export.fileName],
      subject: 'Auditoría Kids CIERVO',
    ),
  );
}

Future<int?> _selectTicketCount(BuildContext context) {
  return showDialog<int>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('Cantidad de entradas'),
      children: [
        for (var count = 1; count <= 6; count++)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, count),
            child: Text('$count ${count == 1 ? 'entrada' : 'entradas'}'),
          ),
      ],
    ),
  );
}

Future<void> _continueMovieFlow(
  BuildContext context, {
  required String showtimeId,
  required String? movieId,
  required String? cinemaId,
  String? requestId,
  required int ticketCount,
  required List<String> seatCodes,
}) async {
  final token = await getIt<SessionManager>().accessToken();
  if (!context.mounted || token == null) return;
  final isKid = AuthTokenClaims.fromJwt(token).routeKind == 'Kid';
  if (isKid && requestId == null) {
    int? conversationId;
    final familyChat = await getIt<KidMeRepository>().familyChat();
    familyChat.when(
      success: (conversation) => conversationId = int.tryParse(conversation.id),
      failure: (_) {},
    );
    if (!context.mounted) return;
    if (conversationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No encontramos el chat familiar para solicitar la película.',
          ),
        ),
      );
      return;
    }
    context.push(
      '/movie-requests/new',
      extra: CreateMovieRequestCommand(
        conversationId: conversationId!,
        movieId: movieId,
        cinemaId: cinemaId,
        showtimeId: showtimeId,
        ticketCount: ticketCount,
        idempotencyKey: IdempotencyKey.generate('movie-request'),
      ),
    );
    return;
  }

  context.push(
    '/movie/reservation',
    extra: _MovieReservationArgs(
      command: CreateMovieReservationCommand(
        showtimeId: showtimeId,
        movieId: movieId,
        cinemaId: cinemaId,
        movieRequestId: requestId,
        ticketCount: ticketCount,
        idempotencyKey: IdempotencyKey.generate('movie-reservation'),
      ),
      seatCodes: seatCodes,
      allowWalletPayment: !isKid,
    ),
  );
}

Future<void> _startMovieShowtimeFlow(
  BuildContext context, {
  required String showtimeId,
  required String movieId,
  required String cinemaId,
  required int ticketCount,
}) async {
  final token = await getIt<SessionManager>().accessToken();
  if (!context.mounted || token == null) return;
  final isKid = AuthTokenClaims.fromJwt(token).routeKind == 'Kid';
  if (!isKid) {
    context.push(
      '/movies/showtimes/$showtimeId/seats'
      '?movieId=$movieId&cinemaId=$cinemaId&tickets=$ticketCount',
    );
    return;
  }

  int? conversationId;
  final familyChat = await getIt<KidMeRepository>().familyChat();
  familyChat.when(
    success: (conversation) => conversationId = int.tryParse(conversation.id),
    failure: (_) {},
  );
  if (!context.mounted) return;
  if (conversationId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No encontramos el chat familiar para solicitar la película.',
        ),
      ),
    );
    return;
  }
  context.push(
    '/movie-requests/new',
    extra: CreateMovieRequestCommand(
      conversationId: conversationId!,
      movieId: movieId,
      cinemaId: cinemaId,
      showtimeId: showtimeId,
      ticketCount: ticketCount,
      idempotencyKey: IdempotencyKey.generate('movie-request'),
    ),
  );
}

class _MovieReservationArgs {
  const _MovieReservationArgs({
    required this.command,
    required this.seatCodes,
    required this.allowWalletPayment,
  });

  final CreateMovieReservationCommand command;
  final List<String> seatCodes;
  final bool allowWalletPayment;
}

class _MovieCatalogRoute extends StatelessWidget {
  const _MovieCatalogRoute();

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: getIt<SessionManager>().accessToken(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final token = snapshot.data;
      final claims = token == null ? null : AuthTokenClaims.fromJwt(token);
      return BlocProvider(
        create: (_) => getIt<MovieCubit>(),
        child: MovieCatalogPage(
          maximumMinimumAge: claims?.routeKind == 'Kid' ? claims?.age : null,
          onHistoryRequested: () => context.push(AppRoutePaths.movieHistory),
          onMovieSelected: (movie) =>
              context.push('/movies/${movie.id}/showtimes'),
        ),
      );
    },
  );
}

class _MovieRequestRoute extends StatelessWidget {
  const _MovieRequestRoute({this.requestId, this.createCommand});

  final String? requestId;
  final CreateMovieRequestCommand? createCommand;

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: getIt<SessionManager>().accessToken(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final token = snapshot.data;
      final canDecide =
          token != null && AuthTokenClaims.fromJwt(token).routeKind == 'Client';
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<MovieCubit>()),
          BlocProvider(create: (_) => getIt<MovieRealtimeCubit>()..start()),
        ],
        child: _MovieRequestRealtimeView(
          requestId: requestId,
          createCommand: createCommand,
          canDecide: canDecide,
        ),
      );
    },
  );
}

class _MovieRequestRealtimeView extends StatelessWidget {
  const _MovieRequestRealtimeView({
    required this.requestId,
    required this.createCommand,
    required this.canDecide,
  });

  final String? requestId;
  final CreateMovieRequestCommand? createCommand;
  final bool canDecide;

  @override
  Widget build(BuildContext context) => RealtimeLifecycleScope(
    onPause: context.read<MovieRealtimeCubit>().stop,
    onResume: () {
      final realtime = context.read<MovieRealtimeCubit>();
      return realtime.start(cursor: realtime.state.cursor);
    },
    child: BlocListener<MovieRealtimeCubit, MovieRealtimeState>(
      listenWhen: (previous, current) =>
          current.events.length > previous.events.length,
      listener: (context, state) {
        final activeId =
            requestId ?? context.read<MovieCubit>().state.request?.id;
        if (activeId == null || state.events.isEmpty) return;
        final event = state.events.last;
        if (event.aggregateId == activeId ||
            event.payloadJson?.contains(activeId) == true) {
          context.read<MovieCubit>().loadRequest(activeId);
        }
      },
      child: MovieRequestPage(
        requestId: requestId,
        createCommand: createCommand,
        canDecide: canDecide,
        onApproved: canDecide
            ? null
            : (request) => context.push(
                '/movies/showtimes/${request.showtimeId}/seats'
                '?movieId=${request.movieId}'
                '&cinemaId=${request.cinemaId}'
                '&tickets=${request.ticketCount}'
                '&requestId=${request.id}',
              ),
        onPayReservation: canDecide
            ? (reservationId) =>
                  context.push('/movie/reservations/$reservationId/payment')
            : null,
      ),
    ),
  );
}

class _InvalidMovieRoute extends StatelessWidget {
  const _InvalidMovieRoute({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Movie')),
    body: Center(child: Text(message)),
  );
}

class _KidsQrRoute extends StatelessWidget {
  const _KidsQrRoute();

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: getIt<SessionManager>().accessToken(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final token = snapshot.data;
      final claims = token == null ? null : AuthTokenClaims.fromJwt(token);
      final kidId = claims?.childProfileId;
      if (kidId == null) {
        return const _InvalidMovieRoute(
          message: 'La sesión actual no contiene una identidad Kids válida.',
        );
      }
      return KidsQrBootstrapPage(
        repository: getIt<kids_v2.KidsRepository>(),
        realtime: getIt<kids_v2.KidsRealtimeRepository>(),
        installation: getIt<DeviceInstallationService>(),
        kidId: kidId,
        cursorStore: SecureStorageKidsRealtimeCursorStore(
          getIt<SecureStorage>(),
          sessionNamespace: claims?.userId ?? 'kid-$kidId',
        ),
      );
    },
  );
}
