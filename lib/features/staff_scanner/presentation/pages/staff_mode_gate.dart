import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/experience/experience_mode_cubit.dart';
import '../../../../shared/widgets/ciervo_bottom_nav_scaffold.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../experience/presentation/pages/experience_mode_page.dart';
import '../../data/staff_scanner_repository.dart';
import '../../domain/entities/staff_scanner_models.dart';
import 'staff_scanner_home_page.dart';

class StaffModeGate extends StatefulWidget {
  const StaffModeGate({super.key});

  @override
  State<StaffModeGate> createState() => _StaffModeGateState();
}

class _StaffModeGateState extends State<StaffModeGate> {
  late Future<StaffPermissions?> _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = _load();
  }

  Future<StaffPermissions?> _load() async {
    final result = await getIt<StaffScannerRepository>().permissions();
    return result.when(
      success: (value) => value,
      failure: (_) => null,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<StaffPermissions?>(
    future: _permissions,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(
          body: CiervoBrandLoader(message: 'Validando permisos del personal'),
        );
      }

      final permissions = snapshot.data;
      if (permissions == null || !permissions.isStaff) {
        if (!context.watch<ExperienceModeCubit>().state.hasSelection) {
          return const ExperienceModePage();
        }
        return const CiervoBottomNavScaffold();
      }
      if (!permissions.canScan) {
        return const _StaffBlockedPage();
      }
      return StaffScannerHomePage(permissions: permissions);
    },
  );
}

class _StaffBlockedPage extends StatelessWidget {
  const _StaffBlockedPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Modo personal'),
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
        title: 'Sin permisos moviles',
        description:
            'Tu cuenta de personal no tiene permisos moviles asignados. Pide al dueno del negocio habilitar el lector QR.',
      ),
    ),
  );
}
