import 'dart:typed_data';

import 'package:ciervo_clud/core/errors/app_exception.dart';
import 'package:ciervo_clud/features/move/data/media/move_image_processor.dart';
import 'package:ciervo_clud/features/move/data/media/move_media_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  const processor = MoveImageProcessor(maxDimension: 64);

  test(
    'sanea nombre, redimensiona y recodifica como JPEG sin metadata',
    () async {
      final source = img.Image(width: 120, height: 80);
      img.fill(source, color: img.ColorRgb8(30, 60, 90));

      final result = await processor.processBytes(
        Uint8List.fromList(img.encodePng(source)),
        originalFileName: '../../Licencia Frente (demo).PNG',
      );
      final decoded = img.decodeJpg(result.bytes);

      expect(result.fileName, 'Licencia_Frente_demo.jpg');
      expect(result.mimeType, 'image/jpeg');
      expect(MoveImageProcessor.detectMimeType(result.bytes), 'image/jpeg');
      expect(decoded, isNotNull);
      expect(decoded!.width, 64);
      expect(decoded.height, 43);
      expect(result.bytes.length, lessThanOrEqualTo(5 * 1024 * 1024));
    },
  );

  test('rechaza extension aunque la firma sea imagen valida', () async {
    final source = img.Image(width: 2, height: 2);

    await expectLater(
      processor.processBytes(
        Uint8List.fromList(img.encodePng(source)),
        originalFileName: 'documento.pdf',
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'move_media_extension_not_allowed',
        ),
      ),
    );
  });

  test('rechaza contenido que no coincide con una imagen permitida', () async {
    await expectLater(
      processor.processBytes(
        Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46]),
        originalFileName: 'falso.jpg',
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'move_media_signature_not_allowed',
        ),
      ),
    );
  });

  test('MediaAsset exige id positivo entregado por backend', () {
    expect(
      () => MoveMediaAsset.fromJson(const {'id': 0}),
      throwsFormatException,
    );
    expect(MoveMediaAsset.fromJson(const {'id': 42}).id, 42);
  });
}
