class VakupliPlan {
  const VakupliPlan({
    required this.title,
    required this.timeLeftLabel,
    required this.statusLabel,
    required this.totalAmount,
    required this.selfDestructLabel,
    required this.friends,
    required this.messages,
  });

  final String title;
  final String timeLeftLabel;
  final String statusLabel;
  final double totalAmount;
  final String selfDestructLabel;
  final List<VakupliFriend> friends;
  final List<VakupliMessage> messages;
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
  });

  final String senderName;
  final String text;
  final String timeLabel;
  final bool isCurrentUser;
}

enum VakupliSplitOption { equal, custom }
