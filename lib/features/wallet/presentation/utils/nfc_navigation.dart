import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../memberships/presentation/pages/membership_page.dart';
import '../pages/nfc_pay_setup_page.dart';

bool isNfcPlusRequiredError(Object error) {
  final message = UserErrorMessage.from(error).toLowerCase();
  return message.contains('plus') && message.contains('nfc');
}

bool isNfcInsufficientBalanceError(Object error) {
  if (error is AppException) {
    final code = error.code?.toUpperCase();
    final message = error.message.toLowerCase();
    return code == 'INSUFFICIENT_BALANCE' ||
        message.contains('insufficient') ||
        message.contains('saldo insuficiente');
  }
  final message = UserErrorMessage.from(error).toLowerCase();
  return message.contains('saldo insuficiente') ||
      message.contains('insufficient');
}

Future<void> handleNfcError(
  BuildContext context,
  Object error, {
  VoidCallback? onRetry,
}) async {
  if (!context.mounted) return;

  if (isNfcPlusRequiredError(error)) {
    final upgrade = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Plan Plus requerido'),
        content: const Text(
          'Pago NFC CIERVO esta disponible en plan Plus o superior. '
          'Actualiza tu membresia para continuar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ver membresias'),
          ),
        ],
      ),
    );
    if (upgrade == true && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MembershipPage()),
      );
    }
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(UserErrorMessage.from(error))),
  );
}

Future<void> openNfcPaySetup(
  BuildContext context, {
  int? businessId,
  String? businessName,
  double? amount,
  String? walletCardId,
  String? description,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => NfcPaySetupPage(
        initialBusinessId: businessId,
        initialBusinessName: businessName,
        initialAmount: amount,
        initialWalletCardId: walletCardId,
        initialDescription: description,
      ),
    ),
  );
}
