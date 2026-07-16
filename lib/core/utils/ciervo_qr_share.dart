import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../shared/widgets/ciervo_qr_view.dart';

abstract final class CiervoQrShare {
  static Future<void> shareIdentity({
    required String ciervoUserCode,
    required String qrPayload,
    String? displayName,
    String? message,
  }) async {
    final text =
        (message ??
                'Este es mi perfil de Ciervo Club.\n'
                    'CIERVO ID: $ciervoUserCode\n'
                    '$qrPayload')
            .trim();

    final png =
        await _renderProfileCardPng(
          ciervoUserCode: ciervoUserCode,
          qrPayload: qrPayload,
          displayName: displayName,
        ) ??
        await _renderQrPng(qrPayload);

    if (png != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              png,
              mimeType: 'image/png',
              name: 'mi_perfil_ciervo.png',
            ),
          ],
          fileNameOverrides: const ['mi_perfil_ciervo.png'],
          text: text,
          subject: 'Mi perfil Ciervo Club',
          title: 'Compartir mi perfil',
        ),
      );
      return;
    }

    await SharePlus.instance.share(
      ShareParams(text: text, subject: 'Mi perfil Ciervo Club'),
    );
  }

  static Future<Uint8List?> _renderQrPng(String payload) async {
    try {
      final data = await CiervoQrView.sharePainter(
        payload,
      ).toImageData(768, format: ui.ImageByteFormat.png);
      if (data == null) return null;
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (error, stack) {
      debugPrintStack(label: 'CiervoQrShare._renderQrPng', stackTrace: stack);
      return null;
    }
  }

  static Future<Uint8List?> _renderProfileCardPng({
    required String ciervoUserCode,
    required String qrPayload,
    String? displayName,
  }) async {
    try {
      final validation = QrValidator.validate(
        data: qrPayload,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );
      if (validation.status != QrValidationStatus.valid) return null;

      const width = 1080.0;
      const height = 1440.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final rect = Rect.fromLTWH(0, 0, width, height);

      final bg = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          const Offset(width, height),
          const [Color(0xFF070708), Color(0xFF151619), Color(0xFF101113)],
        );
      canvas.drawRect(rect, bg);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(36), const Radius.circular(36)),
        Paint()
          ..color = const Color(0xFFD8B45F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

      _drawCenteredText(
        canvas,
        'CIERVO CLUB',
        const Offset(width / 2, 120),
        fontSize: 42,
        color: const Color(0xFFF0D58A),
        fontWeight: FontWeight.w700,
        letterSpacing: 4,
      );
      _drawCenteredText(
        canvas,
        'Este es mi perfil',
        const Offset(width / 2, 200),
        fontSize: 48,
        color: const Color(0xFFF5F2EA),
        fontWeight: FontWeight.w600,
      );
      final name = (displayName ?? '').trim();
      if (name.isNotEmpty) {
        _drawCenteredText(
          canvas,
          name,
          const Offset(width / 2, 270),
          fontSize: 34,
          color: const Color(0xFFAAA7A0),
        );
      }

      const qrBoxSize = 560.0;
      const quietZone = 48.0;
      const qrContentSize = qrBoxSize - quietZone * 2;
      final qrLeft = (width - qrBoxSize) / 2;
      const qrTop = 360.0;

      final frame = RRect.fromRectAndRadius(
        Rect.fromLTWH(qrLeft - 36, qrTop - 36, qrBoxSize + 72, qrBoxSize + 72),
        const Radius.circular(28),
      );
      canvas.drawRRect(frame, Paint()..color = const Color(0xFF1B1C20));
      canvas.drawRRect(
        frame,
        Paint()
          ..color = const Color(0xFFD8B45F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(qrLeft, qrTop, qrBoxSize, qrBoxSize),
          const Radius.circular(18),
        ),
        Paint()..color = const Color(0xFFFFFFFF),
      );

      canvas.save();
      canvas.translate(qrLeft + quietZone, qrTop + quietZone);
      CiervoQrView.sharePainter(
        qrPayload,
      ).paint(canvas, const Size(qrContentSize, qrContentSize));
      canvas.restore();

      _drawCenteredText(
        canvas,
        ciervoUserCode,
        Offset(width / 2, qrTop + qrBoxSize + 120),
        fontSize: 40,
        color: const Color(0xFFD8B45F),
        fontWeight: FontWeight.w700,
      );
      _drawCenteredText(
        canvas,
        'Escanea este código para encontrarme en Ciervo Club',
        Offset(width / 2, qrTop + qrBoxSize + 190),
        fontSize: 28,
        color: const Color(0xFFAAA7A0),
      );

      final picture = recorder.endRecording();
      try {
        final image = await picture.toImage(width.toInt(), height.toInt());
        try {
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          if (data == null) return null;
          return data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
        } finally {
          image.dispose();
        }
      } finally {
        picture.dispose();
      }
    } catch (error, stack) {
      debugPrintStack(
        label: 'CiervoQrShare._renderProfileCardPng',
        stackTrace: stack,
      );
      return null;
    }
  }

  static void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w400,
    double letterSpacing = 0,
  }) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: TextAlign.center,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: letterSpacing,
            ),
          )
          ..addText(text);
    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: 900));
    canvas.drawParagraph(
      paragraph,
      Offset(center.dx - 450, center.dy - paragraph.height / 2),
    );
  }
}
