import 'package:dio/dio.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/idempotency_key.dart';

class CurrentPromotion {
  const CurrentPromotion({
    required this.id,
    required this.title,
    required this.description,
    required this.eligible,
    required this.slotsRemaining,
    required this.termsUrl,
  });

  final String id;
  final String title;
  final String description;
  final bool eligible;
  final int? slotsRemaining;
  final String? termsUrl;

  factory CurrentPromotion.fromJson(Map<String, dynamic> json) {
    return CurrentPromotion(
      id: '${json['id'] ?? json['promotionId'] ?? 'gold-trial-200'}',
      title: '${json['title'] ?? 'Plan Gold gratis 60 días'}',
      description: '${json['description'] ?? json['body'] ?? ''}',
      eligible: json['eligible'] == true || json['isEligible'] == true,
      slotsRemaining: _int(json['slotsRemaining'] ?? json['remainingSlots']),
      termsUrl: json['termsUrl']?.toString(),
    );
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value');
  }
}

class GoldTrialClaimResult {
  const GoldTrialClaimResult({
    required this.promotionId,
    required this.planCode,
    required this.planName,
    required this.status,
    required this.trialDays,
    required this.termsAccepted,
    required this.message,
    this.membershipId,
    this.startsAt,
    this.expiresAt,
  });

  final String promotionId;
  final int? membershipId;
  final String planCode;
  final String planName;
  final String status;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final int trialDays;
  final bool termsAccepted;
  final String message;

  factory GoldTrialClaimResult.fromJson(Map<String, dynamic> json) {
    return GoldTrialClaimResult(
      promotionId: '${json['promotionId'] ?? json['id'] ?? 'gold-trial-200'}',
      membershipId: _int(json['membershipId']),
      planCode: '${json['planCode'] ?? 'gold'}',
      planName: '${json['planName'] ?? 'CIERVO GOLD'}',
      status: '${json['status'] ?? 'Active'}',
      startsAt: DateTime.tryParse('${json['startsAt'] ?? ''}'),
      expiresAt: DateTime.tryParse('${json['expiresAt'] ?? ''}'),
      trialDays: _int(json['trialDays']) ?? 60,
      termsAccepted: json['termsAccepted'] == true,
      message: '${json['message'] ?? 'Plan Gold activado por 60 días.'}',
    );
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value');
  }
}

class PromotionsRepository {
  PromotionsRepository(this._client, this._storage);

  final NetworkClient _client;
  final SecureStorage _storage;

  static const _dismissedKey = 'promotion_gold_trial_dismissed';
  static const _claimIdempotencyKey = 'promotion_gold_trial_idempotency_key';

  Future<bool> wasDismissed() async {
    final value = await _storage.read(_dismissedKey);
    return value == 'true';
  }

  Future<void> markDismissed() => _storage.write(_dismissedKey, 'true');

  Future<Result<CurrentPromotion?>> current() async {
    try {
      final response = await _client.dio.get<dynamic>('/api/promotions/current');
      final raw = unwrapApiResponse(response.data);
      if (raw == null) return const Success(null);
      if (raw is Map) {
        return Success(
          CurrentPromotion.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
      return const Success(null);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const Success(null);
      }
      return Failure(ErrorMapper.fromObject(error));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  Future<Result<GoldTrialClaimResult>> claimGoldTrial({
    required bool acceptedTerms,
  }) async {
    final idempotencyKey = await _readOrCreateClaimIdempotencyKey();
    try {
      final response = await _client.dio.post<dynamic>(
        '/api/promotions/gold-trial/claim',
        data: {
          'acceptedTerms': acceptedTerms,
          'idempotencyKey': idempotencyKey,
        },
      );
      final result = GoldTrialClaimResult.fromJson(
        unwrapApiMap(response.data),
      );
      await _clearClaimIdempotencyKey();
      return Success(result);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  Future<String> _readOrCreateClaimIdempotencyKey() async {
    final existing = await _storage.read(_claimIdempotencyKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }
    final key = IdempotencyKey.generate('gold-trial');
    await _storage.write(_claimIdempotencyKey, key);
    return key;
  }

  Future<void> _clearClaimIdempotencyKey() =>
      _storage.delete(_claimIdempotencyKey);
}
