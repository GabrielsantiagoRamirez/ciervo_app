enum ChatButtonVisibility {
  productionReady,
  hiddenForMvp,
  disabledWithMessage,
  requiresProvider,
  notIncludedInMvp,
  unknown;

  static ChatButtonVisibility parse(String? raw) {
    final normalized = (raw ?? '').replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();
    return switch (normalized) {
      'productionready' => ChatButtonVisibility.productionReady,
      'hiddenformvp' => ChatButtonVisibility.hiddenForMvp,
      'disabledwithmessage' => ChatButtonVisibility.disabledWithMessage,
      'requiresprovider' => ChatButtonVisibility.requiresProvider,
      'notincludedinmvp' => ChatButtonVisibility.notIncludedInMvp,
      _ => ChatButtonVisibility.unknown,
    };
  }

  bool get isVisible =>
      this == ChatButtonVisibility.productionReady ||
      this == ChatButtonVisibility.disabledWithMessage;

  bool get isEnabled => this == ChatButtonVisibility.productionReady;
}

class ChatButton {
  const ChatButton({
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
}
