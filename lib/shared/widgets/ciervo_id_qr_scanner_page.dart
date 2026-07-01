import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/di/service_locator.dart';
import '../../core/permissions/app_permission_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/ciervo_id_qr.dart';

/// Escanea un QR y devuelve el CIERVO ID detectado.
class CiervoIdQrScannerPage extends StatefulWidget {
  const CiervoIdQrScannerPage({super.key});

  @override
  State<CiervoIdQrScannerPage> createState() => _CiervoIdQrScannerPageState();
}

class _CiervoIdQrScannerPageState extends State<CiervoIdQrScannerPage> {
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
          : 'Necesitamos acceso a la cámara para escanear el QR.';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.trim().isEmpty) continue;
      final code = CiervoIdQr.parse(raw);
      if (code == null) continue;
      _handled = true;
      Navigator.of(context).pop(code);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear CIERVO ID')),
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
                      child: Text(_error ?? 'Preparando cámara…'),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Apunta al QR del destinatario. También puedes escanear un CIERVO ID impreso.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
