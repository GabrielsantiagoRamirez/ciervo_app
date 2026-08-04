enum VakupliPaymentStatus {
  paid,
  pending,
  none;

  static VakupliPaymentStatus fromApi(Object? value) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    return switch (raw) {
      'paid' || 'pagado' || 'completed' => paid,
      'pending' || 'pendiente' || 'pendinginvite' => pending,
      _ => none,
    };
  }

  String get label => switch (this) {
    paid => 'Pagó',
    pending => 'Pendiente',
    none => 'Sin cuota',
  };
}

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
    this.expiresAt,
    this.remainingSeconds,
    this.paidContributions = 0,
    this.totalContributions = 0,
    this.participantCount = 0,
    this.maxParticipants = 4,
    this.maxGuests,
    this.maxTotal,
    this.planGuests,
    this.purchasedExtraGuests,
    this.extraSlotPackSize = 4,
    this.nextPackPriceUsd,
    this.extraSlotsPeriodEndsAt,
    this.extraSlotsPeriodActive = false,
    this.usedSlots,
    this.remainingSlots,
    this.planCode,
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

  /// Fin del plan/chat temporal (UTC del API).
  final DateTime? expiresAt;

  /// Segundos restantes al momento de la respuesta (`0` si venció).
  final int? remainingSeconds;
  final int paidContributions;
  final int totalContributions;
  final int participantCount;
  final int maxParticipants;
  final int? maxGuests;

  /// Cupos del grupo incluyendo creador (`maxGuests + 1`).
  final int? maxTotal;
  final int? planGuests;
  final int? purchasedExtraGuests;
  final int extraSlotPackSize;
  final double? nextPackPriceUsd;
  final DateTime? extraSlotsPeriodEndsAt;
  final bool extraSlotsPeriodActive;
  final int? usedSlots;
  final int? remainingSlots;
  final String? planCode;

  String get paymentProgressLabel => totalContributions > 0
      ? '$paidContributions/$totalContributions pagados'
      : '';

  String get participantsLabel {
    final used = usedSlots ?? participantCount;
    final max = maxTotal ?? maxParticipants;
    return '$used / $max';
  }

  bool get hasCapacity {
    if (remainingSlots != null) return remainingSlots! > 0;
    final max = maxTotal ?? maxParticipants;
    return participantCount < max;
  }

  String get planCapacityHint {
    final code = (planCode ?? 'free').toLowerCase();
    final total = maxTotal ?? maxParticipants;
    final guests = maxGuests ?? (total > 0 ? total - 1 : 3);
    final label = switch (code) {
      'silver' || 'plus' => 'Plus',
      'gold' => 'Gold',
      'black' || 'platinum' => 'Platinum',
      _ => 'Free',
    };
    final extras = purchasedExtraGuests ?? 0;
    final extraHint = extras > 0 ? ' · +$extras extra' : '';
    return 'Plan $label · $total cupos del grupo ($guests invitados)$extraHint';
  }

  String get nextPackPriceLabel {
    final price = nextPackPriceUsd;
    if (price == null) return '';
    final packs = extraSlotPackSize > 0 ? extraSlotPackSize : 4;
    final usd = price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return '+$packs invitados · US\$$usd / 2 meses';
  }

  /// Deadline efectiva del timer: `expiresAt` o captura local desde `remainingSeconds`.
  DateTime? get timerEndsAt {
    if (expiresAt != null) return expiresAt!.toUtc();
    final seconds = remainingSeconds;
    if (seconds != null) {
      return DateTime.now().toUtc().add(Duration(seconds: seconds));
    }
    if (createdAt != null) {
      return createdAt!.toUtc().add(const Duration(hours: 24));
    }
    return null;
  }

  VakupliPlan copyWith({
    List<VakupliFriend>? friends,
    List<VakupliMessage>? messages,
    String? timeLeftLabel,
    String? statusLabel,
    DateTime? expiresAt,
    int? remainingSeconds,
    int? paidContributions,
    int? totalContributions,
    int? participantCount,
    int? maxParticipants,
    int? maxGuests,
    int? maxTotal,
    int? planGuests,
    int? purchasedExtraGuests,
    int? extraSlotPackSize,
    double? nextPackPriceUsd,
    DateTime? extraSlotsPeriodEndsAt,
    bool? extraSlotsPeriodActive,
    int? usedSlots,
    int? remainingSlots,
    String? planCode,
  }) => VakupliPlan(
    id: id,
    title: title,
    timeLeftLabel: timeLeftLabel ?? this.timeLeftLabel,
    statusLabel: statusLabel ?? this.statusLabel,
    totalAmount: totalAmount,
    selfDestructLabel: selfDestructLabel,
    friends: friends ?? this.friends,
    messages: messages ?? this.messages,
    chatId: chatId,
    code: code,
    shareUrl: shareUrl,
    deepLink: deepLink,
    createdAt: createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    paidContributions: paidContributions ?? this.paidContributions,
    totalContributions: totalContributions ?? this.totalContributions,
    participantCount: participantCount ?? this.participantCount,
    maxParticipants: maxParticipants ?? this.maxParticipants,
    maxGuests: maxGuests ?? this.maxGuests,
    maxTotal: maxTotal ?? this.maxTotal,
    planGuests: planGuests ?? this.planGuests,
    purchasedExtraGuests: purchasedExtraGuests ?? this.purchasedExtraGuests,
    extraSlotPackSize: extraSlotPackSize ?? this.extraSlotPackSize,
    nextPackPriceUsd: nextPackPriceUsd ?? this.nextPackPriceUsd,
    extraSlotsPeriodEndsAt:
        extraSlotsPeriodEndsAt ?? this.extraSlotsPeriodEndsAt,
    extraSlotsPeriodActive:
        extraSlotsPeriodActive ?? this.extraSlotsPeriodActive,
    usedSlots: usedSlots ?? this.usedSlots,
    remainingSlots: remainingSlots ?? this.remainingSlots,
    planCode: planCode ?? this.planCode,
  );
}

