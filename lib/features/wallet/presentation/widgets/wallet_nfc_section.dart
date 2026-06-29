import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../chat/domain/entities/chat_button.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../domain/entities/wallet_card.dart';
import '../pages/nfc_physical_cards_page.dart';
import '../utils/nfc_navigation.dart';

class WalletNfcSection extends StatefulWidget {
  const WalletNfcSection({this.selectedCard, super.key});

  final WalletCard? selectedCard;

  @override
  State<WalletNfcSection> createState() => _WalletNfcSectionState();
}

class _WalletNfcSectionState extends State<WalletNfcSection> {
  late Future<bool> _nfcEnabled;

  @override
  void initState() {
    super.initState();
    _nfcEnabled = _loadNfcEnabled();
  }

  Future<bool> _loadNfcEnabled() async {
    final result = await getIt<ChatRepository>().buttons();
    return result.when(
      success: (buttons) => buttons.any(_isNfcButtonVisible),
      failure: (_) => false,
    );
  }

  bool _isNfcButtonVisible(ChatButton button) {
    final code = button.code.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();
    return (code == 'nfc' || code == 'paynfc' || code == 'pagonfc') &&
        button.visibility.isVisible;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _nfcEnabled,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ActionChip(
                avatar: const Icon(Icons.nfc, size: 18),
                label: const Text('Pago NFC CIERVO'),
                onPressed: () => openNfcPaySetup(
                  context,
                  walletCardId: widget.selectedCard?.id,
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.credit_card_outlined, size: 18),
                label: const Text('Tarjeta fisica'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NfcPhysicalCardsPage(
                      walletCard: widget.selectedCard,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
