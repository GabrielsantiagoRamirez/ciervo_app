import '../models/safety_models.dart';

class SafetyFilterCache {
  final Set<int> _blockedUserIds = <int>{};
  final Set<String> _blockedContentKeys = <String>{};

  Set<int> get blockedUserIds => Set.unmodifiable(_blockedUserIds);
  Set<String> get blockedContentKeys => Set.unmodifiable(_blockedContentKeys);

  bool isUserBlocked(String userId) =>
      int.tryParse(userId) != null &&
      _blockedUserIds.contains(int.parse(userId));

  bool isUserBlockedInt(int userId) => _blockedUserIds.contains(userId);

  bool isContentBlocked(ReportTargetType type, String targetId) =>
      _blockedContentKeys.contains('${type.apiValue}:$targetId');

  bool isContentBlockedKey(String key) => _blockedContentKeys.contains(key);

  void addBlockedUser(int userId) => _blockedUserIds.add(userId);

  void removeBlockedUser(int userId) => _blockedUserIds.remove(userId);

  void addContentBlock(ContentBlockModel block) =>
      _blockedContentKeys.add(block.key);

  void removeContentBlock(ReportTargetType type, String targetId) =>
      _blockedContentKeys.remove('${type.apiValue}:$targetId');

  void replaceAll({
    required Set<int> blockedUserIds,
    required List<ContentBlockModel> contentBlocks,
  }) {
    _blockedUserIds
      ..clear()
      ..addAll(blockedUserIds);
    _blockedContentKeys
      ..clear()
      ..addAll(contentBlocks.map((e) => e.key));
  }

  /// Vacía el cache de bloqueos para evitar arrastrar datos entre cuentas.
  void clear() {
    _blockedUserIds.clear();
    _blockedContentKeys.clear();
  }
}
