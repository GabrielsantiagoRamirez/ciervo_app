import 'dart:math';

import 'package:flutter/foundation.dart';

import '../storage/secure_storage.dart';

class DeviceInstallationService {
  DeviceInstallationService(this._storage, {Random? random})
    : _random = random ?? Random.secure();

  static const _deviceIdKey = 'ciervo.device.installationId';

  final SecureStorage _storage;
  final Random _random;
  String? _cachedId;

  Future<String> deviceId() async {
    final cached = _cachedId;
    if (cached != null) return cached;

    final stored = await _storage.read(_deviceIdKey);
    if (stored != null && _isValid(stored)) {
      return _cachedId = stored;
    }

    final generated = _uuidV4();
    await _storage.write(_deviceIdKey, generated);
    _cachedId = generated;
    return generated;
  }

  String get platform => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux => 'linux',
    TargetPlatform.fuchsia => 'fuchsia',
  };

  bool _isValid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-'
      r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
