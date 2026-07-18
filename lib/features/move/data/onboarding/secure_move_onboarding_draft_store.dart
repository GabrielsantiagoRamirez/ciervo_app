import 'dart:convert';

import '../../../../core/storage/secure_storage.dart';
import '../../domain/onboarding/move_onboarding_draft.dart';
import 'sha256.dart';

class SecureMoveOnboardingDraftStore implements MoveOnboardingDraftStore {
  SecureMoveOnboardingDraftStore(this._storage, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final SecureStorage _storage;
  final DateTime Function() _now;

  static const _operations = {
    'identity',
    'license',
    'vehicle',
    'operations',
    'submit',
  };

  @override
  Future<MoveOnboardingDraft?> read(String userId) async {
    final raw = await _storage.read(_storageKey(userId));
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return MoveOnboardingDraft.fromJson(Map<String, dynamic>.from(decoded));
  }

  @override
  Future<void> write(String userId, MoveOnboardingDraft draft) {
    _requireUser(userId);
    if (draft.countryCode != null &&
        draft.countryCode != 'CO' &&
        draft.countryCode != 'CL') {
      throw ArgumentError.value(draft.countryCode, 'countryCode');
    }
    final sanitizedAssets = <String, int>{
      for (final entry in draft.assetIds.entries)
        if (entry.key.trim().isNotEmpty && entry.value > 0)
          entry.key.trim(): entry.value,
    };
    final safeDraft = draft.copyWith(
      assetIds: Map.unmodifiable(sanitizedAssets),
      updatedAt: _now().toUtc(),
    );
    return _storage.write(_storageKey(userId), jsonEncode(safeDraft.toJson()));
  }

  @override
  Future<MoveOnboardingIntent> saveIntent({
    required String userId,
    required String operation,
    required String idempotencyKey,
    required Map<String, dynamic> payload,
  }) async {
    _requireUser(userId);
    final normalizedOperation = operation.trim().toLowerCase();
    if (!_operations.contains(normalizedOperation)) {
      throw ArgumentError.value(operation, 'operation');
    }
    final normalizedKey = idempotencyKey.trim();
    if (normalizedKey.isEmpty || normalizedKey.length > 120) {
      throw ArgumentError.value(idempotencyKey, 'idempotencyKey');
    }
    final payloadHash = sha256Hex(_canonicalJson(payload));
    final draft = await read(userId) ?? const MoveOnboardingDraft();
    final existing = draft.intents[normalizedOperation];
    if (existing != null && existing.payloadHash == payloadHash) {
      return existing;
    }
    if (existing != null && existing.idempotencyKey == normalizedKey) {
      throw StateError(
        'Una Idempotency-Key no puede reutilizarse con otro payload.',
      );
    }
    final intent = MoveOnboardingIntent(
      idempotencyKey: normalizedKey,
      payloadHash: payloadHash,
      createdAt: _now().toUtc(),
    );
    await write(
      userId,
      draft.copyWith(
        intents: Map.unmodifiable({
          ...draft.intents,
          normalizedOperation: intent,
        }),
      ),
    );
    return intent;
  }

  @override
  Future<void> completeIntent(String userId, String operation) async {
    final draft = await read(userId);
    if (draft == null) return;
    final intents = Map<String, MoveOnboardingIntent>.from(draft.intents)
      ..remove(operation.trim().toLowerCase());
    await write(userId, draft.copyWith(intents: Map.unmodifiable(intents)));
  }

  @override
  Future<void> clear(String userId) => _storage.delete(_storageKey(userId));

  String _storageKey(String userId) {
    _requireUser(userId);
    return 'move_onboarding_v2_${sha256Hex(userId.trim())}';
  }

  void _requireUser(String userId) {
    if (userId.trim().isEmpty) throw ArgumentError.value(userId, 'userId');
  }
}

String _canonicalJson(Object? value) {
  Object? sort(Object? item) {
    if (item is Map) {
      final keys = item.keys.map((key) => key.toString()).toList()..sort();
      return <String, Object?>{for (final key in keys) key: sort(item[key])};
    }
    if (item is List) return item.map(sort).toList(growable: false);
    return item;
  }

  return jsonEncode(sort(value));
}
