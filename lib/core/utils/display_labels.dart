import 'package:flutter/material.dart';

/// Etiquetas amigables en español para valores técnicos del backend.
abstract final class DisplayLabels {
  static String kycStatus(String? status) {
    if (status == null || status.isEmpty) return 'No enviado';
    final key = status.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    return switch (key) {
      'notsubmitted' || 'sinenviar' => 'Sin enviar',
      'pending' || 'pendingapproval' || 'pendiente' => 'En revisión',
      'approved' || 'aprobado' => 'Aprobado',
      'rejected' || 'rechazado' => 'Rechazado',
      'underreview' || 'inreview' || 'enrevision' => 'En revisión',
      'submitted' || 'enviado' => 'Enviado',
      'noenviado' => 'No enviado',
      _ => _humanize(status),
    };
  }

  static String settlementFieldLabel(String field) {
    final key = field.toLowerCase().replaceAll('_', '');
    return switch (key) {
      'bankid' => 'Banco',
      'accounttype' => 'Tipo de cuenta',
      'accountnumber' => 'Número de cuenta',
      'holdername' => 'Titular',
      'documentnumber' => 'Documento del titular',
      'phonenumber' => 'Teléfono',
      'walletidentifier' => 'Identificador de billetera',
      _ => _humanize(field),
    };
  }

  static String settlementStatus(String? status) {
    if (status == null || status.isEmpty) return 'Sin registrar';
    final key = status.toLowerCase().replaceAll('_', '');
    return switch (key) {
      'notregistered' || 'sinregistrar' => 'Sin registrar',
      'pending' || 'pendingapproval' || 'pendingreview' => 'Pendiente de revisión',
      'approved' || 'verified' => 'Aprobada',
      'rejected' => 'Rechazada',
      _ => _humanize(status),
    };
  }

  static String planPeriod(String? period) {
    if (period == null || period.isEmpty) return '';
    return switch (period.toLowerCase()) {
      'monthly' => 'Mensual',
      'yearly' || 'annual' => 'Anual',
      'weekly' => 'Semanal',
      _ => _humanize(period),
    };
  }

  static String moduleStatusLabel(String? status) {
    if (status == null || status.isEmpty) return '';
    return switch (status.toLowerCase()) {
      'pilot' => 'Módulo piloto',
      'active' => 'Disponible',
      _ => '',
    };
  }

  static String sanitizeDiscountDescription(String? description) {
    if (description == null || description.isEmpty) {
      return 'Beneficio de transporte disponible.';
    }
    final lower = description.toLowerCase();
    if (lower.contains('mock')) {
      return 'Beneficio de transporte disponible.';
    }
    return description;
  }

  static String deliveryStatus(String status) {
    final key = status.toLowerCase().replaceAll('_', '');
    return switch (key) {
      'pending' || 'pendingapproval' => 'Pendiente de aprobación',
      'approved' => 'Aprobado',
      'rejected' => 'Rechazado',
      'suspended' => 'Suspendido',
      _ => _humanize(status),
    };
  }

  static String availability(bool isOnline) =>
      isOnline ? 'Disponible' : 'Desconectado';

  static String vehicleType(String? type) {
    if (type == null || type.isEmpty) return 'Sin registrar';
    return switch (type.toLowerCase()) {
      'bike' || 'bicycle' => 'Bicicleta',
      'motorcycle' || 'moto' => 'Moto',
      'car' => 'Carro',
      'walking' => 'Caminando',
      _ => _humanize(type),
    };
  }

  static String transportCardStatus(String status) {
    final key = status.toLowerCase();
    return switch (key) {
      'active' => 'Activa',
      'inactive' => 'Inactiva',
      'blocked' => 'Bloqueada',
      'expired' => 'Vencida',
      _ => _humanize(status),
    };
  }

  static String conversationType(String? type) {
    if (type == null || type.isEmpty) return 'Conversación';
    final key = type.toLowerCase().replaceAll('_', '');
    return switch (key) {
      'business' => 'Negocio',
      'family' => 'Familiar',
      'delivery' => 'Domicilio',
      'support' => 'Soporte',
      'open' => 'Abierta',
      _ => _humanize(type),
    };
  }

