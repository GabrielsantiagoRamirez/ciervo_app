class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.title,
    required this.type,
    required this.unreadCount,
    required this.status,
    this.businessId,
    this.businessName,
    this.businessLogoUrl,
    this.avatarUrl,
    this.peerUserId,
    this.peerUsername,
    this.peerDisplayName,
    this.peerPhotoUrl,
    this.participantCount,
    this.lastMessage,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String type;
  final int unreadCount;
  final String status;
  final int? businessId;
  final String? businessName;

  /// Logo del negocio (`businessLogoUrl` / `logoUrl`).
  final String? businessLogoUrl;

  /// URL ya resuelta por el backend para el círculo del inbox.
  final String? avatarUrl;
  final int? peerUserId;
  final String? peerUsername;
  final String? peerDisplayName;

  /// Foto de perfil del otro usuario (directo o cliente visto por negocio).
  final String? peerPhotoUrl;
  final int? participantCount;
  final String? lastMessage;
  final DateTime? updatedAt;

  bool get canSend => status.toLowerCase() == 'open';
  bool get isDirect => type.toLowerCase().contains('direct');
  bool get isBusiness =>
      type.toLowerCase().contains('business') || businessId != null;

  /// Imagen del círculo en la lista de chats.
  ///
  /// Preferencia: `avatarUrl` (backend ya elige la correcta) y fallback
  /// según el tipo de conversación.
  String? get circleImageUrl {
    final resolved = _nonEmpty(avatarUrl);
    if (resolved != null) return resolved;

    if (isDirect) {
      return _nonEmpty(peerPhotoUrl);
    }

    if (isBusiness) {
      // Cliente ↔ negocio: logo; panel negocio viendo cliente: foto del peer.
      return _nonEmpty(businessLogoUrl) ?? _nonEmpty(peerPhotoUrl);
    }

    return _nonEmpty(peerPhotoUrl) ?? _nonEmpty(businessLogoUrl);
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
