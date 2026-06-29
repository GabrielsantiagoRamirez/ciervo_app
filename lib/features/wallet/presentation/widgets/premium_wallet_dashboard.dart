import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../financial_history/presentation/pages/financial_history_page.dart';
import '../../../notifications/domain/entities/notification_badges.dart';
import '../../../notifications/presentation/cubit/notification_badges_cubit.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../pins/presentation/pages/pins_page.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/entities/wallet_card.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';
import '../utils/nfc_navigation.dart';
import 'ciervo_digital_card.dart';
import '../../../bonuses/presentation/widgets/wallet_available_bonuses_section.dart';
import 'wallet_nfc_section.dart';
import '../pages/recharge_page.dart';
import '../pages/transfer_page.dart';

class PremiumWalletDashboard extends StatefulWidget {
  const PremiumWalletDashboard({required this.state, super.key});

  final WalletState state;

  @override
  State<PremiumWalletDashboard> createState() => _PremiumWalletDashboardState();
}

class _PremiumWalletDashboardState extends State<PremiumWalletDashboard> {
  String? _displayAlias;
  String _userName = 'Usuario';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final result = await getIt<ProfileRepository>().getMe();
    if (!mounted) return;
    result.when(
      success: (profile) => setState(() {
        _userName = profile.firstName.isNotEmpty
            ? profile.firstName
            : profile.fullName.split(' ').first;
      }),
      failure: (_) {},
    );
  }

  WalletCard? get _card =>
      widget.state.selectedCard ??
      widget.state.cards.where((c) => c.isPrimary).firstOrNull ??
      widget.state.cards.firstOrNull;

  @override
  Widget build(BuildContext context) {
    final card = _card;
    final balance = card?.availableBalance ?? 0;
    final currency = card?.currency ?? 'COP';
    final recent = widget.state.transactions.take(3).toList();

    return ColoredBox(
      color: CiervoBrandColors.background,
      child: SafeArea(
        child: RefreshIndicator(
          color: CiervoBrandColors.gold,
          onRefresh: context.read<WalletCubit>().load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              _Header(userName: _userName),
              const SizedBox(height: AppSpacing.lg),
              if (card != null)
                CiervoDigitalCard(
                  holderName: _userName,
                  alias: _displayAlias ?? card.name,
                  status: card.status,
                  mask: card.mask ?? 'Tarjeta digital CIERVO',
                  isBlocked: card.isBlocked,
                  onCustomizeAlias: () => _editAlias(context, card),
                  onNfcTap: () => openNfcPaySetup(
                    context,
                    walletCardId: card.id,
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              _BalanceBar(
                balance: balance,
                currency: currency,
                onRecharge: card == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RechargePage(card: card),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _QuickActionsRow(
                card: card,
                onBlock: card == null
                    ? null
                    : () => context.read<WalletCubit>().block(card.id),
              ),
              const SizedBox(height: AppSpacing.md),
              WalletNfcSection(selectedCard: card),
              const SizedBox(height: AppSpacing.xl),
              const WalletAvailableBonusesSection(),
              const SizedBox(height: AppSpacing.xl),
              _RecentMovementsHeader(
                onSeeAll: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FinancialHistoryPage(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (recent.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    'Aun no hay movimientos recientes.',
                    style: TextStyle(color: CiervoBrandColors.textMuted),
                  ),
                )
              else
                ...recent.map(
                  (tx) => _MovementTile(transaction: tx),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editAlias(BuildContext context, WalletCard card) async {
    final controller = TextEditingController(text: _displayAlias ?? card.name);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CiervoBrandColors.surface,
        title: const Text('Personalizar apodo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Tu apodo en la tarjeta'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      setState(() => _displayAlias = controller.text.trim());
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: CiervoBrandColors.textPrimary,
                  ),
                  children: [
                    const TextSpan(text: 'Hola, '),
                    TextSpan(
                      text: userName,
                      style: const TextStyle(color: CiervoBrandColors.gold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Bienvenido a tu cuenta Ciervo',
                style: TextStyle(color: CiervoBrandColors.textMuted),
              ),
            ],
          ),
        ),
        BlocBuilder<NotificationBadgesCubit, NotificationBadges>(
          builder: (context, badges) {
            final count = badges.total;
            return IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsPage(),
                ),
              ),
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: CiervoBrandColors.gold,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BalanceBar extends StatelessWidget {
  const _BalanceBar({
    required this.balance,
    required this.currency,
    this.onRecharge,
  });

  final double balance;
  final String currency;
  final VoidCallback? onRecharge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: CiervoBrandColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SALDO RECARGADO',
                  style: TextStyle(
                    color: CiervoBrandColors.goldSoft,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatMoney(balance, currency),
                  style: const TextStyle(
                    color: CiervoBrandColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 48, color: CiervoBrandColors.gold.withValues(alpha: 0.25)),
          const SizedBox(width: AppSpacing.md),
          InkWell(
            onTap: onRecharge,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: onRecharge == null
                        ? CiervoBrandColors.textMuted
                        : CiervoBrandColors.gold,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RECARGAR\nSALDO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onRecharge == null
                          ? CiervoBrandColors.textMuted
                          : CiervoBrandColors.goldSoft,
                      fontSize: 9,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.card, this.onBlock});

  final WalletCard? card;
  final VoidCallback? onBlock;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _CircleAction(
          label: 'Movimientos',
          icon: Icons.credit_card_outlined,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const FinancialHistoryPage(),
            ),
          ),
        ),
        _CircleAction(
          label: 'Pagar',
          icon: Icons.qr_code_2_outlined,
          onTap: card == null
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PinsPage(card: card!),
                  ),
                ),
        ),
        _CircleAction(
          label: 'Transferir',
          icon: Icons.swap_horiz,
          onTap: card == null
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TransferPage(card: card),
                  ),
                ),
        ),
        _CircleAction(
          label: 'Bloquear tarjeta',
          icon: Icons.lock_outline,
          onTap: onBlock,
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: CiervoBrandColors.surfaceHigh,
            child: Icon(
              icon,
              color: onTap == null
                  ? CiervoBrandColors.textMuted
                  : CiervoBrandColors.gold,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CiervoBrandColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentMovementsHeader extends StatelessWidget {
  const _RecentMovementsHeader({required this.onSeeAll});
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Movimientos recientes',
            style: TextStyle(
              color: CiervoBrandColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Text(
            'Ver todos >',
            style: TextStyle(color: CiervoBrandColors.gold),
          ),
        ),
      ],
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.transaction});
  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.direction.toLowerCase().contains('in') ||
        transaction.direction.toLowerCase().contains('credit') ||
        transaction.amount > 0 && transaction.type.toLowerCase().contains('recharge');
    final color = isCredit ? CiervoBrandColors.income : CiervoBrandColors.expense;
    final prefix = isCredit ? '+' : '-';
    final date = transaction.createdAt?.toLocal();
    final dateLabel = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: CiervoBrandColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: CiervoBrandColors.surfaceHigh,
            child: Icon(_iconFor(transaction), color: CiervoBrandColors.gold, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description.isEmpty
                      ? transaction.type
                      : transaction.description,
                  style: const TextStyle(
                    color: CiervoBrandColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (dateLabel.isNotEmpty)
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: CiervoBrandColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '$prefix${_formatMoney(transaction.amount.abs(), transaction.currency)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: CiervoBrandColors.textMuted, size: 18),
        ],
      ),
    );
  }

  IconData _iconFor(WalletTransaction tx) {
    final text = '${tx.type} ${tx.description}'.toLowerCase();
    if (text.contains('recarga')) return Icons.add_circle_outline;
    if (text.contains('cafe') || text.contains('restaur')) return Icons.local_cafe_outlined;
    if (text.contains('compra') || text.contains('tienda')) return Icons.shopping_bag_outlined;
    return Icons.receipt_long_outlined;
  }

  String _month(int m) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return months[m - 1];
  }
}

String _formatMoney(double amount, String currency) {
  final symbol = currency == 'COP' ? '\$' : '$currency ';
  return '$symbol${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';
}
