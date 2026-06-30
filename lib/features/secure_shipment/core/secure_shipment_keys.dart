/// Genera claves idempotentes para operaciones de envío seguro.
abstract final class SecureShipmentKeys {
  static String create() => 'ss-create-${DateTime.now().microsecondsSinceEpoch}';

  static String hold() => 'ss-hold-${DateTime.now().microsecondsSinceEpoch}';

  static String sync() => 'ss-sync-${DateTime.now().microsecondsSinceEpoch}';

  static String pay() => 'ss-pay-${DateTime.now().microsecondsSinceEpoch}';
}
