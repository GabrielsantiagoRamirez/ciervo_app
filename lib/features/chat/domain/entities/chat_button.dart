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
      'pilot' => ChatButtonVisibility.disabledWithMessage,
      _ => ChatButtonVisibility.unknown,
    };
  }

  bool get isEnabled => this == ChatButtonVisibility.productionReady;

  bool get isVisible =>
      this == ChatButtonVisibility.productionReady ||
      this == ChatButtonVisibility.disabledWithMessage;
}

class ChatButton {
  const ChatButton({
    required this.code,
    required this.label,
    required this.visibility,
    this.message,
    this.icon,
    this.sortOrder = 0,
    this.showOnMobile = true,
  });

  final String code;
  final String label;
  final ChatButtonVisibility visibility;
  final String? message;
  final String? icon;
  final int sortOrder;
  final bool showOnMobile;

  bool get isVisibleOnMobile =>
      showOnMobile &&
      visibility != ChatButtonVisibility.notIncludedInMvp &&
      visibility != ChatButtonVisibility.requiresProvider &&
      visibility != ChatButtonVisibility.hiddenForMvp &&
      (visibility == ChatButtonVisibility.productionReady ||
          visibility == ChatButtonVisibility.disabledWithMessage ||
          visibility == ChatButtonVisibility.unknown);
}

extension ChatButtonListX on List<ChatButton> {
  List<ChatButton> visibleOnMobile() => where((b) => b.isVisibleOnMobile).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}
