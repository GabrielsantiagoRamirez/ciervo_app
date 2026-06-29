class StaffPermissions {
  const StaffPermissions({
    required this.permissions,
    required this.canUseMobileScanner,
    this.businessId,
    this.businessName,
    this.staffId,
    this.staffName,
    this.roleName,
  });

  final int? businessId;
  final String? businessName;
  final int? staffId;
  final String? staffName;
  final String? roleName;
  final List<String> permissions;
  final bool canUseMobileScanner;

  bool get isStaff =>
      staffId != null ||
      roleName?.toLowerCase().contains('staff') == true ||
      permissions.isNotEmpty;

  bool get canScan =>
      canUseMobileScanner &&
      permissions.any((item) => item == 'qr.scan' || item == 'qr.validate');

  bool get canRedeem =>
      permissions.any(
        (item) => item == 'qr.redeem' || item.endsWith('.redeem'),
      );

  bool get canViewOrders => permissions.any(
    (item) =>
        item == 'orders.view' ||
        item == 'delivery.view' ||
        item == 'products.view',
  );

  bool get canManageOrders => permissions.any(
    (item) =>
        item == 'orders.manage' ||
        item == 'delivery.manage' ||
        item == 'products.edit',
  );
}

class StaffQrValidation {
  const StaffQrValidation({
    required this.valid,
    required this.canRedeem,
    required this.requiresConfirmation,
    this.qrId,
    this.type,
    this.status,
    this.title,
    this.ownerName,
    this.message,
  });

  final bool valid;
  final bool canRedeem;
  final bool requiresConfirmation;
  final String? qrId;
  final String? type;
  final String? status;
  final String? title;
  final String? ownerName;
  final String? message;
}

class StaffQrRedeemResult {
  const StaffQrRedeemResult({
    required this.redeemed,
    this.status,
    this.redeemedAt,
    this.redeemedBy,
    this.message,
  });

  final bool redeemed;
  final String? status;
  final DateTime? redeemedAt;
  final String? redeemedBy;
  final String? message;
}

class StaffQrScanAudit {
  const StaffQrScanAudit({
    required this.id,
    required this.result,
    this.qrType,
    this.resourceTitle,
    this.ownerName,
    this.failureReason,
    this.scannedAt,
  });

  final String id;
  final String result;
  final String? qrType;
  final String? resourceTitle;
  final String? ownerName;
  final String? failureReason;
  final DateTime? scannedAt;
}
