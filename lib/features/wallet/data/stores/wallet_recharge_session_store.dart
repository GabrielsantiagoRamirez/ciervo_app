import 'dart:convert';

import '../../../../core/storage/secure_storage.dart';
import '../models/wallet_recharge_session.dart';

class WalletRechargeSessionStore {
  const WalletRechargeSessionStore(this._storage);

  static const storageKey = 'wallet.recharge.session.v1';

  final SecureStorage _storage;

  Future<WalletRechargeSession?> read() async {
    final encoded = await _storage.read(storageKey);
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final json = jsonDecode(encoded);
      if (json is! Map<String, dynamic>) {
        await clear();
        return null;
      }
      return WalletRechargeSession.fromJson(json);
    } on FormatException {
      await clear();
      return null;
    }
  }

  Future<void> write(WalletRechargeSession session) {
    return _storage.write(storageKey, jsonEncode(session.toJson()));
  }

  Future<void> clear() => _storage.delete(storageKey);

  Future<WalletRechargeSession?> readCompatible({
    required String currency,
    required String countryCode,
    required double amount,
    required String cardId,
  }) async {
    final session = await read();
    if (session == null) return null;
    if (!session.isCompatibleWith(
      currency: currency,
      countryCode: countryCode,
      amount: amount,
      cardId: cardId,
    )) {
      await clear();
      return null;
    }
    return session;
  }
}
