class ResolvedWalletUser {
  const ResolvedWalletUser({
    required this.userId,
    required this.ciervoUserCode,
    required this.displayName,
    this.username,
    this.photoUrl,
    this.countryCode,
    this.localCurrency,
    this.isVerified = false,
    this.isBusiness = false,
    this.isFavorite = false,
  });

  final String userId;
  final String ciervoUserCode;
  final String displayName;
  final String? username;
  final String? photoUrl;
  final String? countryCode;
  final String? localCurrency;
  final bool isVerified;
  final bool isBusiness;
  final bool isFavorite;

  String get handle {
    final user = username?.trim();
    if (user == null || user.isEmpty) return ciervoUserCode;
    return user.startsWith('@') ? user : '@$user';
  }
}