class VakupliExtraSlotsMe {
  const VakupliExtraSlotsMe({
    required this.isActive,
    required this.extraGuests,
    required this.packs,
    required this.billingPeriodMonths,
    required this.nextRenewalPriceUsd,
    required this.nextPackPriceUsd,
    required this.planCode,
    required this.planUpgradePreservesDays,
    required this.acknowledgeBeforePlanUpgrade,
    required this.upgradeModal,
    this.periodStartsAt,
    this.periodEndsAt,
  });

  factory VakupliExtraSlotsMe.fromJson(Map<String, dynamic> json) {
    final modalRaw = json['upgradeModal'];
    final modalMap = modalRaw is Map
        ? Map<String, dynamic>.from(modalRaw)
        : <String, dynamic>{};
    return VakupliExtraSlotsMe(
      isActive: json['isActive'] == true,
      extraGuests: _int(json['extraGuests']),
      packs: _int(json['packs']),
      periodStartsAt: DateTime.tryParse('${json['periodStartsAt'] ?? ''}'),
      periodEndsAt: DateTime.tryParse('${json['periodEndsAt'] ?? ''}'),
      billingPeriodMonths: _int(json['billingPeriodMonths']) > 0
          ? _int(json['billingPeriodMonths'])
          : 2,
      nextRenewalPriceUsd: _double(json['nextRenewalPriceUsd']),
      nextPackPriceUsd: _double(json['nextPackPriceUsd']),
      planCode: _nullable(json['planCode']) ?? 'free',
      planUpgradePreservesDays: json['planUpgradePreservesDays'] != false,
      acknowledgeBeforePlanUpgrade:
          json['acknowledgeBeforePlanUpgrade'] == true,
      upgradeModal: VakupliExtraSlotsUpgradeModal.fromJson(modalMap),
    );
  }

  final bool isActive;
  final int extraGuests;
  final int packs;
  final DateTime? periodStartsAt;
  final DateTime? periodEndsAt;
  final int billingPeriodMonths;
  final double nextRenewalPriceUsd;
  final double nextPackPriceUsd;
  final String planCode;
  final bool planUpgradePreservesDays;
  final bool acknowledgeBeforePlanUpgrade;
  final VakupliExtraSlotsUpgradeModal upgradeModal;
}

class VakupliExtraSlotsUpgradeModal {
  const VakupliExtraSlotsUpgradeModal({
    required this.title,
    required this.body,
    required this.continueUpgradeLabel,
    required this.cancelLabel,
  });

  factory VakupliExtraSlotsUpgradeModal.fromJson(Map<String, dynamic> json) {
    String brand(String? raw, String fallback) {
      final text = (raw ?? '').trim();
      if (text.isEmpty) return fallback;
      return text.replaceAll('Vakupli', 'Vaku').replaceAll('vakupli', 'Vaku');
    }

    return VakupliExtraSlotsUpgradeModal(
      title: brand(json['title']?.toString(), 'Cupos extra Vaku'),
      body: brand(
        json['body']?.toString(),
        'Los cupos extra se cobran cada 2 meses. Si mejoras tu plan ahora, '
        'no pierdes los días que te quedan de este periodo y no se vuelve a '
        'cobrar el pack hasta que venza.',
      ),
      continueUpgradeLabel: brand(
        json['continueUpgradeLabel']?.toString(),
        'Entendido, mejorar plan',
      ),
      cancelLabel: brand(
        json['cancelLabel']?.toString(),
        'Seguir con mi plan actual',
      ),
    );
  }

