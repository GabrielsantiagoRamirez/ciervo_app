class CiervoWalletIdentity {
  const CiervoWalletIdentity({
    required this.userId,
    required this.ciervoUserCode,
    this.qrPayload,
  });

  final String userId;
  final String ciervoUserCode;
  final String? qrPayload;
}
