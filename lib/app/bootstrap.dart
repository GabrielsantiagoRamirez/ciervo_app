import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/crash/crash_reporting_service.dart';
import '../core/di/service_locator.dart';
import '../core/experience/experience_mode_cubit.dart';
import '../core/session/session_manager.dart';
import '../core/storage/secure_storage.dart';
import '../core/utils/app_bloc_observer.dart';
import '../firebase_options.dart';
import '../app.dart';

Future<void> bootstrap() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await configureDependencies();
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (error) {
        debugPrint('[bootstrap] Firebase init: $error');
      }
      Bloc.observer = AppBlocObserver();

      try {
        await getIt<SessionManager>().restore();
      } catch (error, stackTrace) {
        debugPrint('[bootstrap] session restore failed: $error');
        if (getIt.isRegistered<CrashReportingService>()) {
          getIt<CrashReportingService>().recordError(
            error,
            stackTrace,
            fatal: false,
          );
        }
      }

      runApp(
        BlocProvider(
          create: (_) => ExperienceModeCubit(getIt<SecureStorage>())..restore(),
          child: const CiervoApp(),
        ),
      );
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
