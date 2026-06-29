import '../../domain/entities/recharge_intent.dart';
import '../../domain/entities/resolved_wallet_user.dart';
import '../../domain/entities/transfer_result.dart';

class RechargeIntentDto {
  const RechargeIntentDto({
    required this.id,
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
  final String checkoutUrl;
  final String status;

  RechargeIntent toDomain() =>
      RechargeIntent(id: id, checkoutUrl: checkoutUrl, status: status);
}

class ResolvedWalletUserDto {
  const ResolvedWalletUserDto({
    required this.userId,
    required this.ciervoUserCode,
    required this.displayName,
  });

  factory ResolvedWalletUserDto.fromJson(Map<String, dynamic> json) {
    final data = json['value'] ?? json['data'];
    final source = data is Map<String, dynamic> ? data : json;
    return ResolvedWalletUserDto(
      userId: _string(source, const ['userId', 'id', 'clientId']),
      ciervoUserCode: _string(source, const ['ciervoUserCode', 'userCode']),
      displayName: _string(source, const ['displayName', 'name', 'maskedName']),
    );
  }

  final String userId;
  final String ciervoUserCode;
  final String displayName;

  ResolvedWalletUser toDomain() => ResolvedWalletUser(
    userId: userId,
    ciervoUserCode: ciervoUserCode,
    displayName: displayName,
  );
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
