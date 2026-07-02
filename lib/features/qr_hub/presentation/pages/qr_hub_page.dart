import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/permissions/app_permission_service.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../qr_wallet/presentation/pages/qr_wallet_page.dart';
import '../../../wallet/domain/entities/ciervo_wallet_identity.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../qr_scan_router.dart';
import '../widgets/my_ciervo_identity_card.dart';

class QrHubPage extends StatelessWidget {
  const QrHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Ciervo')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Elige que quieres hacer',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _HubActionCard(
            title: 'Mi QR',
            subtitle: 'Mostrar mi codigo',
            description:
                'Para eventos, reservas, accesos y cuando te deban escanear.',
            icon: Icons.qr_code_2_outlined,
            color: Theme.of(context).colorScheme.primaryContainer,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MyQrPage()),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _HubActionCard(
            title: 'Escanear QR',
            subtitle: 'Leer un codigo',
            description:
                'Para pagar en comercios, activar cupones o iniciar un flujo externo.',
            icon: Icons.qr_code_scanner,
            color: Theme.of(context).colorScheme.secondaryContainer,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ScanQrPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class MyQrPage extends StatefulWidget {
  const MyQrPage({super.key});

  @override
  State<MyQrPage> createState() => _MyQrPageState();
}

class _MyQrPageState extends State<MyQrPage> {
  late Future<CiervoWalletIdentity> _identity;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _identity = getIt<WalletRepository>().myCiervoId().then(
          (result) => result.when(
            success: (value) => value,
            failure: (error) => throw error,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi QR')),
      body: FutureBuilder<CiervoWalletIdentity>(
        future: _identity,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CiervoBrandLoader(message: 'Cargando tu QR');
          }
          if (snapshot.hasError) {
            return CiervoErrorState(
              title: 'No pudimos cargar tu QR',
              description: UserErrorMessage.from(snapshot.error!),
              onRetry: () => setState(_reload),
            );
          }

          final identity = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              MyCiervoIdentityCard(identity: identity),
              const SizedBox(height: AppSpacing.lg),
              CiervoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Mis accesos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Entradas, reservas, tarjetas regalo y beneficios con QR propio.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CiervoButton(
                      label: 'Ver entradas y reservas',
                      icon: Icons.confirmation_number_outlined,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const QrWalletPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({
    this.chatConversationId,
    super.key,
  });

  final String? chatConversationId;

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  final _controller = MobileScannerController();
  bool _cameraReady = false;
  bool _handled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ensureCamera();
  }

  Future<void> _ensureCamera() async {
    final granted =
        await getIt<AppPermissionService>().requestCameraIfNeeded();
    if (!mounted) return;
    setState(() {
      _cameraReady = granted;
      _error = granted
          ? null
          : 'Necesitamos acceso a la camara para escanear el QR.';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.trim().isEmpty) continue;
      _handled = true;
      await _controller.stop();
      if (!mounted) return;
      await QrScanRouter.handle(
        context,
        raw,
        chatConversationId: widget.chatConversationId,
      );
      if (!mounted) return;
      setState(() => _handled = false);
      await _controller.start();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR')),
      body: Column(
        children: [
          Expanded(
            child: _cameraReady
                ? MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(_error ?? 'Preparando camara…'),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Apunta al QR del comercio, cupon o persona. '
              'No uses esta opcion si te van a escanear a ti: usa Mi QR.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _HubActionCard extends StatelessWidget {
  const _HubActionCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(description),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
