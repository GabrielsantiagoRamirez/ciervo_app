import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../kid_businesses/presentation/pages/kid_businesses_page.dart';
import '../../../kid_pay_for_me/presentation/pages/kid_pay_for_me_list_page.dart';
import '../../../wallet/presentation/widgets/ciervo_digital_card.dart';

class KidPremiumWalletDashboard extends StatelessWidget {
  const KidPremiumWalletDashboard({
    required this.userName,
    required this.balance,
    required this.heldBalance,
    required this.currency,
    required this.movements,
    required this.onRefresh,
    super.key,
  });

  final String userName;
  final double balance;
  final double heldBalance;
  final String currency;
  final List<Map<String, dynamic>> movements;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final palette = CiervoWalletPalette.of(context);
    final recent = movements.take(5).toList();

    return ColoredBox(
      color: palette.background,
      child: RefreshIndicator(
        color: CiervoBrandColors.gold,
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            _KidHeader(userName: userName, palette: palette),
            const SizedBox(height: AppSpacing.md),
            _ParentAuthBanner(palette: palette),
            const SizedBox(height: AppSpacing.lg),
            CiervoDigitalCard(
              holderName: userName,
              alias: 'Wallet Kids',
              status: 'Activa',
              mask: 'Tarjeta digital CIERVO Kids',
              isBlocked: false,
              onNfcTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const KidBusinessesPage(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _KidBalanceBar(
              balance: balance,
              heldBalance: heldBalance,
              currency: currency,
              palette: palette,
              onRequestFunds: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const KidBusinessesPage(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _KidQuickActionsRow(palette: palette),
            const SizedBox(height: AppSpacing.xl),
            _RecentMovementsHeader(palette: palette),
            const SizedBox(height: AppSpacing.sm),
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'Aún no hay movimientos recientes.',
                  style: TextStyle(color: palette.textMuted),
                ),
              )
            else
              ...recent.map(
                (item) => _KidMovementTile(item: item, palette: palette),
              ),
            if (movements.length > recent.length) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${movements.length - recent.length} movimientos más abajo',
                style: TextStyle(color: palette.textMuted, fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...movements.skip(5).map(
                    (item) => _KidMovementTile(item: item, palette: palette),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KidHeader extends StatelessWidget {
  const _KidHeader({required this.userName, required this.palette});

  final String userName;
  final CiervoWalletPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: palette.textPrimary,
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
        Text(
          'Tu wallet CIERVO Kids',
          style: TextStyle(color: palette.textMuted),
        ),
      ],
    );
  }
}

class _ParentAuthBanner extends StatelessWidget {
  const _ParentAuthBanner({required this.palette});

  final CiervoWalletPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CiervoBrandColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CiervoBrandColors.gold.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: CiervoBrandColors.gold),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Algunos pagos requieren aprobación de tu tutor antes de completarse.',
              style: TextStyle(color: palette.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _KidBalanceBar extends StatelessWidget {
  const _KidBalanceBar({
    required this.balance,
    required this.heldBalance,
    required this.currency,
    required this.palette,
    required this.onRequestFunds,
  });

  final double balance;
  final double heldBalance;
  final String currency;
  final CiervoWalletPalette palette;
  final VoidCallback onRequestFunds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Theme.of(context).brightness == Brightness.light
            ? Border.all(color: palette.textMuted.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SALDO DISPONIBLE',
                  style: TextStyle(
                    color: CiervoBrandColors.goldSoft,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatMoney(balance, currency),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (heldBalance > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Retenido: ${_formatMoney(heldBalance, currency)}',
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: CiervoBrandColors.gold.withValues(alpha: 0.25),
          ),
          const SizedBox(width: AppSpacing.md),
          InkWell(
            onTap: onRequestFunds,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                children: const [
                  Icon(
                    Icons.family_restroom_outlined,
                    color: CiervoBrandColors.gold,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'PEDIR\nAL TUTOR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CiervoBrandColors.goldSoft,
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

class _KidQuickActionsRow extends StatelessWidget {
  const _KidQuickActionsRow({required this.palette});

  final CiervoWalletPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _KidCircleAction(
          label: 'Comercios',
          icon: Icons.storefront_outlined,
          palette: palette,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const KidBusinessesPage()),
          ),
        ),
        _KidCircleAction(
          label: 'Pagar',
          icon: Icons.payments_outlined,
          palette: palette,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const KidBusinessesPage()),
          ),
        ),
        _KidCircleAction(
          label: 'Solicitudes',
          icon: Icons.request_page_outlined,
          palette: palette,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const KidPayForMeListPage(),
            ),
          ),
        ),
        _KidCircleAction(
          label: 'Movimientos',
          icon: Icons.receipt_long_outlined,
          palette: palette,
          onTap: () {},
        ),
      ],
    );
  }
}

class _KidCircleAction extends StatelessWidget {
  const _KidCircleAction({
    required this.label,
    required this.icon,
    required this.palette,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final CiervoWalletPalette palette;
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
            backgroundColor: palette.surfaceHigh,
            child: Icon(icon, color: CiervoBrandColors.gold),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentMovementsHeader extends StatelessWidget {
  const _RecentMovementsHeader({required this.palette});

  final CiervoWalletPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Movimientos recientes',
      style: TextStyle(
        color: palette.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _KidMovementTile extends StatelessWidget {
  const _KidMovementTile({required this.item, required this.palette});

  final Map<String, dynamic> item;
  final CiervoWalletPalette palette;

  @override
  Widget build(BuildContext context) {
    final amount = _num(item['amount']);
    final isCredit = amount >= 0;
    final color = isCredit ? CiervoBrandColors.income : CiervoBrandColors.expense;
    final prefix = isCredit ? '+' : '-';
    final title =
        '${item['description'] ?? item['type'] ?? 'Movimiento'}';
    final subtitle = '${item['createdAt'] ?? ''}';
    final status = '${item['status'] ?? ''}';
    final needsApproval = status.toLowerCase().contains('pending') ||
        status.toLowerCase().contains('approval');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Theme.of(context).brightness == Brightness.light
            ? Border.all(color: palette.textMuted.withValues(alpha: 0.15))
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: palette.surfaceHigh,
            child: Icon(
              needsApproval ? Icons.hourglass_top : Icons.receipt_long_outlined,
              color: CiervoBrandColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                if (needsApproval)
                  Text(
                    'Pendiente de aprobación del tutor',
                    style: TextStyle(
                      color: CiervoBrandColors.goldSoft,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '$prefix${_formatMoney(amount.abs(), 'COP')}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  double _num(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

String _formatMoney(double amount, String currency) {
  final symbol = currency == 'COP' ? '\$' : '$currency ';
  return '$symbol${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';
}
