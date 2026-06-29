import 'dart:convert';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.body,
    required this.messageType,
    required this.isMine,
    this.senderName,
    this.sentAt,
    this.attachmentUrl,
    this.metadataJson,
  });

  final String id;
  final String body;
  final String messageType;
  final bool isMine;
  final String? senderName;
  final DateTime? sentAt;
  final String? attachmentUrl;
  final String? metadataJson;

  Map<String, dynamic>? get _metadata {
    if (metadataJson == null || metadataJson!.isEmpty) return null;
    try {
      final decoded = jsonDecode(metadataJson!);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  BookingReceipt? get bookingReceipt {
    if (messageType != 'System' || _metadata == null) return null;
    if (_metadata!['type'] != 'booking_receipt') return null;
    final booking = _metadata!['booking'] ?? _metadata!['receipt'] ?? _metadata;
    if (booking is! Map) return null;
    return BookingReceipt.fromJson(Map<String, dynamic>.from(booking));
  }

  ChatLocationPayload? get locationPayload {
    final type = messageType.toLowerCase();
    if (type != 'location') return null;
    final meta = _metadata;
    if (meta == null) return null;
    return ChatLocationPayload.fromJson(meta);
  }

  ChatSharePayload? get sharePayload {
    final type = messageType.toLowerCase();
    if (type != 'share') return null;
    final meta = _metadata;
    if (meta == null) return null;
    return ChatSharePayload.fromJson(meta);
  }

  ChatPaymentPayload? get paymentPayload {
    final type = messageType.toLowerCase();
    if (type != 'payment') return null;
    final meta = _metadata;
    if (meta == null) return null;
    return ChatPaymentPayload.fromJson(meta);
  }

  ChatGiftPayload? get giftPayload {
    final type = messageType.toLowerCase();
    if (type != 'gift') return null;
    final meta = _metadata;
    if (meta == null) return null;
    return ChatGiftPayload.fromJson(meta);
  }
}

class ChatLocationPayload {
  const ChatLocationPayload({
    required this.latitude,
    required this.longitude,
    this.label,
  });

  factory ChatLocationPayload.fromJson(Map<String, dynamic> json) {
    return ChatLocationPayload(
      latitude: _double(json['latitude'] ?? json['lat']) ?? 0,
      longitude: _double(json['longitude'] ?? json['lng'] ?? json['lon']) ?? 0,
      label: json['label']?.toString() ?? json['address']?.toString(),
    );
  }

  final double latitude;
  final double longitude;
  final String? label;
}

class ChatSharePayload {
  const ChatSharePayload({
    required this.shareType,
    required this.title,
    this.subtitle,
    this.referenceId,
    this.url,
  });

  factory ChatSharePayload.fromJson(Map<String, dynamic> json) {
    return ChatSharePayload(
      shareType: '${json['shareType'] ?? json['type'] ?? 'Share'}',
      title: '${json['title'] ?? json['name'] ?? 'Compartido'}',
      subtitle: json['subtitle']?.toString(),
      referenceId: json['referenceId']?.toString() ?? json['id']?.toString(),
      url: json['url']?.toString(),
    );
  }

  final String shareType;
  final String title;
  final String? subtitle;
  final String? referenceId;
  final String? url;
}

class ChatPaymentPayload {
  const ChatPaymentPayload({
    required this.amount,
    required this.currency,
    required this.status,
    this.description,
  });

  factory ChatPaymentPayload.fromJson(Map<String, dynamic> json) {
    return ChatPaymentPayload(
      amount: _num(json['amount']) ?? 0,
      currency: '${json['currency'] ?? 'COP'}',
      status: '${json['status'] ?? json['paymentStatus'] ?? ''}',
      description: json['description']?.toString(),
    );
  }

  final num amount;
  final String currency;
  final String status;
  final String? description;
}

class ChatGiftPayload {
  const ChatGiftPayload({
    required this.giftType,
    required this.amount,
    required this.currency,
    this.description,
  });

  factory ChatGiftPayload.fromJson(Map<String, dynamic> json) {
    return ChatGiftPayload(
      giftType: '${json['giftType'] ?? json['type'] ?? 'Gift'}',
      amount: _num(json['amount']) ?? 0,
      currency: '${json['currency'] ?? 'COP'}',
      description: json['description']?.toString(),
    );
  }

  final String giftType;
  final num amount;
  final String currency;
  final String? description;
}

class BookingReceipt {
  const BookingReceipt({
    required this.publicCode,
    required this.business,
    required this.client,
    required this.bookingType,
    required this.status,
    required this.currency,
    this.bookingDate,
    this.total,
  });

  factory BookingReceipt.fromJson(Map<String, dynamic> json) {
    final business = json['business'];
    final client = json['client'];
    return BookingReceipt(
      publicCode: '${json['publicCode'] ?? ''}',
      business: _name(business),
      client: _name(client),
      bookingDate: DateTime.tryParse('${json['bookingDate'] ?? ''}'),
      bookingType: '${json['bookingType'] ?? ''}',
      status: '${json['status'] ?? ''}',
      total: _num(json['total'] ?? json['totalAmount']),
      currency: '${json['currency'] ?? ''}',
    );
  }

  final String publicCode;
  final String business;
  final String client;
  final DateTime? bookingDate;
  final String bookingType;
  final String status;
  final num? total;
  final String currency;
}

String _name(dynamic value) {
  if (value is Map) {
    return '${value['name'] ?? value['businessName'] ?? value['fullName'] ?? ''}';
  }
  return '${value ?? ''}';
}

double? _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value');

num? _num(dynamic value) => value is num ? value : num.tryParse('$value');
