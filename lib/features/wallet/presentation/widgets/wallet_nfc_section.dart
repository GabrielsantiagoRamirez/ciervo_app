import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../chat/domain/entities/chat_button.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../universal_nfc/presentation/pages/kids_nfc_parent_approvals_page.dart';
import '../../../universal_nfc/presentation/pages/universal_nfc_pay_page.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.primary : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: FutureBuilder<bool>(
        future: _nfcEnabled,
        builder: (context, snapshot) {
          final legacyNfc = snapshot.data == true;
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ActionChip(
                avatar: Icon(Icons.contactless_outlined, size: 18, color: accent),
                label: const Text('NFC Universal'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const UniversalNfcPayPage(),
                  ),
                ),
              ),
              ActionChip(
                avatar: Icon(Icons.family_restroom_outlined, size: 18, color: accent),
                label: const Text('Aprobaciones Kids'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const KidsNfcParentApprovalsPage(),
                  ),
                ),
              ),
              if (legacyNfc) ...[
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
            ],
          );
        },
      ),
    );
  }
}
