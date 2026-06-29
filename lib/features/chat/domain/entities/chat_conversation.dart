class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.title,
    required this.type,
    required this.unreadCount,
    required this.status,
    this.businessId,
    this.lastMessage,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String type;
  final int unreadCount;
  final String status;
  final int? businessId;
  final String? lastMessage;
  final DateTime? updatedAt;

  bool get canSend => status == 'Open';
}
