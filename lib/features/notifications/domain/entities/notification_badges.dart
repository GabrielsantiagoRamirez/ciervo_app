class NotificationBadges {
  const NotificationBadges({
    this.total = 0,
    this.wallet = 0,
    this.chat = 0,
    this.delivery = 0,
    this.reservations = 0,
    this.promos = 0,
  });

  final int total;
  final int wallet;
  final int chat;
  final int delivery;
  final int reservations;
  final int promos;

  factory NotificationBadges.fromJson(Map<String, dynamic> json) {
    int count(dynamic value) =>
        value is int ? value : int.tryParse('$value') ?? 0;
    return NotificationBadges(
      total: count(json['total'] ?? json['unreadTotal'] ?? json['count']),
      wallet: count(json['wallet']),
      chat: count(json['chat'] ?? json['messages']),
      delivery: count(json['delivery']),
      reservations: count(json['reservas'] ?? json['reservations']),
      promos: count(json['promos'] ?? json['promociones'] ?? json['promotions']),
    );
  }
}
