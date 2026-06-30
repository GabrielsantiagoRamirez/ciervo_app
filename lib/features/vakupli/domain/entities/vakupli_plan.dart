class VakupliPlan {
  const VakupliPlan({
    this.id,
    required this.title,
    required this.timeLeftLabel,
    required this.statusLabel,
    required this.totalAmount,
    required this.selfDestructLabel,
    required this.friends,
    required this.messages,
    this.chatId,
    this.code,
    this.shareUrl,
    this.deepLink,
    this.createdAt,
    this.paidContributions = 0,
    this.totalContributions = 0,
  });

  final int? id;
  final String title;
  final String timeLeftLabel;
  final String statusLabel;
  final double totalAmount;
  final String selfDestructLabel;
  final List<VakupliFriend> friends;
  final List<VakupliMessage> messages;
  final int? chatId;
  final String? code;
  final String? shareUrl;
  final String? deepLink;
  final DateTime? createdAt;
  final int paidContributions;
  final int totalContributions;

  String get paymentProgressLabel =>
      totalContributions > 0
          ? '$paidContributions/$totalContributions pagados'
          : statusLabel;
}

class VakupliFriend {
  const VakupliFriend({
    required this.name,
    required this.initials,
  });

  final String name;
  final String initials;
}

class VakupliMessage {
  const VakupliMessage({
    required this.senderName,
    required this.text,
    required this.timeLabel,
    required this.isCurrentUser,
    this.id,
  });

  final String senderName;
  final String text;
  final String timeLabel;
  final bool isCurrentUser;
  final int? id;
}

enum VakupliSplitOption { equal, custom }

class VakupliGroupsPage {
  const VakupliGroupsPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  final List<VakupliPlan> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
}
