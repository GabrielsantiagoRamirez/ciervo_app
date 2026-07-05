import 'dart:io';
import 'dart:ui' as ui;

import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

abstract final class CiervoQrShare {
  static Future<void> shareIdentity({
    required String ciervoUserCode,
    required String qrPayload,
    String? message,
  }) async {
    final text = (message ??
            'Mi CIERVO ID: $ciervoUserCode\n$qrPayload')
        .trim();
    final imagePath = await _renderQrPng(qrPayload);
    if (imagePath != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imagePath)],
          text: text,
          subject: 'CIERVO CLUB',
        ),
      );
      return;
    }
    await SharePlus.instance.share(
      ShareParams(text: text, subject: 'CIERVO CLUB'),
    );
  }

  static Future<String?> _renderQrPng(String payload) async {
    try {
      final validation = QrValidator.validate(
        data: payload,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );
      if (validation.status != QrValidationStatus.valid) return null;

      final painter = QrPainter(
        data: payload,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );
      final data = await painter.toImageData(512, format: ui.ImageByteFormat.png);
      if (data == null) return null;

      final file = File(
        '${Directory.systemTemp.path}/ciervo_qr_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(data.buffer.asUint8List());
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
