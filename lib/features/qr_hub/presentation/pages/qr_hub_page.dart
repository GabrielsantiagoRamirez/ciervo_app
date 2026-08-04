import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/layout/ciervo_page_layout.dart';
import '../../../../core/permissions/permission_kind.dart';
import '../../../../core/permissions/permission_manager.dart';
import '../../../../core/permissions/widgets/open_settings_button.dart';
import '../../../../core/permissions/widgets/permission_denied_state.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_logo_mark.dart';
import '../../../wallet/domain/entities/ciervo_wallet_identity.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../qr_scan_router.dart';
import '../widgets/my_ciervo_identity_card.dart';

class QrHubPage extends StatelessWidget {
  const QrHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Ciervo'),
      ),
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
            useCiervoLogo: true,
            color: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const MyQrPage())),
          ),
          const SizedBox(height: AppSpacing.md),
          _HubActionCard(
            title: 'Escanear QR',
            subtitle: 'Leer un codigo',
            description:
                'Para pagar en comercios, activar cupones o iniciar un flujo externo.',
            icon: Icons.qr_code_scanner,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const ScanQrPage())),
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
      appBar: AppBar(
        title: const Text('Mi QR'),
      ),
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
                      onPressed: () => context.push('/tickets/wallet'),
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
  const ScanQrPage({this.chatConversationId, super.key});

  final String? chatConversationId;

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  final _controller = MobileScannerController();
  final _picker = ImagePicker();
  _ScanSource _source = _ScanSource.choosing;
  bool _cameraReady = false;
  bool _handled = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _photosDenied = false;

  Future<void> _startCamera() async {
    setState(() {
      _source = _ScanSource.camera;
      _error = null;
      _photosDenied = false;
    });
    final granted = await PermissionManager.instance.ensure(
      context,
      AppPermissionKind.camera,
    );
    if (!mounted) return;
    setState(() {
      _cameraReady = granted;
      _error = granted
          ? null
          : 'Necesitamos acceso a la cámara para escanear el QR.';
    });
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _busy = true;
      _error = null;
      _photosDenied = false;
    });
    final granted = await PermissionManager.instance.ensure(
      context,
      AppPermissionKind.photos,
    );
    if (!granted) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _photosDenied = true;
        _error = 'Necesitamos acceso a tu galería para leer el QR.';
      });
      return;
    }

    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (image == null) {
      setState(() => _busy = false);
      return;
    }

    try {
      final capture = await _controller.analyzeImage(image.path);
      String? raw;
      if (capture != null) {
        for (final barcode in capture.barcodes) {
          final value = barcode.rawValue?.trim();
          if (value != null && value.isNotEmpty) {
            raw = value;
            break;
          }
        }
      }
      if (raw == null) {
        setState(() {
          _busy = false;
          _error = 'No encontramos un código QR válido en esta imagen.';
        });
        return;
      }
      setState(() => _busy = false);
      await QrScanRouter.handle(
        context,
        raw,
        chatConversationId: widget.chatConversationId,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'No pudimos leer el QR de la imagen seleccionada.';
      });
    }
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
      appBar: AppBar(
        title: const Text('Escanear QR'),
        actions: [
          if (_source == _ScanSource.camera)
            IconButton(
              tooltip: 'Cambiar metodo',
              onPressed: () => setState(() {
                _source = _ScanSource.choosing;
                _error = null;
              }),
              icon: const Icon(Icons.swap_horiz),
            ),
        ],
      ),
      body: switch (_source) {
        _ScanSource.choosing => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Elige como quieres leer el codigo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _ScanOptionCard(
              title: 'Usar camara',
              subtitle: 'Apunta al QR en tiempo real',
              icon: Icons.photo_camera_outlined,
              color: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor:
                  Theme.of(context).colorScheme.onPrimaryContainer,
              onTap: _startCamera,
            ),
            const SizedBox(height: CiervoPageLayout.cardGap),
            _ScanOptionCard(
              title: 'Elegir de galeria',
              subtitle: 'Selecciona una foto que ya tengas',
              icon: Icons.photo_library_outlined,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              onTap: _busy ? null : _pickFromGallery,
            ),
            if (_photosDenied) ...[
              const SizedBox(height: AppSpacing.md),
              PermissionDeniedState(
                kind: AppPermissionKind.photos,
                onRetry: _pickFromGallery,
              ),
            ] else if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: AppSpacing.sm),
              const OpenSettingsButton(),
            ],
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No uses esta opcion si te van a escanear a ti: usa Mi QR.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        _ScanSource.camera => Column(
          children: [
            Expanded(
              child: _cameraReady
                  ? MobileScanner(controller: _controller, onDetect: _onDetect)
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
                'Apunta al QR del comercio, cupon o persona.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        _ScanSource.gallery => const SizedBox.shrink(),
      },
    );
  }
}

enum _ScanSource { choosing, camera, gallery }

class _ScanOptionCard extends StatelessWidget {
  const _ScanOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.foregroundColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color foregroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: CiervoPageLayout.compactCardPadding,
          child: Row(
            children: [
              Icon(icon, size: 36, color: foregroundColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: foregroundColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: foregroundColor.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: foregroundColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubActionCard extends StatelessWidget {
  const _HubActionCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.foregroundColor,
    required this.onTap,
    this.useCiervoLogo = false,
    this.icon,
  });

  final String title;
  final String subtitle;
  final String description;
  final bool useCiervoLogo;
  final IconData? icon;
  final Color color;
  final Color foregroundColor;
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
              if (useCiervoLogo)
                const CiervoLogoMark(size: 48)
              else
                Icon(icon ?? Icons.qr_code_2, size: 40, color: foregroundColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: foregroundColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: foregroundColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: foregroundColor.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: foregroundColor),
            ],
          ),
        ),
      ),
    );
  }
}
