class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.title,
    required this.type,
    required this.unreadCount,
    required this.status,
    this.businessId,
    this.peerUserId,
    this.peerUsername,
    this.peerDisplayName,
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
  final int? peerUserId;
  final String? peerUsername;
  final String? peerDisplayName;
  final int? participantCount;
  final String? lastMessage;
  final DateTime? updatedAt;

  bool get canSend => status.toLowerCase() == 'open';
  bool get isDirect => type.toLowerCase().contains('direct');
}
