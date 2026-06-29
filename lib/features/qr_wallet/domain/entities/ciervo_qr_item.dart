enum CiervoQrType { booking, ticket, giftCard, benefit }

enum CiervoQrStatus { active, used, expired, cancelled, unknown }

class CiervoQrItem {
  const CiervoQrItem({
    required this.id,
    required this.type,
    required this.status,
    required this.reference,
    this.title,
    this.subtitle,
    this.qrId,
    this.qrPayload,
    this.expiresAt,
    this.eventDate,
    this.pin,
    this.points,
    this.rawStatus,
    this.redeemPath,
  });

  final String id;
  final CiervoQrType type;
  final CiervoQrStatus status;
  final String reference;
  final String? title;
  final String? subtitle;
  final String? qrId;
  final String? qrPayload;
  final DateTime? expiresAt;
  final DateTime? eventDate;
  final String? pin;
  final int? points;
  final String? rawStatus;
  final String? redeemPath;

  bool get hasQr =>
      (qrPayload?.isNotEmpty ?? false) || (qrId?.isNotEmpty ?? false);
  bool get canRedeemFromCatalog => redeemPath != null && redeemPath!.isNotEmpty;
}