  final String title;
  final String body;
  final String continueUpgradeLabel;
  final String cancelLabel;
}

class VakupliExtraSlotsPurchase {
  const VakupliExtraSlotsPurchase({
    required this.groupId,
    required this.packsPurchased,
    required this.guestsAdded,
    required this.purchasedExtraGuests,
    required this.maxGuests,
    required this.remainingSlots,
    required this.amountCharged,
    required this.currency,
    required this.priceUsd,
    required this.billingPeriodMonths,
    required this.periodPreservedOnPlanUpgrade,
    this.periodStartsAt,
    this.periodEndsAt,
    this.paymentIntentId,
    this.walletTransactionId,
  });

  factory VakupliExtraSlotsPurchase.fromJson(Map<String, dynamic> json) {
    return VakupliExtraSlotsPurchase(
      groupId: _int(json['groupId']),
      packsPurchased: _int(json['packsPurchased'] ?? json['packs']),
      guestsAdded: _int(json['guestsAdded']),
      purchasedExtraGuests: _int(json['purchasedExtraGuests']),
      maxGuests: _int(json['maxGuests']),
      remainingSlots: _int(json['remainingSlots']),
      amountCharged: _double(json['amountCharged']),
      currency: _nullable(json['currency']) ?? 'USD',
      priceUsd: _double(json['priceUsd']),
      periodStartsAt: DateTime.tryParse('${json['periodStartsAt'] ?? ''}'),
      periodEndsAt: DateTime.tryParse('${json['periodEndsAt'] ?? ''}'),
      billingPeriodMonths: _int(json['billingPeriodMonths']) > 0
          ? _int(json['billingPeriodMonths'])
          : 2,
      periodPreservedOnPlanUpgrade:
          json['periodPreservedOnPlanUpgrade'] != false,
      paymentIntentId: _intOrNull(json['paymentIntentId']),
      walletTransactionId: _intOrNull(json['walletTransactionId']),
    );
  }

  final int groupId;
  final int packsPurchased;
  final int guestsAdded;
  final int purchasedExtraGuests;
  final int maxGuests;
  final int remainingSlots;
  final double amountCharged;
  final String currency;
  final double priceUsd;
  final DateTime? periodStartsAt;
  final DateTime? periodEndsAt;
  final int billingPeriodMonths;
  final bool periodPreservedOnPlanUpgrade;
  final int? paymentIntentId;
  final int? walletTransactionId;
}

class VakupliFriend {
  const VakupliFriend({
    required this.name,
    required this.initials,
    this.userId,
    this.username,
    this.photoUrl,
    this.countryCode,
    this.paymentStatus = VakupliPaymentStatus.none,
    this.hasPaid = false,
    this.amount,
    this.currency = 'COP',
    this.contributionId,
  });

  final String name;
  final String initials;
  final int? userId;
  final String? username;
  final String? photoUrl;
  final String? countryCode;
  final VakupliPaymentStatus paymentStatus;
  final bool hasPaid;
  final double? amount;
  final String currency;
  final int? contributionId;

  String get paymentLabel {
    if (hasPaid || paymentStatus == VakupliPaymentStatus.paid) return 'Pagó';
    return paymentStatus.label;
  }
}

class VakupliContact {
  const VakupliContact({
    required this.userId,
    required this.displayName,
    this.ciervoUserCode,
    this.username,
    this.photoUrl,
    this.countryCode,
    this.isFavorite = false,
  });

  factory VakupliContact.fromJson(Map<String, dynamic> json) {
    final display =
        '${json['displayName'] ?? json['name'] ?? json['username'] ?? 'Usuario'}'
            .trim();
    return VakupliContact(
      userId: _int(json['userId'] ?? json['id']),
      displayName: display.isEmpty ? 'Usuario' : display,
      ciervoUserCode: _nullable(
        json['ciervoUserCode'] ?? json['ciervoId'] ?? json['code'],
      ),
      username: _nullable(json['username']),
      photoUrl: _nullable(json['photoUrl'] ?? json['avatarUrl']),
      countryCode: _nullable(json['countryCode']),
      isFavorite: json['isFavorite'] == true,
    );
  }

  final int userId;
  final String displayName;
  final String? ciervoUserCode;
  final String? username;
  final String? photoUrl;
  final String? countryCode;
  final bool isFavorite;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get subtitle {
    final parts = <String>[
      if (username != null && username!.trim().isNotEmpty)
        username!.startsWith('@') ? username! : '@$username',
      if (ciervoUserCode != null && ciervoUserCode!.trim().isNotEmpty)
        ciervoUserCode!,
      if (countryCode != null && countryCode!.trim().isNotEmpty) countryCode!,
    ];
    return parts.join(' · ');
  }
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

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _intOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _double(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String? _nullable(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}
