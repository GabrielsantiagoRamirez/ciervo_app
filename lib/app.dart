import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'app/app_router.dart';
import 'core/di/service_locator.dart';
import 'core/experience/experience_mode.dart';
import 'core/experience/experience_mode_cubit.dart';
import 'core/notifications/ciervo_push_service.dart';
import 'core/permissions/app_permission_service.dart';
import 'core/session/session_manager.dart';
import 'core/session/session_state.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/presentation/cubit/notification_badges_cubit.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class CiervoApp extends StatefulWidget {
  const CiervoApp({super.key});

  @override
  State<CiervoApp> createState() => _CiervoAppState();
}

class _CiervoAppState extends State<CiervoApp> {
  late final GoRouter _router;
  late final SessionManager _sessionManager;
  late final StreamSubscription<SessionState> _sessionSubscription;
  late final NotificationBadgesCubit _badgesCubit;
  bool _requestingEntryPermissions = false;

  @override
  void initState() {
    super.initState();
    _sessionManager = getIt<SessionManager>();
    _badgesCubit = getIt<NotificationBadgesCubit>()..refresh();
    getIt<CiervoPushService>().bindNavigator(rootNavigatorKey);
    unawaited(getIt<CiervoPushService>().initialize());
    _router = createAppRouter(
      _sessionManager,
      context.read<ExperienceModeCubit>(),
      navigatorKey: rootNavigatorKey,
    );
    _sessionSubscription =
        _sessionManager.stream.listen(_onSessionChanged);
    _onSessionChanged(_sessionManager.state);
  }

  @override
  void dispose() {
    _sessionSubscription.cancel();
    _badgesCubit.close();
    super.dispose();
  }

  void _onSessionChanged(SessionState state) {
    if (state.status == SessionStatus.authenticated) {
      getIt<CiervoPushService>().syncTokenIfAuthenticated();
      _badgesCubit.refresh();
      _requestEntryPermissionsWhenAuthenticated(state);
    }
  }

  void _requestEntryPermissionsWhenAuthenticated(SessionState state) {
    if (state.status != SessionStatus.authenticated ||
        _requestingEntryPermissions) {
      return;
    }
    _requestingEntryPermissions = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await getIt<AppPermissionService>().requestRequiredEntryPermissions();
      } finally {
        _requestingEntryPermissions = false;
      }
    });
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
            theme: AppTheme.day(),
            darkTheme: AppTheme.dark(),
            themeMode: state.mode == ExperienceMode.day
                ? ThemeMode.light
                : ThemeMode.dark,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
