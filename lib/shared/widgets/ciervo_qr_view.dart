import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_spacing.dart';

/// QR Ciervo con contraste correcto en tema oscuro y al exportar PNG.
class CiervoQrView extends StatelessWidget {
  const CiervoQrView({
    required this.data,
    this.size = 220,
    this.padding = AppSpacing.md,
    super.key,
  });

  final String data;
  final double size;
  final double padding;

  static const QrEyeStyle eyeStyle = QrEyeStyle(
    eyeShape: QrEyeShape.square,
    color: Colors.black,
  );

  static const QrDataModuleStyle dataModuleStyle = QrDataModuleStyle(
    dataModuleShape: QrDataModuleShape.square,
    color: Colors.black,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        backgroundColor: Colors.white,
        eyeStyle: eyeStyle,
        dataModuleStyle: dataModuleStyle,
        gapless: false,
      ),
    );
  }

  /// Renderiza PNG con fondo blanco para compartir (evita cuadrado negro).
  static QrPainter sharePainter(String payload) => QrPainter(
    data: payload,
    version: QrVersions.auto,
    errorCorrectionLevel: QrErrorCorrectLevel.M,
    color: Colors.black,
    emptyColor: Colors.white,
    gapless: false,
  );
}
