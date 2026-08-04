import 'dart:convert';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/idempotency_key.dart';
import '../domain/entities/durable_user_pin.dart';

/// PIN semanal asociado al usuario vía `POST /api/pins/durable` (producción).
class DurablePinService {
  DurablePinService({
    required NetworkClient client,
    required SecureStorage storage,
  }) : _client = client,
       _storage = storage;

  static const _storageKeyPrefix = 'ciervo.durablePin.';
  static const helpSeenKey = 'ciervo.durablePin.helpSeen';

  final NetworkClient _client;
  final SecureStorage _storage;

  Future<bool> hasSeenHelp() async =>
      (await _storage.read(helpSeenKey)) == 'true';

  Future<void> markHelpSeen() => _storage.write(helpSeenKey, 'true');

  Future<Result<DurableUserPin>> ensureActive({
    required String ownerUserId,
    required String walletCardId,
    required String currency,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cached = await _readLocal(ownerUserId);
        if (cached != null &&
            !cached.isExpired &&
            cached.paymentPinId != null &&
            cached.code.isNotEmpty &&
            cached.walletCardId == walletCardId) {
          return Success(cached);
        }
      }

      final pin = await _fetchDurable(
        ownerUserId: ownerUserId,
        walletCardId: walletCardId,
        currency: currency,
      );
      await _writeLocal(pin);
      return Success(pin);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  Future<Result<DurableUserPin?>> current(String ownerUserId) async {
    try {
      final local = await _readLocal(ownerUserId);
      if (local == null || local.isExpired || local.code.isEmpty) {
        return const Success(null);
      }
      return Success(local);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  Future<DurableUserPin> _fetchDurable({
    required String ownerUserId,
    required String walletCardId,
    required String currency,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/pins/durable',
      data: {
        'walletCardId': int.tryParse(walletCardId) ?? walletCardId,
        if (currency.trim().isNotEmpty)
          'currency': currency.trim().toUpperCase(),
        'idempotencyKey': IdempotencyKey.generate(),
      },
    );
    final map = unwrapApiMap(response.data);
    final code = '${map['pin'] ?? map['code'] ?? map['pinCode'] ?? ''}';
    final paymentPinId =
        '${map['paymentPinId'] ?? map['id'] ?? map['pinId'] ?? ''}';
    if (code.isEmpty || paymentPinId.isEmpty) {
      throw StateError('El servidor no devolvió el PIN semanal completo.');
    }

    final now = DateTime.now().toUtc();
    return DurableUserPin(
      code: code,
      ownerUserId: ownerUserId,
      walletCardId: walletCardId,
      currency: '${map['currency'] ?? currency}'.trim().isEmpty
          ? currency
          : '${map['currency']}',
      validFrom:
          DateTime.tryParse(
            '${map['validFrom'] ?? map['createdAt'] ?? ''}',
          )?.toUtc() ??
          now,
      expiresAt:
          DateTime.tryParse(
            '${map['expiresAt'] ?? map['nextRotationAt'] ?? ''}',
          )?.toUtc() ??
          now.add(const Duration(days: 7)),
      paymentPinId: paymentPinId,
    );
  }

  Future<DurableUserPin?> _readLocal(String ownerUserId) async {
    final raw = await _storage.read('$_storageKeyPrefix$ownerUserId');
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return DurableUserPin.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<void> _writeLocal(DurableUserPin pin) async {
    await _storage.write(
      '$_storageKeyPrefix${pin.ownerUserId}',
      jsonEncode(pin.toJson()),
    );
  }
}
