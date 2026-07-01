import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/session/session_manager.dart';
import '../core/session/session_state.dart';
import '../core/experience/experience_mode_cubit.dart';
import '../features/kid_auth/presentation/pages/kid_register_flow_page.dart';
import '../features/kid_auth/presentation/pages/kid_login_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/experience/presentation/pages/experience_mode_page.dart';
import 'account_route_gate.dart';
import 'app_router_refresh_stream.dart';

abstract final class AppRoutePaths {
  static const root = '/';
  static const splash = '/splash';
  static const login = '/login';
  static const kidLogin = '/kid-login';
  static const kidRegister = '/kid-register';
  static const firebaseLogin = '/firebase-login';
  static const firebaseRegister = '/firebase-register';
  static const register = '/register';
  static const experienceMode = '/experience-mode';
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
    redirect: (context, state) {
      final status = sessionManager.state.status;
      final location = state.matchedLocation;
      final isAuthRoute = location == AppRoutePaths.login ||
          location == AppRoutePaths.kidLogin ||
          location == AppRoutePaths.kidRegister ||
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
        path: AppRoutePaths.kidLogin,
        builder: (context, state) => const KidLoginPage(),
      ),
      GoRoute(
        path: AppRoutePaths.kidRegister,
        builder: (context, state) => const KidRegisterFlowPage(),
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
        path: AppRoutePaths.root,
        builder: (context, state) => const AccountRouteGate(),
      ),
    ],
  );
}
