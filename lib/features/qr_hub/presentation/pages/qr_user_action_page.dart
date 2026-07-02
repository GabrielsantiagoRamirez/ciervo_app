import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../../chat_payments/presentation/pages/chat_gift_page.dart';
import '../../../chat_payments/presentation/pages/chat_pay_page.dart';
import '../../../wallet/presentation/pages/transfer_page.dart';

class QrUserActionPage extends StatelessWidget {
  const QrUserActionPage({
    required this.ciervoUserCode,
    required this.displayName,
    required this.userId,
    this.chatConversationId,
    super.key,
  });

  final String ciervoUserCode;
  final String displayName;
  final String userId;
  final String? chatConversationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuario detectado')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: CiervoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(displayName),
                subtitle: Text(ciervoUserCode),
              ),
              const SizedBox(height: AppSpacing.lg),
              CiervoButton(
                label: 'Pagar',
                icon: Icons.payments_outlined,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatPayPage(
                      chatConversationId: chatConversationId,
                      initialTargetCiervoCode: ciervoUserCode,
                      initialTargetUserId: userId,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              CiervoButton(
                label: 'Enviar regalo',
                icon: Icons.card_giftcard_outlined,
                variant: CiervoButtonVariant.secondary,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChatGiftPage(
                      conversationId: chatConversationId,
                      initialTargetCiervoCode: ciervoUserCode,
                      initialTargetUserId: userId,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              CiervoButton(
                label: 'Transferir',
                icon: Icons.swap_horiz,
                variant: CiervoButtonVariant.secondary,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TransferPage(
                      initialCiervoCode: ciervoUserCode,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
