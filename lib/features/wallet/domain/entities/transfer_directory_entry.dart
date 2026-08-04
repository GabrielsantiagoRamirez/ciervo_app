class TransferDirectoryEntry {
  const TransferDirectoryEntry({
    required this.userId,
    required this.displayName,
    this.ciervoUserCode,
    this.username,
    this.photoUrl,
    this.countryCode,
    this.localCurrency,
    this.isVerified = false,
    this.isBusiness = false,
    this.isFavorite = false,
    this.lastTransferAt,
    this.lastTransferLabel,
  });

  final String userId;
  final String displayName;
  final String? ciervoUserCode;
  final String? username;
  final String? photoUrl;
  final String? countryCode;
  final String? localCurrency;
  final bool isVerified;
  final bool isBusiness;
  final bool isFavorite;
  final DateTime? lastTransferAt;
  final String? lastTransferLabel;

  /// Preferencia de lookup para resolve / transfer.
  String get lookup {
    final code = ciervoUserCode?.trim();
    if (code != null && code.isNotEmpty) return code;
    final user = username?.trim();
    if (user != null && user.isNotEmpty) {
      return user.startsWith('@') ? user : '@$user';
    }
    return userId;
  }

  String get subtitle {
    final parts = <String>[
      if (username != null && username!.trim().isNotEmpty)
        username!.startsWith('@') ? username! : '@${username!}',
      if (ciervoUserCode != null && ciervoUserCode!.trim().isNotEmpty)
        ciervoUserCode!,
      if (countryCode != null && countryCode!.trim().isNotEmpty) countryCode!,
    ];
    return parts.join(' · ');
  }
}
