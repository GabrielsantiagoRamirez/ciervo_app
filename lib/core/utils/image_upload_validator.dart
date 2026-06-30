import 'dart:io';

class ImageUploadValidator {
  static const maxBytes = 5 * 1024 * 1024;
  static const allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp'};

  static String? validate({required String path, String? fileName}) {
    final file = File(path);
    if (!file.existsSync()) {
      return 'No se pudo leer la imagen seleccionada.';
    }
    final size = file.lengthSync();
    if (size > maxBytes) {
      return 'La imagen supera el tamaño permitido.';
    }
    final name = (fileName ?? path).toLowerCase();
    final ext = name.contains('.') ? '.${name.split('.').last}' : '';
    if (!allowedExtensions.contains(ext)) {
      return 'Formato de imagen no permitido.';
    }
    return null;
  }
}
