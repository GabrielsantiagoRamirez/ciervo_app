import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyCUOhcLeB1so8jWnZL3rC-qLAmcjmgKaAM',
    appId: '1:613568140358:android:c9ee0545900befc2916647',
    messagingSenderId: '613568140358',
    projectId: 'ciervoclub-70a3c',
    storageBucket: 'ciervoclub-70a3c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCUOhcLeB1so8jWnZL3rC-qLAmcjmgKaAM',
    appId: '1:613568140358:android:c9ee0545900befc2916647',
    messagingSenderId: '613568140358',
    projectId: 'ciervoclub-70a3c',
    storageBucket: 'ciervoclub-70a3c.firebasestorage.app',
    iosBundleId: 'com.company.ciervoclub',
  );
}
