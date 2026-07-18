import 'dart:math';

import 'package:ciervo_clud/core/device/device_installation_service.dart';
import 'package:ciervo_clud/core/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates and reuses a stable installation UUID', () async {
    final storage = _MemorySecureStorage();
    final first = DeviceInstallationService(storage, random: Random(7));

    final generated = await first.deviceId();
    final nextLaunch = DeviceInstallationService(storage, random: Random(8));

    expect(
      generated,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
          r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(await nextLaunch.deviceId(), generated);
  });
}

class _MemorySecureStorage implements SecureStorage {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> deleteAll() async => _values.clear();

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
