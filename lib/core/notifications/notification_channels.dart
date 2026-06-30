import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Canales Android alineados con FcmPushService del backend.
abstract final class CiervoNotificationChannels {
  static const messages = 'ciervo_messages';
  static const wallet = 'ciervo_wallet';
  static const pagos = 'ciervo_pagos';
  static const reservas = 'ciervo_reservas';
  static const delivery = 'ciervo_delivery';
  static const eventos = 'ciervo_eventos';
  static const promociones = 'ciervo_promociones';
  static const recompensas = 'ciervo_recompensas';
  static const seguridad = 'ciervo_seguridad';
  static const sistema = 'ciervo_sistema';

  static const brandColor = 0xFFD4AF37;

  static String channelForCategory(String? category) {
    final normalized = (category ?? '').toLowerCase();
    if (normalized.startsWith('secure')) return pagos;
    return switch (normalized) {
      'messages' || 'mensajes' || 'chat' => messages,
      'wallet' => wallet,
      'pagos' || 'payments' || 'payment' || 'secure' => pagos,
      'reservas' || 'reservations' || 'booking' => reservas,
      'delivery' || 'entregas' => delivery,
      'eventos' || 'events' || 'event' => eventos,
      'promociones' || 'promotions' || 'promo' => promociones,
      'recompensas' || 'rewards' || 'reward' => recompensas,
      'seguridad' || 'security' => seguridad,
      _ => sistema,
    };
  }

  static String soundForCategory(String? category) {
    final normalized = (category ?? '').toLowerCase();
    if (normalized.contains('seguridad') || normalized.contains('security')) {
      return 'security_alert';
    }
    if (normalized.contains('recompensa') || normalized.contains('reward')) {
      return 'achievement';
    }
    if (normalized.contains('wallet') ||
        normalized.contains('pago') ||
        normalized.contains('payment')) {
      return 'payment_elegant';
    }
    if (normalized.contains('message') || normalized.contains('chat')) {
      return 'message_short';
    }
    return 'message_short';
  }

  static List<AndroidNotificationChannel> androidChannels() => const [
    AndroidNotificationChannel(
      messages,
      'Mensajes',
      description: 'Nuevos mensajes y chat',
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      wallet,
      'Wallet',
      description: 'Saldo, recargas y tarjeta',
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      pagos,
      'Pagos',
      description: 'Pagos, transferencias y cobros',
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      reservas,
      'Reservas',
      description: 'Reservas y recordatorios',
      importance: Importance.defaultImportance,
    ),
    AndroidNotificationChannel(
      delivery,
      'Delivery',
      description: 'Pedidos y domiciliarios',
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      eventos,
      'Eventos',
      description: 'Entradas y eventos',
      importance: Importance.defaultImportance,
    ),
    AndroidNotificationChannel(
      promociones,
      'Promociones',
      description: 'Cupones y ofertas',
      importance: Importance.defaultImportance,
    ),
    AndroidNotificationChannel(
      recompensas,
      'Recompensas',
      description: 'Puntos e insignias',
      importance: Importance.defaultImportance,
    ),
    AndroidNotificationChannel(
      seguridad,
      'Seguridad',
      description: 'Alertas de cuenta',
      importance: Importance.max,
    ),
    AndroidNotificationChannel(
      sistema,
      'Sistema',
      description: 'Actualizaciones de CIERVO CLUB',
      importance: Importance.defaultImportance,
    ),
  ];
}
