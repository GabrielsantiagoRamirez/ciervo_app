import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
    return AuthTokenClaims.fromJwt(token);
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

      return switch (routeKind) {
        'Staff' => const StaffModeGate(),
        'Kid' => const KidShellPage(),
        'BusinessOwner' => const _OperationsHome(
          title: 'Operaciones del negocio',
        ),
        'SuperAdmin' => const _OperationsHome(
          title: 'Operaciones de administración',
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

class _OperationsHome extends StatelessWidget {
  const _OperationsHome({required this.title});

  final String title;

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
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Selecciona una operación autorizada.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => context.push('/movie/consume'),
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Consumir entrada QR Movie'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => context.push('/business/kids-payment'),
          icon: const Icon(Icons.point_of_sale_outlined),
          label: const Text('Validar y ejecutar pago Kids'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => context.push('/business/nfc'),
          icon: const Icon(Icons.nfc),
          label: const Text('Validar y cobrar con NFC'),
        ),
      ],
    ),
  );
}
