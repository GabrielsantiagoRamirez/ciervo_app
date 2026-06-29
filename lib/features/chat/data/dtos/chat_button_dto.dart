import '../../domain/entities/chat_button.dart';

class ChatButtonDto {
  const ChatButtonDto({
    required this.code,
    required this.label,
    required this.visibility,
    this.message,
    this.icon,
    this.sortOrder = 0,
  });

  final String code;
  final String label;
  final ChatButtonVisibility visibility;
  final String? message;
  final String? icon;
  final int sortOrder;

  factory ChatButtonDto.fromJson(Map<String, dynamic> json) {
    return ChatButtonDto(
      code: _string(json, const ['code', 'buttonCode', 'id']),
      label: _string(json, const ['label', 'title', 'name']),
      visibility: ChatButtonVisibility.parse(
        _string(json, const ['visibility', 'status', 'state']),
      ),
      message: _optional(json, const ['message', 'disabledMessage', 'reason']),
      icon: _optional(json, const ['icon', 'iconName']),
      sortOrder: _int(json['sortOrder'] ?? json['order']),
    );
  }

  ChatButton toDomain() => ChatButton(
    code: code,
    label: label.isEmpty ? code : label,
    visibility: visibility,
    message: message,
    icon: icon,
    sortOrder: sortOrder,
  );

  static List<ChatButtonDto> listFrom(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(ChatButtonDto.fromJson)
          .toList();
    }
    if (value is Map<String, dynamic>) {
      final items = value['items'] ?? value['buttons'] ?? value['value'];
      if (items is List) return listFrom(items);
      return value.entries
          .where((e) => e.value is Map<String, dynamic>)
          .map((e) {
            final map = Map<String, dynamic>.from(e.value as Map);
            map.putIfAbsent('code', () => e.key);
            return ChatButtonDto.fromJson(map);
          })
          .toList();
    }
    return const [];
  }

  static String _string(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  static String? _optional(Map<String, dynamic> json, List<String> keys) {
    final text = _string(json, keys);
    return text.isEmpty ? null : text;
  }

  static int _int(dynamic value) =>
      value is int ? value : int.tryParse('$value') ?? 0;
}
