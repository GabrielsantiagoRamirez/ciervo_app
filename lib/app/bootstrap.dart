import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/crash/crash_reporting_service.dart';
import '../core/di/service_locator.dart';
import '../features/memberships/presentation/cubit/membership_cubit.dart';
import '../core/experience/experience_mode_cubit.dart';
import '../core/session/session_manager.dart';
import '../core/storage/secure_storage.dart';
import '../core/utils/app_bloc_observer.dart';
import '../core/version/app_version_service.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../firebase_options.dart';
import '../app.dart';
import '../shared/widgets/ciervo_error_state.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapRoot());
}

class _BootstrapRoot extends StatefulWidget {
  const _BootstrapRoot();

  @override
  State<_BootstrapRoot> createState() => _BootstrapRootState();
}

class _BootstrapRootState extends State<_BootstrapRoot> {
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    await runZonedGuarded<Future<void>>(
      () async {
        await configureDependencies();
        unawaited(getIt<AppVersionService>().load());
        await _initializeFirebase();
        Bloc.observer = AppBlocObserver();

        try {
          await getIt<SessionManager>()
              .restore()
              .timeout(const Duration(seconds: 8));
        } on TimeoutException {
          debugPrint('[bootstrap] session restore timeout');
          getIt<SessionManager>().markUnauthenticated();
        } catch (error, stackTrace) {
          debugPrint('[bootstrap] session restore failed: $error');
          getIt<SessionManager>().markUnauthenticated();
          if (getIt.isRegistered<CrashReportingService>()) {
            getIt<CrashReportingService>().recordError(
              error,
              stackTrace,
              fatal: false,
            );
          }
        }
      },
      (error, stackTrace) {
        if (getIt.isRegistered<CrashReportingService>()) {
          getIt<CrashReportingService>().recordError(
            error,
            stackTrace,
            fatal: true,
          );
        }
      },
    );
  }

  Future<void> _initializeFirebase() async {
    if (!_hasValidFirebaseOptions()) {
      debugPrint(
        '[bootstrap] Firebase omitido: configura firebase_options.dart.',
      );
      return;
    }
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      debugPrint('[bootstrap] Firebase init timeout');
    } catch (error) {
      debugPrint('[bootstrap] Firebase init: $error');
    }
  }

  bool _hasValidFirebaseOptions() {
    const placeholder = 'REPLACE_WITH_FLUTTERFIRE';
    final options = DefaultFirebaseOptions.currentPlatform;
    return options.apiKey != placeholder &&
        options.appId != placeholder &&
        options.messagingSenderId != placeholder;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashPage(),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: CiervoErrorState(
                    title: 'No pudimos iniciar la app',
                    description:
                        'Revisa tu conexion e intenta abrir Ciervo Club de nuevo.',
                    onRetry: () {
                      setState(() {
                        _initialization = _initialize();
                      });
                    },
                  ),
                ),
              ),
            ),
          );
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => ExperienceModeCubit(getIt<SecureStorage>())..restore(),
            ),
            BlocProvider.value(
              value: getIt<MembershipCubit>(),
            ),
          ],
          child: const CiervoApp(),
        );
      },
    );
  }
}