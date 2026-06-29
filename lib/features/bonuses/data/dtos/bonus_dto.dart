import '../../domain/entities/bonus.dart';

class BonusDto {
  const BonusDto({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.businessId,
    required this.businessName,
    required this.currency,
    this.discountPercent,
    this.discountAmount,
    this.cashbackAmount,
    this.savingsAmount,
    this.imageUrl,
    this.validFrom,
    this.validUntil,
    this.claimedAt,
    this.redeemedAt,
    this.promoCode,
    this.paymentMethod,
    this.city,
    this.zone,
    this.country,
    this.distanceKm,
    this.canRedeem = false,
    this.userClaimId,
  });

  final String id;
  final String title;
  final String description;
  final BonusType type;
  final BonusStatus status;
  final String businessId;
  final String businessName;
  final String currency;
  final double? discountPercent;
  final double? discountAmount;
  final double? cashbackAmount;
  final double? savingsAmount;
  final String? imageUrl;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime? claimedAt;
  final DateTime? redeemedAt;
  final String? promoCode;
  final String? paymentMethod;
  final String? city;
  final String? zone;
  final String? country;
  final double? distanceKm;
  final bool canRedeem;
  final String? userClaimId;

  factory BonusDto.fromJson(Map<String, dynamic> json) {
    final business = json['business'] is Map
        ? Map<String, dynamic>.from(json['business'] as Map)
        : null;
    final type = BonusType.fromApi(
          '${json['type'] ?? json['bonusType'] ?? ''}',
        ) ??
        BonusType.coupon;
    final status = _resolveStatus(json);
    return BonusDto(
      id: _string(json, const ['id', 'bonusId', 'userBonusId']),
      title: _string(json, const ['title', 'name']),
      description: _string(json, const ['description', 'summary', 'details']),
      type: type,
      status: status,
      businessId: _string(
        json,
        const ['businessId'],
        fallback: _string(business ?? {}, const ['id', 'businessId']),
      ),
      businessName: _string(
        json,
        const ['businessName', 'businessTitle'],
        fallback: _string(business ?? {}, const ['name', 'title']),
      ),
      currency: _string(json, const ['currency', 'currencyCode'], fallback: 'COP'),
      discountPercent: _doubleOrNull(
        json['discountPercent'] ?? json['percentOff'] ?? json['discount'],
      ),
      discountAmount: _doubleOrNull(json['discountAmount'] ?? json['amountOff']),
      cashbackAmount: _doubleOrNull(json['cashbackAmount'] ?? json['cashback']),
      savingsAmount: _doubleOrNull(json['savingsAmount'] ?? json['savings']),
      imageUrl: _media(json),
      validFrom: _date(json['validFrom'] ?? json['startsAt'] ?? json['startDate']),
      validUntil: _date(json['validUntil'] ?? json['expiresAt'] ?? json['endDate']),
      claimedAt: _date(json['claimedAt']),
      redeemedAt: _date(json['redeemedAt'] ?? json['usedAt']),
      promoCode: _nullable(json['promoCode'] ?? json['code']),
      paymentMethod: _nullable(json['paymentMethod']),
      city: _nullable(json['city'] ?? business?['city']),
      zone: _nullable(json['zone'] ?? business?['zone']),
      country: _nullable(json['country'] ?? json['countryCode'] ?? business?['country']),
      distanceKm: _doubleOrNull(json['distanceKm'] ?? json['distance']),
      canRedeem: json['canRedeem'] == true || json['redeemable'] == true,
      userClaimId: _nullable(json['userClaimId'] ?? json['claimId']),
    );
  }

  Bonus toEntity() => Bonus(
        id: id,
        title: title,
        description: description,
        type: type,
        status: status,
        businessId: businessId,
        businessName: businessName,
        currency: currency,
        discountPercent: discountPercent,
        discountAmount: discountAmount,
        cashbackAmount: cashbackAmount,
        savingsAmount: savingsAmount,
        imageUrl: imageUrl,
        validFrom: validFrom,
        validUntil: validUntil,
        claimedAt: claimedAt,
        redeemedAt: redeemedAt,
        promoCode: promoCode,
        paymentMethod: paymentMethod,
        city: city,
        zone: zone,
        country: country,
        distanceKm: distanceKm,
        canRedeem: canRedeem,
        userClaimId: userClaimId,
      );

  static List<BonusDto> listFromResponse(dynamic response) {
    final items = _unwrapList(response);
    return items.map(BonusDto.fromJson).toList();
  }
}

BonusStatus _resolveStatus(Map<String, dynamic> json) {
  final userStatus = BonusStatus.fromApi('${json['userStatus'] ?? ''}');
  if (userStatus != null) return userStatus;
  if (json['redeemedAt'] != null || json['usedAt'] != null) {
    return BonusStatus.redeemed;
  }
  if (json['claimedAt'] != null) return BonusStatus.claimed;
  return BonusStatus.fromApi('${json['status'] ?? json['bonusStatus'] ?? ''}') ??
      BonusStatus.active;
}

List<Map<String, dynamic>> _unwrapList(dynamic response) {
  dynamic source = response;
  if (source is Map<String, dynamic> && source.containsKey('data')) {
    source = source['data'];
  }
  final items = source is List
      ? source
      : source is Map<String, dynamic> && source['items'] is List
          ? source['items'] as List
          : const [];
  return items
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String _string(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  return fallback;
}

String? _nullable(dynamic value) =>
    value == null || value.toString().isEmpty ? null : value.toString();

double? _doubleOrNull(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}');
}

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());

String? _media(Map<String, dynamic> json) {
  final direct = _nullable(
    json['imageUrl'] ??
        json['imageMediaId'] ??
        json['coverMediaId'] ??
        json['mediaId'],
  );
  if (direct != null) return direct;
  final image = json['image'];
  if (image is Map) {
    return _nullable(image['id'] ?? image['mediaId'] ?? image['url']);
  }
  return null;
}
