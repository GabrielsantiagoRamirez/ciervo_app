import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../firebase_options.dart';
import 'notification_presenter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Si el payload trae `notification`, Android/iOS ya lo muestran en bandeja.
  // Solo presentamos local para pushes data-only (título/cuerpo en `data`).
  if (message.notification != null) return;

  await NotificationPresenter.showRemoteMessage(message);
}
