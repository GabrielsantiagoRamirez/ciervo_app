abstract final class InputValidators {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phoneRegex = RegExp(r'^\+?[0-9\s]{7,18}$');

  static String? email(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Ingresa tu correo.';
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Ingresa un correo valido.';
    }
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) {
      return 'Ingresa tu contraseña.';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    return null;
  }

  static String? passwordConfirmation(String password, String confirmation) {
    if (confirmation.isEmpty) {
      return 'Confirma tu contraseña.';
    }
    if (password != confirmation) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  static String? requiredText(String value, String label) {
    if (value.trim().isEmpty) {
      return 'Ingresa $label.';
    }
    return null;
  }

  static String? phone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Ingresa tu telefono.';
    }
    if (!_phoneRegex.hasMatch(trimmed)) {
      return 'Ingresa un telefono valido.';
    }
    return null;
  }
}
