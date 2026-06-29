import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'app/app_router.dart';
import 'core/experience/experience_mode.dart';
import 'core/experience/experience_mode_cubit.dart';
import 'core/di/service_locator.dart';
import 'core/permissions/app_permission_service.dart';
import 'core/session/session_manager.dart';
import 'core/session/session_state.dart';
import 'core/theme/app_theme.dart';

class CiervoApp extends StatefulWidget {
  const CiervoApp({super.key});

  @override
  State<CiervoApp> createState() => _CiervoAppState();
}

class _CiervoAppState extends State<CiervoApp> {
  late final GoRouter _router;
  late final SessionManager _sessionManager;
  late final StreamSubscription<SessionState> _sessionSubscription;
  bool _requestingEntryPermissions = false;

  @override
  void initState() {
    super.initState();
    _sessionManager = getIt<SessionManager>();
    _router = createAppRouter(
      _sessionManager,
      context.read<ExperienceModeCubit>(),
    );
    _sessionSubscription =
        _sessionManager.stream.listen(_requestEntryPermissionsWhenAuthenticated);
    _requestEntryPermissionsWhenAuthenticated(_sessionManager.state);
  }

  @override
  void dispose() {
    _sessionSubscription.cancel();
    super.dispose();
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
    return BlocBuilder<ExperienceModeCubit, ExperienceModeState>(
      builder: (context, state) {
        return MaterialApp.router(
          title: 'Ciervo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.day(),
          darkTheme: AppTheme.dark(),
          themeMode: state.mode == ExperienceMode.day
              ? ThemeMode.light
              : ThemeMode.dark,
          routerConfig: _router,
        );
      },
    );
  }
}
