import '../../domain/entities/app_notification.dart';

class AppNotificationDto {
  const AppNotificationDto({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.isRead,
    this.type,
    this.category,
    this.businessId,
    this.eventId,
    this.productId,
    this.serviceId,
    this.promotionId,
    this.discountId,
    this.giftCardId,
    this.benefitId,
    this.rewardId,
    this.couponId,
    this.bookingId,
    this.ticketId,
    this.qrId,
    this.deepLink,
    this.metadataJson,
  });

  factory AppNotificationDto.fromJson(Map<String, dynamic> json) {
    final title = _s(json, const ['title', 'subject']);
    return AppNotificationDto(
      id: _s(json, const ['id', 'notificationId']),
      title: title.isEmpty ? 'Notificacion' : title,
      message: _s(json, const ['message', 'body', 'description']),
      date: DateTime.tryParse(_s(json, const ['createdAt', 'date', 'sentAt'])),
      isRead: _b(json, const ['isRead', 'read']),
      type: _s(json, const ['type']),
      category: _s(json, const ['category']),
      businessId: _i(json['businessId']),
      eventId: _i(json['eventId']),
      productId: _i(json['productId']),
      serviceId: _i(json['serviceId']),
      promotionId: _i(json['promotionId']),
      discountId: _i(json['discountId']),
      giftCardId: _i(json['giftCardId']),
      benefitId: _i(json['benefitId']),
      rewardId: _i(json['rewardId']),
      couponId: _i(json['couponId']),
      bookingId: _i(json['bookingId']),
      ticketId: _i(json['ticketId']),
      qrId: _i(json['qrId']),
      deepLink: _s(json, const ['deepLink']),
      metadataJson: _s(json, const ['metadataJson']),
    );
  }

  final String id;
  final String title;
  final String message;
  final DateTime? date;
  final bool isRead;
  final String? type;
  final String? category;
  final int? businessId;
  final int? eventId;
  final int? productId;
  final int? serviceId;
  final int? promotionId;
  final int? discountId;
  final int? giftCardId;
  final int? benefitId;
  final int? rewardId;
  final int? couponId;
  final int? bookingId;
  final int? ticketId;
  final int? qrId;
  final String? deepLink;
  final String? metadataJson;

  AppNotification toDomain() => AppNotification(
    id: id,
    title: title,
    message: message,
    date: date,
    isRead: isRead,
    type: type,
    category: category,
    businessId: businessId,
    eventId: eventId,
    productId: productId,
    serviceId: serviceId,
    promotionId: promotionId,
    discountId: discountId,
    giftCardId: giftCardId,
    benefitId: benefitId,
    rewardId: rewardId,
    couponId: couponId,
    bookingId: bookingId,
    ticketId: ticketId,
    qrId: qrId,
    deepLink: deepLink,
    metadataJson: metadataJson,
  );

  static List<AppNotificationDto> listFrom(dynamic value) {
    final source = value is Map<String, dynamic>
        ? value['value'] ?? value['data'] ?? value
        : value;
    final items = source is List
        ? source
        : source is Map<String, dynamic> && source['items'] is List
        ? source['items'] as List
        : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(AppNotificationDto.fromJson)
        .toList();
  }

  static String _s(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  static int? _i(dynamic value) => value is int ? value : int.tryParse('$value');

  static bool _b(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value != null) return value.toString().toLowerCase() == 'true';
    }
    return false;
  }
}
