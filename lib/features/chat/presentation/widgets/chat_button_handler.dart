import 'package:flutter/material.dart';

import '../../../memberships/presentation/pages/membership_page.dart';
import '../../../transport/presentation/pages/transport_page.dart';
import '../../../chat_payments/presentation/pages/chat_gift_page.dart';
import '../../../wallet/presentation/pages/payment_requests_page.dart';
import '../../../wallet/presentation/pages/recharge_by_ciervo_id_page.dart';
import '../../../wallet/presentation/pages/request_money_page.dart';
import '../../../wallet/presentation/pages/transfer_page.dart';
import '../../../wallet/presentation/pages/wallet_page.dart';
import '../../../wallet/presentation/utils/nfc_navigation.dart';
import '../../domain/entities/chat_button.dart';

IconData iconForChatButton(String code) {
  final normalized = code.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();
  return switch (normalized) {
    'pay' || 'pagar' => Icons.send_outlined,
    'sendgift' || 'gift' || 'enviarregalo' => Icons.card_giftcard_outlined,
    'payforme' || 'pagapormi' => Icons.request_page_outlined,
    'requestapproval' ||
    'solicitaraprobacion' ||
    'approval' =>
      Icons.verified_user_outlined,
    'rechargeaccount' ||
    'recargarcuenta' ||
    'recharge' ||
    'recargar' =>
      Icons.add_card_outlined,
    'memberships' || 'membresias' || 'membership' =>
      Icons.workspace_premium_outlined,
    'trips' || 'viajes' => Icons.flight_outlined,
    'transport' || 'transporte' => Icons.directions_bus_outlined,
    'nfc' || 'paynfc' || 'pagonfc' => Icons.nfc,
    _ => Icons.touch_app_outlined,
  };
}

Future<void> handleChatButtonTap(
  BuildContext context, {
  required ChatButton button,
  required String conversationId,
  int? businessId,
  String? businessName,
}) async {
  if (!button.visibility.isEnabled) {
    final message = button.message?.trim();
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
    return;
  }

  final code = button.code.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();
  switch (code) {
    case 'pay':
    case 'pagar':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const TransferPage()),
      );
      return;
    case 'sendgift':
    case 'gift':
    case 'enviarregalo':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatGiftPage(conversationId: conversationId),
        ),
      );
      return;
    case 'payforme':
    case 'pagapormi':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const RequestMoneyPage()),
      );
      return;
    case 'requestapproval':
    case 'solicitaraprobacion':
    case 'approval':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PaymentRequestsPage()),
      );
      return;
    case 'rechargeaccount':
    case 'recargarcuenta':
    case 'recharge':
    case 'recargar':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const RechargeByCiervoIdPage()),
      );
      return;
    case 'memberships':
    case 'membresias':
    case 'membership':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MembershipPage()),
      );
      return;
    case 'trips':
    case 'viajes':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const TransportPage()),
      );
      return;
    case 'transport':
    case 'transporte':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const TransportPage()),
      );
      return;
    case 'wallet':
    case 'miwallet':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const WalletPage()),
      );
      return;
    case 'nfc':
    case 'paynfc':
    case 'pagonfc':
      await openNfcPaySetup(
        context,
        businessId: businessId,
        businessName: businessName,
      );
      return;
    default:
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Accion ${button.label} no disponible aun.')),
      );
  }
}

Future<void> showChatButtonsSheet(
  BuildContext context, {
  required List<ChatButton> buttons,
  required String conversationId,
  int? businessId,
  String? businessName,
}) async {
  final visible = buttons.where((b) => b.visibility.isVisible).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  if (visible.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No hay acciones disponibles en este chat.')),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        children: [
          for (final button in visible)
            ListTile(
              leading: Icon(iconForChatButton(button.code)),
              title: Text(button.label),
              subtitle: !button.visibility.isEnabled && button.message != null
                  ? Text(button.message!)
                  : null,
              onTap: () async {
                Navigator.pop(sheetContext);
                await handleChatButtonTap(
                  context,
                  button: button,
                  conversationId: conversationId,
                  businessId: businessId,
                  businessName: businessName,
                );
              },
            ),
        ],
      ),
    ),
  );
}
