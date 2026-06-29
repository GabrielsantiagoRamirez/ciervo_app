import 'package:ciervo_clud/core/experience/experience_mode.dart';
import 'package:ciervo_clud/core/experience/experience_mode_cubit.dart';
import 'package:ciervo_clud/core/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restore remembers mode without selecting it for the session', () async {
    final storage = _MemorySecureStorage({'ciervo.experienceMode': 'day'});
    final cubit = ExperienceModeCubit(storage);

    await cubit.restore();

    expect(cubit.state.mode, ExperienceMode.day);
    expect(cubit.state.hasSelection, isFalse);
    await cubit.close();
  });

  test('setMode selects and persists the chosen mode', () async {
    final storage = _MemorySecureStorage();
    final cubit = ExperienceModeCubit(storage);

    await cubit.setMode(ExperienceMode.night);

    expect(cubit.state.mode, ExperienceMode.night);
    expect(cubit.state.hasSelection, isTrue);
    expect(await storage.read('ciervo.experienceMode'), 'night');
    await cubit.close();
  });
}

class _MemorySecureStorage implements SecureStorage {
  _MemorySecureStorage([Map<String, String>? values])
    : _values = {...?values};

  final Map<String, String> _values;

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> deleteAll() async => _values.clear();

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}
