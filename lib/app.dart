import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'app/app_router.dart';
import 'core/di/service_locator.dart';
import 'core/experience/experience_mode.dart';
import 'core/experience/experience_mode_cubit.dart';
import 'core/notifications/ciervo_push_service.dart';
import 'core/notifications/notifications_sync.dart';
import 'core/notifications/notification_events_listener.dart';
import 'core/session/session_manager.dart';
import 'core/session/session_state.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/keyboard_utils.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/memberships/presentation/cubit/membership_cubit.dart';
import 'features/notifications/presentation/cubit/notification_badges_cubit.dart';
final rootNavigatorKey = GlobalKey<NavigatorState>();

class CiervoApp extends StatefulWidget {
  const CiervoApp({super.key});

  @override
  State<CiervoApp> createState() => _CiervoAppState();
}

class _CiervoAppState extends State<CiervoApp> with WidgetsBindingObserver {
  late final GoRouter _router;
  late final SessionManager _sessionManager;
  late final StreamSubscription<SessionState> _sessionSubscription;
  late final NotificationBadgesCubit _badgesCubit;
  late final ExperienceModeCubit _experienceModeCubit;
  StreamSubscription<void>? _notificationsSyncSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionManager = getIt<SessionManager>();
    _badgesCubit = getIt<NotificationBadgesCubit>();
    getIt<CiervoPushService>().bindNavigator(rootNavigatorKey);
    _experienceModeCubit = context.read<ExperienceModeCubit>();
    _router = createAppRouter(
      _sessionManager,
      _experienceModeCubit,
      navigatorKey: rootNavigatorKey,
    );
    _sessionSubscription = _sessionManager.stream.listen(_onSessionChanged);
    _notificationsSyncSubscription = getIt<NotificationsSync>().onRefresh
        .listen((_) {
          _badgesCubit.refresh();
        });
    _onSessionChanged(_sessionManager.state);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(getIt<CiervoPushService>().initialize());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionSubscription.cancel();
    _notificationsSyncSubscription?.cancel();
    stopNotificationEventsListener();
    _badgesCubit.close();
    super.dispose();
  }

  void _onSessionChanged(SessionState state) {
    if (state.status == SessionStatus.authenticated) {
      getIt<CiervoPushService>().syncTokenIfAuthenticated();
      startNotificationEventsListener();
      _badgesCubit.refresh();
      getIt<MembershipCubit>().load();
    } else {
      stopNotificationEventsListener(clearCursor: true);
      getIt<MembershipCubit>().clear();
      _badgesCubit.clear();
      _experienceModeCubit.requireSelection();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _sessionManager.state.status == SessionStatus.authenticated) {
      unawaited(getIt<CiervoPushService>().syncTokenIfAuthenticated());
      startNotificationEventsListener();
      _badgesCubit.refresh();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      stopNotificationEventsListener();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _badgesCubit,
      child: BlocBuilder<ExperienceModeCubit, ExperienceModeState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: 'CIERVO CLUB',
            debugShowCheckedModeBanner: false,
            locale: const Locale('es'),
            supportedLocales: const [
              Locale('es'),
              Locale('es', 'CL'),
              Locale('es', 'CO'),
              Locale('es', 'MX'),
              Locale('es', 'PE'),
              Locale('es', 'AR'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.day(),
            darkTheme: AppTheme.dark(),
            themeMode: state.mode == ExperienceMode.day
                ? ThemeMode.light
                : ThemeMode.dark,
            routerConfig: _router,
            builder: (context, child) {
              return DismissKeyboardScope(
                child: child ?? const SplashPage(),
              );
            },
          );
        },
      ),
    );
  }
}