  static String bookingStatus(String status) {
    final key = status.toLowerCase().replaceAll('_', '');
    return switch (key) {
      'pending' || 'pendingapproval' => 'Pendiente de aprobación',
      'confirmed' || 'approved' => 'Confirmada',
      'cancelled' || 'canceled' => 'Cancelada',
      'completed' => 'Completada',
      'rejected' => 'Rechazada',
      _ => _humanize(status),
    };
  }

  static String membershipStatus(String? status) {
    if (status == null || status.isEmpty) return 'Activo';
    final key = status.toLowerCase().replaceAll('_', '');
    return switch (key) {
      'active' => 'Activo',
      'cancelled' || 'canceled' => 'Cancelado',
      'expired' => 'Vencido',
      'pending' => 'Pendiente',
      _ => _humanize(status),
    };
  }

  static String planName({required String code, String? name}) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isNotEmpty && !_looksTechnical(trimmed)) return trimmed;
    final key = code.toLowerCase().replaceAll('-', '_');
    return switch (key) {
      'free' => 'Plan Gratuito',
      'basic' || 'plan_basic' || 'plan_basic_active' => 'Plan Básico',
      'plus' || 'silver' => 'Plan Plus',
      'gold' || 'premium' => 'Plan Gold',
      'premium_monthly' => 'Plan Premium Mensual',
      'premium_yearly' => 'Plan Premium Anual',
      'family' || 'family_gold' => 'Plan Familiar Gold',
      'platinum' || 'black' => 'Plan Platinum',
      _ => _titleFromCode(code),
    };
  }

  static String planDescription(String code) {
    final key = code.toLowerCase().replaceAll('-', '_');
    return switch (key) {
      'free' => 'Acceso básico a Ciervo Club sin costo mensual.',
      'basic' || 'plan_basic' => 'Ideal para empezar con beneficios esenciales.',
      'plus' || 'silver' => 'Más cashback y acceso a promociones seleccionadas.',
      'gold' || 'premium' || 'premium_monthly' =>
        'Beneficios premium, mayor cashback y prioridad en reservas.',
      'family' || 'family_gold' =>
        'Pensado para familias con control parental y beneficios compartidos.',
      'platinum' || 'black' => 'Máximo nivel con beneficios exclusivos.',
      _ => 'Membresía Ciervo Club con ventajas según tu plan.',
    };
  }

  static String notificationPreference(String key) {
    final text = key.toLowerCase();
    if (text.contains('chat') && text.contains('message')) {
      return 'Mensajes de chat';
    }
    if (text.contains('push')) return 'Notificaciones push';
    if (text.contains('email')) return 'Correo electrónico';
    if (text.contains('sms')) return 'Mensajes de texto';
    if (text.contains('wallet')) return 'Movimientos de billetera';
    if (text.contains('payment')) return 'Pagos y cobros';
    if (text.contains('booking') || text.contains('reserv')) {
      return 'Reservas';
    }
    if (text.contains('delivery') || text.contains('order')) {
      return 'Pedidos y domicilios';
    }
    if (text.contains('promo') || text.contains('coupon')) return 'Promociones';
    if (text.contains('reward')) return 'Recompensas';
    if (text.contains('security') || text.contains('kyc')) return 'Seguridad';
    return _humanize(key);
  }

  static String notificationGroup(String group) => switch (group) {
    'Wallet' => 'Billetera',
    'Delivery' => 'Domicilios',
    _ => group,
  };

  static String documentType(String type) => switch (type.toUpperCase()) {
    'CC' => 'Cédula',
    'CE' => 'Cédula de extranjería',
    'PASSPORT' => 'Pasaporte',
    _ => type,
  };

  static String locationSummary({
    required double? latitude,
    required double? longitude,
  }) {
    if (latitude == null || longitude == null) {
      return 'Sin registrar';
    }
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  static String sanitizeBackendMessage(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return 'Revisa los datos e intenta nuevamente.';

    final fieldRequired = RegExp(
      r'(?:the\s+)?(\w+)\s+field\s+is\s+required',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (fieldRequired != null) {
      return _fieldRequiredMessage(fieldRequired.group(1)!);
    }

    if (RegExp(r'is required\.?$', caseSensitive: false).hasMatch(trimmed) &&
        RegExp(r'^[A-Z][a-zA-Z]+$').hasMatch(trimmed.split(' ').first)) {
      return _fieldRequiredMessage(trimmed.split(' ').first);
    }

    if (trimmed.toLowerCase().contains('no se pudo completar la solicitud')) {
      return 'No se pudo completar la solicitud. Verifica tu conexión e intenta de nuevo.';
    }

    if (_looksTechnical(trimmed)) {
      return 'Revisa los datos ingresados e intenta nuevamente.';
    }

    return trimmed;
  }

  static String _fieldRequiredMessage(String field) {
    final key = field.toLowerCase();
    return switch (key) {
      'subjectrole' =>
        'Falta información de tu perfil. Cierra sesión, vuelve a entrar e intenta de nuevo.',
      'publiccode' =>
        'No pudimos crear el recurso. Intenta nuevamente en unos segundos.',
      'documenttype' => 'Selecciona el tipo de documento.',
      'documentnumber' => 'Ingresa el número de documento.',
      'vehicletype' => 'Selecciona el tipo de vehículo.',
      'phonenumber' || 'phone' => 'Ingresa tu teléfono.',
      'birthdate' => 'Selecciona tu fecha de nacimiento.',
      _ => 'Completa todos los campos obligatorios.',
    };
  }

  static bool _looksTechnical(String value) {
    if (value.contains('_') && value == value.toLowerCase()) return true;
    if (RegExp(r'^[a-z]+_[a-z0-9_]+$').hasMatch(value)) return true;
    if (RegExp(r'^[A-Z][a-zA-Z]+$').hasMatch(value) &&
        value.length > 2 &&
        !value.contains(' ')) {
      return true;
    }
    return false;
  }

  static String _titleFromCode(String code) {
    final words = code
        .replaceAll('-', '_')
        .split('_')
        .where((w) => w.isNotEmpty)
        .map(
          (w) => w.length <= 3
              ? w.toUpperCase()
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        );
    return 'Plan ${words.join(' ')}';
  }

  static String secureShipmentStatus(String? statusName) {
    if (statusName == null || statusName.isEmpty) {
      return 'En preparación';
    }
    final key = statusName.replaceAll('_', '').replaceAll(' ', '');
    return switch (key.toLowerCase()) {
      'created' => 'Creado',
      'pendingacceptance' => 'Esperando aceptación',
      'rejected' => 'Rechazado',
      'accepted' => 'Aceptado',
      'fundsheld' => 'Fondos retenidos',
      'pinsgenerated' => 'PIN listos',
      'pickedup' => 'Recogido',
      'intransit' => 'En tránsito',
      'logisticscenter' => 'En centro logístico',
      'outfordelivery' => 'En reparto',
      'arriveddestination' => 'Llegó al destino',
      'senderpinvalidated' => 'PIN emisor confirmado',
      'receiverpinvalidated' => 'PIN receptor confirmado',
      'deliveryconfirmed' => 'Entrega confirmada',
      'paymentreleased' => 'Pago liberado',
      'completed' => 'Completado',
      'cancelled' => 'Cancelado',
      'expired' => 'Expirado',
      'disputed' => 'En disputa',
      'refunded' => 'Reembolsado',
      'failed' => 'Fallido',
      _ => _humanize(statusName),
    };
  }

  static Color secureShipmentStatusColor(String? statusName) {
    final key = (statusName ?? '').replaceAll('_', '').toLowerCase();
    if (key.contains('pending') || key.contains('accepted')) {
      return const Color(0xFFE6A817);
    }
    if (key.contains('completed') ||
        key.contains('paymentreleased') ||
        key.contains('deliveryconfirmed')) {
      return const Color(0xFF2E7D52);
    }
    if (key.contains('disputed') ||
        key.contains('rejected') ||
        key.contains('failed') ||
        key.contains('cancelled')) {
      return const Color(0xFFC62828);
    }
    if (key.contains('fundsheld') || key.contains('pins')) {
      return const Color(0xFF1565C0);
    }
    return const Color(0xFF757575);
  }

  static String _humanize(String value) {
    if (value.contains('_')) {
      return value
          .split('_')
          .map(
            (part) => part.isEmpty
                ? ''
                : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
          )
          .join(' ');
    }
    if (RegExp(r'^[a-z]+([A-Z][a-z]+)+$').hasMatch(value)) {
      return value.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (m) => '${m.group(1)} ${m.group(2)}',
      );
    }
    return value;
  }
}
