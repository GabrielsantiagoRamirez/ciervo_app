import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'app/app_router.dart';
import 'core/di/service_locator.dart';
import 'core/experience/experience_mode.dart';
import 'core/experience/experience_mode_cubit.dart';
import 'core/notifications/ciervo_push_service.dart';
import 'core/notifications/notifications_sync.dart';
import 'core/notifications/notification_events_listener.dart';
import 'core/permissions/app_permission_service.dart';
import 'features/onboarding/entry_permissions_prompt.dart';
import 'core/session/session_manager.dart';
import 'core/session/session_state.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/memberships/presentation/cubit/membership_cubit.dart';
import 'features/notifications/presentation/cubit/notification_badges_cubit.dart';
import 'shared/widgets/ciervo_user_id_badge.dart';

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
  StreamSubscription<void>? _notificationsSyncSubscription;
  bool _requestingEntryPermissions = false;
  bool _entryPermissionsHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionManager = getIt<SessionManager>();
    _badgesCubit = getIt<NotificationBadgesCubit>()..refresh();
    getIt<CiervoPushService>().bindNavigator(rootNavigatorKey);
    _router = createAppRouter(
      _sessionManager,
      context.read<ExperienceModeCubit>(),
      navigatorKey: rootNavigatorKey,
    );
    _sessionSubscription =
        _sessionManager.stream.listen(_onSessionChanged);
    _notificationsSyncSubscription =
        getIt<NotificationsSync>().onRefresh.listen((_) {
      _badgesCubit.refresh();
    });
    _onSessionChanged(_sessionManager.state);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureEntryPermissions();
    });
  }

  Future<void> _ensureEntryPermissions() async {
    if (_entryPermissionsHandled) return;
    _entryPermissionsHandled = true;
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      await EntryPermissionsPrompt.showIfNeeded(context);
    }
    await getIt<AppPermissionService>().requestRequiredEntryPermissions();
    await getIt<CiervoPushService>().initialize();
    await getIt<CiervoPushService>().syncTokenIfAuthenticated();
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
      _requestEntryPermissionsWhenAuthenticated(state);
    } else {
      stopNotificationEventsListener();
      getIt<MembershipCubit>().clear();
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
        await getIt<CiervoPushService>().initialize();
        await getIt<CiervoPushService>().syncTokenIfAuthenticated();
      } finally {
        _requestingEntryPermissions = false;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(getIt<CiervoPushService>().syncTokenIfAuthenticated());
      _badgesCubit.refresh();
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
            theme: AppTheme.day(),
            darkTheme: AppTheme.dark(),
            themeMode: state.mode == ExperienceMode.day
                ? ThemeMode.light
                : ThemeMode.dark,
            routerConfig: _router,
            builder: (context, child) {
              return CiervoUserIdOverlay(
                child: child ?? const SplashPage(),
              );
            },
          );
        },
      ),
    );
  }
}
