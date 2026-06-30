import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/permissions/app_permission_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../data/staff_scanner_repository.dart';
import '../../domain/entities/staff_scanner_models.dart';

class StaffQrScannerPage extends StatefulWidget {
  const StaffQrScannerPage({required this.permissions, super.key});

  final StaffPermissions permissions;

  @override
  State<StaffQrScannerPage> createState() => _StaffQrScannerPageState();
}

class _StaffQrScannerPageState extends State<StaffQrScannerPage> {
  final _controller = MobileScannerController();
  StaffQrValidation? _validation;
  StaffQrRedeemResult? _redeemResult;
  String? _payload;
  String? _error;
  bool _isBusy = false;
  bool _cameraReady = false;

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
      if (!granted) {
        _error = 'Necesitamos acceso a la cámara para escanear códigos QR.';
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Escanear QR'),
      actions: [
        IconButton(
          tooltip: 'Reiniciar lector',
          onPressed: _reset,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_cameraReady)
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                )
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(_error ?? 'Preparando cámara...'),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70, width: 2),
                ),
              ),
              if (_isBusy)
                const ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _ResultPanel(
              validation: _validation,
              redeemResult: _redeemResult,
              error: _error,
              isBusy: _isBusy,
              canRedeem: widget.permissions.canRedeem,
              onRedeem: _redeem,
              onReset: _reset,
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isBusy || _validation != null || _error != null) return;
    String? payload;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        payload = value;
        break;
      }
    }
    if (payload == null) return;

    setState(() {
      _isBusy = true;
      _payload = payload;
      _error = null;
      _redeemResult = null;
    });
    await _controller.stop();
    final result = await getIt<StaffScannerRepository>().validate(
      payload: payload,
    );
    if (!mounted) return;
    result.when(
      success: (value) => setState(() {
        _validation = value;
        _isBusy = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _isBusy = false;
      }),
    );
  }

  Future<void> _redeem() async {
    final payload = _payload;
    final validation = _validation;
    if (payload == null || validation == null || _isBusy) return;
    setState(() => _isBusy = true);
    final result = await getIt<StaffScannerRepository>().redeem(
      payload: payload,
      qrId: validation.qrId,
    );
    if (!mounted) return;
    result.when(
      success: (value) => setState(() {
        _redeemResult = value;
        _isBusy = false;
      }),
      failure: (error) => setState(() {
        _error = UserErrorMessage.from(error);
        _isBusy = false;
      }),
    );
  }

  Future<void> _reset() async {
    setState(() {
      _validation = null;
      _redeemResult = null;
      _payload = null;
      _error = null;
      _isBusy = false;
    });
    await _controller.start();
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.validation,
    required this.redeemResult,
    required this.error,
    required this.isBusy,
    required this.canRedeem,
    required this.onRedeem,
    required this.onReset,
  });

  final StaffQrValidation? validation;
  final StaffQrRedeemResult? redeemResult;
  final String? error;
  final bool isBusy;
  final bool canRedeem;
  final VoidCallback onRedeem;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return _StatusCard(
        color: Theme.of(context).colorScheme.error,
        icon: Icons.cancel_outlined,
        title: 'QR no valido',
        lines: [error!],
        action: OutlinedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Escanear otro'),
        ),
      );
    }

    if (redeemResult != null) {
      final result = redeemResult!;
      return _StatusCard(
        color: Colors.green,
        icon: Icons.verified_outlined,
        title: result.redeemed ? 'Uso confirmado' : 'Resultado recibido',
        lines: [
          if (result.status != null) 'Estado: ${result.status}',
          if (result.redeemedBy != null) 'Por: ${result.redeemedBy}',
          if (result.redeemedAt != null)
            'Fecha: ${result.redeemedAt!.toLocal().toString().substring(0, 16)}',
          if (result.message != null) result.message!,
        ],
        action: OutlinedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Escanear otro'),
        ),
      );
    }

    final result = validation;
    if (result == null) {
      return const _StatusCard(
        color: Colors.blueGrey,
        icon: Icons.qr_code_scanner,
        title: 'Apunta al QR del cliente',
        lines: ['La validacion se hara con tu sesion de personal.'],
      );
    }

    final color = _colorFor(result);
    return _StatusCard(
      color: color,
      icon: result.valid ? Icons.check_circle_outline : Icons.cancel_outlined,
      title: result.valid ? 'QR valido' : 'QR rechazado',
      lines: [
        if (result.title != null) result.title!,
        if (result.ownerName != null) 'Cliente: ${result.ownerName}',
        if (result.type != null) 'Tipo: ${result.type}',
        if (result.status != null) 'Estado: ${result.status}',
        if (result.message != null) result.message!,
      ],
      action: result.valid && result.canRedeem && canRedeem
          ? CiervoButton(
              label: isBusy ? 'Confirmando' : 'Confirmar uso',
              icon: Icons.verified,
              state:
                  isBusy ? CiervoButtonState.loading : CiervoButtonState.normal,
              onPressed: onRedeem,
            )
          : OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear otro'),
            ),
    );
  }

  Color _colorFor(StaffQrValidation result) {
    final status = result.status?.toLowerCase() ?? '';
    if (!result.valid) return Colors.red;
    if (status.contains('used')) return Colors.grey;
    if (status.contains('expired')) return Colors.orange;
    return Colors.green;
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.lines,
    this.action,
  });

  final Color color;
  final IconData icon;
  final String title;
  final List<String> lines;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...lines.map((line) => Text(line, textAlign: TextAlign.center)),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    ),
  );
}
