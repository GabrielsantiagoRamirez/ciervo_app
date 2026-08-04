import '../../domain/entities/recharge_intent.dart';
import '../../domain/entities/resolved_wallet_user.dart';
import '../../domain/entities/transfer_directory_entry.dart';
import '../../domain/entities/transfer_result.dart';

class RechargeIntentDto {
  const RechargeIntentDto({
    required this.id,
    required this.preferenceId,
    required this.checkoutUrl,
    required this.status,
  });

  factory RechargeIntentDto.fromJson(Map<String, dynamic> json) {
    final data = json['value'] ?? json['data'];
    final source = data is Map<String, dynamic> ? data : json;
    final intent = source['intent'];
    final intentSource = intent is Map<String, dynamic> ? intent : source;
    return RechargeIntentDto(
      id: _string(intentSource, const ['id', 'paymentIntentId', 'intentId']),
      preferenceId: _string(source, const ['preferenceId', 'preference_id']),
      checkoutUrl: _string(source, const [
        'checkoutUrl',
        'initPoint',
        'init_point',
      ]),
      status: _string(intentSource, const ['status']).isEmpty
          ? 'pending'
          : _string(intentSource, const ['status']),
    );
  }

  final String id;
  final String preferenceId;
  final String checkoutUrl;
  final String status;

  RechargeIntent toDomain() => RechargeIntent(
    id: id,
    preferenceId: preferenceId,
    checkoutUrl: checkoutUrl,
    status: status,
  );
}

class ResolvedWalletUserDto {
  const ResolvedWalletUserDto({
    required this.userId,
    required this.ciervoUserCode,
    required this.displayName,
    this.username,
    this.photoUrl,
    this.countryCode,
    this.localCurrency,
    this.isVerified = false,
    this.isBusiness = false,
    this.isFavorite = false,
  });

  factory ResolvedWalletUserDto.fromJson(Map<String, dynamic> json) {
    final data = json['value'] ?? json['data'];
    final source = data is Map<String, dynamic> ? data : json;
    return ResolvedWalletUserDto(
      userId: _string(source, const ['userId', 'id', 'clientId']),
      ciervoUserCode: _string(source, const [
        'ciervoUserCode',
        'userCode',
        'ciervoId',
      ]),
      displayName: _string(source, const ['displayName', 'name', 'maskedName']),
      username: _nullableString(source, const ['username', 'userName', 'handle']),
      photoUrl: _nullableString(source, const [
        'photoUrl',
        'profilePhotoUrl',
        'avatarUrl',
      ]),
      countryCode: _nullableString(source, const [
        'countryCode',
        'country',
        'localCountryCode',
      ]),
      localCurrency: _nullableString(source, const [
        'localCurrency',
        'currency',
      ]),
      isVerified: source['isVerified'] == true || source['verified'] == true,
      isBusiness: source['isBusiness'] == true || source['business'] == true,
      isFavorite: source['isFavorite'] == true || source['favorite'] == true,
    );
  }

  final String userId;
  final String ciervoUserCode;
  final String displayName;
  final String? username;
  final String? photoUrl;
  final String? countryCode;
  final String? localCurrency;
  final bool isVerified;
  final bool isBusiness;
  final bool isFavorite;

  ResolvedWalletUser toDomain() => ResolvedWalletUser(
    userId: userId,
    ciervoUserCode: ciervoUserCode,
    displayName: displayName,
    username: username,
    photoUrl: photoUrl,
    countryCode: countryCode,
    localCurrency: localCurrency,
    isVerified: isVerified,
    isBusiness: isBusiness,
    isFavorite: isFavorite,
  );
}

class TransferDirectoryEntryDto {
  const TransferDirectoryEntryDto({
    required this.userId,
    required this.displayName,
    this.ciervoUserCode,
    this.username,
    this.photoUrl,
    this.countryCode,
    this.localCurrency,
    this.isVerified = false,
    this.isBusiness = false,
    this.isFavorite = false,
    this.lastTransferAt,
    this.lastTransferLabel,
  });

  factory TransferDirectoryEntryDto.fromJson(Map<String, dynamic> json) {
    return TransferDirectoryEntryDto(
      userId: _string(json, const ['userId', 'id', 'clientId', 'favoriteUserId']),
      displayName: _string(json, const [
        'displayName',
        'name',
        'fullName',
        'maskedName',
      ]),
      ciervoUserCode: _nullableString(json, const [
        'ciervoUserCode',
        'userCode',
        'ciervoId',
      ]),
      username: _nullableString(json, const ['username', 'userName', 'handle']),
      photoUrl: _nullableString(json, const [
        'photoUrl',
        'profilePhotoUrl',
        'avatarUrl',
      ]),
      countryCode: _nullableString(json, const ['countryCode', 'country']),
      localCurrency: _nullableString(json, const [
        'localCurrency',
        'currency',
      ]),
      isVerified: json['isVerified'] == true || json['verified'] == true,
      isBusiness: json['isBusiness'] == true || json['business'] == true,
      isFavorite: json['isFavorite'] == true || json['favorite'] == true,
      lastTransferAt: _date(json['lastTransferAt'] ?? json['lastTransferDate']),
      lastTransferLabel: _nullableString(json, const [
        'lastTransferLabel',
        'lastTransferSummary',
        'lastAmountLabel',
      ]),
    );
  }

  final String userId;
  final String displayName;
  final String? ciervoUserCode;
  final String? username;
  final String? photoUrl;
  final String? countryCode;
  final String? localCurrency;
  final bool isVerified;
  final bool isBusiness;
  final bool isFavorite;
  final DateTime? lastTransferAt;
  final String? lastTransferLabel;

  TransferDirectoryEntry toDomain() => TransferDirectoryEntry(
    userId: userId,
    displayName: displayName.isEmpty ? 'Usuario CIERVO' : displayName,
    ciervoUserCode: ciervoUserCode,
    username: username,
    photoUrl: photoUrl,
    countryCode: countryCode,
    localCurrency: localCurrency,
    isVerified: isVerified,
    isBusiness: isBusiness,
    isFavorite: isFavorite,
    lastTransferAt: lastTransferAt,
    lastTransferLabel: lastTransferLabel,
  );

  static List<TransferDirectoryEntryDto> listFrom(dynamic value) {
    final list = value is List
        ? value
        : value is Map && value['items'] is List
        ? value['items'] as List
        : value is Map && value['results'] is List
        ? value['results'] as List
        : const [];
    return list
        .whereType<Map>()
        .map(
          (item) => TransferDirectoryEntryDto.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((item) => item.userId.isNotEmpty || (item.ciervoUserCode?.isNotEmpty ?? false))
        .toList();
  }
}

class TransferResultDto {
  const TransferResultDto({
    required this.id,
    required this.status,
    this.message,
  });

  factory TransferResultDto.fromJson(Map<String, dynamic> json) {
    final data = json['value'] ?? json['data'];
    final source = data is Map<String, dynamic> ? data : json;
    return TransferResultDto(
      id: _string(source, const ['id', 'transferId', 'paymentIntentId']),
      status: _string(source, const ['status']).isEmpty
          ? 'completed'
          : _string(source, const ['status']),
      message: _string(source, const ['message']),
    );
  }

  final String id;
  final String status;
  final String? message;

  TransferResult toDomain() =>
      TransferResult(id: id, status: status, message: message);
}

String _string(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  return '';
}

String? _nullableString(Map<String, dynamic> json, List<String> keys) {
  final text = _string(json, keys).trim();
  return text.isEmpty ? null : text;
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse('$value');
}
