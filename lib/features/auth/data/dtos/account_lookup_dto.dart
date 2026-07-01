class AccountLookupResult {
  const AccountLookupResult({
    required this.exists,
    this.authProvider,
    required this.suggestedFlow,
  });

  factory AccountLookupResult.fromJson(Map<String, dynamic> json) {
    return AccountLookupResult(
      exists: json['exists'] == true,
      authProvider: json['authProvider']?.toString(),
      suggestedFlow: json['suggestedFlow']?.toString() ?? 'register',
    );
  }

  final bool exists;
  final String? authProvider;
  final String suggestedFlow;

  bool get isLegacyLogin => suggestedFlow == 'legacy_password';
  bool get isFirebaseLogin => suggestedFlow == 'firebase_password';
  bool get isRegister => !exists || suggestedFlow == 'register';
}
