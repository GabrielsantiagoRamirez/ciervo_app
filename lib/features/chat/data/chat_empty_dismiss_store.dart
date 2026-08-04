import '../../../core/storage/secure_storage.dart';

/// Oculta localmente chats vacíos que el usuario eliminó del inbox.
class ChatEmptyDismissStore {
  ChatEmptyDismissStore(this._storage);

  final SecureStorage _storage;
  static const _key = 'chat_inbox_dismissed_empty_ids';

  Future<Set<String>> load() async {
    final raw = await _storage.read(_key);
    if (raw == null || raw.trim().isEmpty) return {};
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  Future<void> dismiss(String conversationId) async {
    final id = conversationId.trim();
    if (id.isEmpty) return;
    final ids = await load()..add(id);
    await _storage.write(_key, ids.join(','));
  }

  Future<void> dismissMany(Iterable<String> conversationIds) async {
    final ids = await load();
    for (final id in conversationIds) {
      final trimmed = id.trim();
      if (trimmed.isNotEmpty) ids.add(trimmed);
    }
    await _storage.write(_key, ids.join(','));
  }

  Future<void> clear() => _storage.delete(_key);
}
