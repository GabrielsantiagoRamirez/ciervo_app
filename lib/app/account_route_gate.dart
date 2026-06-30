import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/service_locator.dart';
import '../core/experience/experience_mode_cubit.dart';
import '../core/session/auth_token_claims.dart';
import '../core/session/session_manager.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/experience/presentation/pages/experience_mode_page.dart';
import '../features/kid_shell/presentation/pages/kid_shell_page.dart';
import '../features/staff_scanner/presentation/pages/staff_mode_gate.dart';
import '../shared/widgets/ciervo_bottom_nav_scaffold.dart';
import '../shared/widgets/ciervo_brand_loader.dart';
import '../shared/widgets/ciervo_error_state.dart';

class AccountRouteGate extends StatefulWidget {
  const AccountRouteGate({super.key});

  @override
  State<AccountRouteGate> createState() => _AccountRouteGateState();
}

class _AccountRouteGateState extends State<AccountRouteGate> {
  late Future<AuthTokenClaims?> _claims;

  @override
  void initState() {
    super.initState();
    _claims = _loadClaims();
  }

  Future<AuthTokenClaims?> _loadClaims() async {
    final token = await getIt<SessionManager>().accessToken();
    if (token == null || token.isEmpty) return null;
    final claims = AuthTokenClaims.fromJwt(token);
    debugPrint('[AUTH] JWT recibido: $token');
    debugPrint('[AUTH] accountKind: ${claims.accountKind}');
    debugPrint('[AUTH] role: ${claims.role}');
    debugPrint('[AUTH] businessRoleId: ${claims.businessRoleId}');
    return claims;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AuthTokenClaims?>(
        future: _claims,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: CiervoBrandLoader(message: 'Preparando tu cuenta'),
            );
          }

          final claims = snapshot.data;
          final routeKind = claims?.routeKind ?? 'Client';
          debugPrint('[AUTH] ruta elegida: $routeKind');

          return switch (routeKind) {
            'Staff' => const StaffModeGate(),
            'Kid' => const KidShellPage(),
            'BusinessOwner' => const _AdminPlaceholder(
                title: 'Dashboard dueño',
                description:
                    'Tu cuenta fue identificada como dueño de negocio.',
              ),
            'SuperAdmin' => const _AdminPlaceholder(
                title: 'Dashboard superadmin',
                description: 'Tu cuenta fue identificada como superadmin.',
              ),
            _ => const _ClientEntry(),
          };
        },
      );
}

class _ClientEntry extends StatelessWidget {
  const _ClientEntry();

  @override
  Widget build(BuildContext context) {
    if (!context.watch<ExperienceModeCubit>().state.hasSelection) {
      return const ExperienceModePage();
    }
    return const CiervoBottomNavScaffold();
  }
}

class _AdminPlaceholder extends StatelessWidget {
  const _AdminPlaceholder({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              tooltip: 'Cerrar sesion',
              onPressed: () => getIt<AuthRepository>().logout(),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: CiervoErrorState(
            title: title,
            description: description,
          ),
        ),
      );
}
