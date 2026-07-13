enum AppPermissionKind {
  camera,
  photos,
  contacts,
  location,
  notifications,
  nfc,
}

extension AppPermissionKindX on AppPermissionKind {
  String get title => switch (this) {
    AppPermissionKind.camera => 'Cámara',
    AppPermissionKind.photos => 'Galería y fotos',
    AppPermissionKind.contacts => 'Contactos',
    AppPermissionKind.location => 'Ubicación',
    AppPermissionKind.notifications => 'Notificaciones',
    AppPermissionKind.nfc => 'NFC',
  };

  String get explanation => switch (this) {
    AppPermissionKind.camera =>
      'La usamos para escanear códigos QR, tomar fotos de documentos y verificar tu identidad.',
    AppPermissionKind.photos =>
      'La usamos para elegir imágenes desde tu galería, como fotos de documentos o códigos QR.',
    AppPermissionKind.contacts =>
      'La usamos para encontrar amigos en Ciervo y enviarles invitaciones.',
    AppPermissionKind.location =>
      'La usamos para mostrar negocios cercanos, delivery, mapas y seguridad de pagos.',
    AppPermissionKind.notifications =>
      'Te avisamos de pagos, transferencias, aprobaciones, mensajes y movimientos importantes.',
    AppPermissionKind.nfc =>
      'Permite pagar en comercios afiliados acercando tu celular cuando el dispositivo lo soporta.',
  };

  String get deniedMessage => switch (this) {
    AppPermissionKind.camera =>
      'Necesitamos acceso a la cámara para continuar.',
    AppPermissionKind.photos =>
      'Necesitamos acceso a tu galería para leer la imagen.',
    AppPermissionKind.contacts =>
      'Necesitamos acceso a tus contactos para buscar amigos en Ciervo.',
    AppPermissionKind.location =>
      'Necesitamos acceso a tu ubicación para esta función.',
    AppPermissionKind.notifications =>
      'Activa las notificaciones para recibir alertas de pagos y seguridad.',
    AppPermissionKind.nfc =>
      'Tu dispositivo no tiene NFC disponible o está desactivado.',
  };
}
