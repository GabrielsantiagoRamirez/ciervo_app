import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Ejecuta `flutterfire configure` con el proyecto ciervoclub-70a3c
/// y reemplaza este archivo con la salida generada.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('FCM web no configurado.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Plataforma no soportada para FCM.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE',
    appId: 'REPLACE_WITH_FLUTTERFIRE',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE',
    projectId: 'ciervoclub-70a3c',
    storageBucket: 'ciervoclub-70a3c.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE',
    appId: 'REPLACE_WITH_FLUTTERFIRE',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE',
    projectId: 'ciervoclub-70a3c',
    storageBucket: 'ciervoclub-70a3c.appspot.com',
    iosBundleId: 'com.example.ciervoClud',
  );
}
