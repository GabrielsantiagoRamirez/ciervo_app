import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../kid_businesses/presentation/pages/kid_businesses_page.dart';
import '../../../kid_nfc/presentation/pages/kid_nfc_device_registration_page.dart';
import '../../../kid_pay_for_me/presentation/pages/kid_pay_for_me_request_page.dart';
import '../../../wallet/presentation/widgets/ciervo_digital_card.dart';

class KidPremiumWalletDashboard extends StatefulWidget {
  const KidPremiumWalletDashboard({
    required this.userName,
    required this.balance,
    required this.heldBalance,
    required this.currency,
    required this.movements,
    required this.monthlySpent,
    required this.monthlyLimit,
    required this.shieldLocked,
    required this.cardLast4,
    required this.photoUrl,
    required this.onRefresh,
    super.key,
  });

  final String userName;
  final double balance;
  final double heldBalance;
  final String currency;
  final List<Map<String, dynamic>> movements;
  final double monthlySpent;
  final double monthlyLimit;
  final bool? shieldLocked;
  final String cardLast4;
  final String photoUrl;
  final Future<void> Function() onRefresh;

  @override
  State<KidPremiumWalletDashboard> createState() =>
      _KidPremiumWalletDashboardState();
}

class _KidPremiumWalletDashboardState extends State<KidPremiumWalletDashboard> {
  final _scrollController = ScrollController();
  final _movementsKey = GlobalKey();

  void _scrollToMovements() {
    final context = _movementsKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = CiervoWalletPalette.of(context);
    final recent = widget.movements.take(5).toList();

    return ColoredBox(
      color: palette.background,
      child: RefreshIndicator(
        color: CiervoBrandColors.gold,
        onRefresh: widget.onRefresh,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            _KidHeader(
              userName: widget.userName,
              photoUrl: widget.photoUrl,
              palette: palette,
            ),
            const SizedBox(height: AppSpacing.md),
            _WalletOverviewCard(
              balance: widget.balance,
              heldBalance: widget.heldBalance,
              currency: widget.currency,
              monthlySpent: widget.monthlySpent,
              monthlyLimit: widget.monthlyLimit,
              cardLast4: widget.cardLast4,
              userName: widget.userName,
              palette: palette,
              onRequestFunds: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const KidPayForMeRequestPage(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _KidQuickActionsRow(
              palette: palette,
              onMovementsTap: _scrollToMovements,
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => context.push('/movies'),
              icon: const Icon(Icons.local_movies_outlined),
              label: const Text('Explorar películas y solicitar entradas'),
            ),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton.icon(
              onPressed: () => context.push('/kids-v2/qr'),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Pagar con QR Kids'),
            ),
            const SizedBox(height: AppSpacing.md),
            _ShieldBanner(palette: palette, isLocked: widget.shieldLocked),
            const SizedBox(height: AppSpacing.lg),
            KeyedSubtree(
              key: _movementsKey,
              child: _RecentMovementsHeader(palette: palette),
            ),
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
            if (widget.movements.length > recent.length) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${widget.movements.length - recent.length} movimientos más abajo',
                style: TextStyle(color: palette.textMuted, fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...widget.movements
                  .skip(5)
                  .map(
                    (item) => _KidMovementTile(item: item, palette: palette),
                  ),
            ],
            if (widget.monthlyLimit > 0 || widget.monthlySpent > 0) ...[
              const SizedBox(height: AppSpacing.lg),
              _MonthlyUsageCard(
                spent: widget.monthlySpent,
                limit: widget.monthlyLimit,
                currency: widget.currency,
                palette: palette,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KidHeader extends StatelessWidget {
  const _KidHeader({
    required this.userName,
    required this.photoUrl,
    required this.palette,
  });

  final String userName;
  final String photoUrl;
  final CiervoWalletPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/notifications/ciervo_logo_gold.png',
          width: 54,
          height: 54,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'C I E R V O',
                style: TextStyle(
                  color: CiervoBrandColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: 3,
                ),
              ),
              Text(
                'K I D S  ·  Hola, $userName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: CiervoBrandColors.gold,
          child: CircleAvatar(
            radius: 21,
            backgroundColor: palette.surfaceHigh,
            backgroundImage: photoUrl.trim().isEmpty
                ? null
                : NetworkImage(photoUrl),
            child: photoUrl.trim().isEmpty
                ? Text(
                    userName.isEmpty ? 'K' : userName[0].toUpperCase(),
                    style: const TextStyle(
                      color: CiervoBrandColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _ShieldBanner extends StatelessWidget {
  const _ShieldBanner({required this.palette, required this.isLocked});

  final CiervoWalletPalette palette;
  final bool? isLocked;

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
          Icon(
            isLocked == true ? Icons.gpp_bad_outlined : Icons.gpp_good_outlined,
            color: isLocked == true
                ? CiervoBrandColors.expense
                : CiervoBrandColors.gold,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLocked == true
                      ? 'CIERVO SHIELD BLOQUEADO'
                      : isLocked == false
                      ? 'CIERVO SHIELD ACTIVO'
                      : 'PAGOS SUPERVISADOS',
                  style: TextStyle(
                    color: isLocked == true
                        ? CiervoBrandColors.expense
                        : CiervoBrandColors.goldSoft,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  isLocked == true
                      ? 'Tu tutor debe revisar la seguridad de la cuenta.'
                      : isLocked == false
                      ? 'Tus solicitudes están protegidas por las reglas de tu tutor.'
                      : 'Las solicitudes requieren las validaciones definidas por tu tutor.',
                  style: TextStyle(color: palette.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: palette.textMuted, size: 20),
        ],
      ),
    );
  }
}

class _WalletOverviewCard extends StatelessWidget {
  const _WalletOverviewCard({
    required this.balance,
    required this.heldBalance,
    required this.currency,
    required this.monthlySpent,
    required this.monthlyLimit,
    required this.cardLast4,
    required this.userName,
    required this.palette,
    required this.onRequestFunds,
  });

  final double balance;
  final double heldBalance;
  final String currency;
  final double monthlySpent;
  final double monthlyLimit;
  final String cardLast4;
  final String userName;
  final CiervoWalletPalette palette;
  final VoidCallback onRequestFunds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CiervoBrandColors.gold.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MI WALLET',
            style: TextStyle(
              color: CiervoBrandColors.goldSoft,
              fontSize: 10,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Saldo disponible',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.visibility_outlined,
                          color: palette.textMuted,
                          size: 14,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatMoney(balance, currency),
                        style: const TextStyle(
                          color: CiervoBrandColors.gold,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (heldBalance > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Retenido: ${_formatMoney(heldBalance, currency)}',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: onRequestFunds,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: CiervoBrandColors.goldSoft,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.send_rounded, size: 17),
                      label: const Text('Pinduck'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _CompactKidCard(
                userName: userName,
                cardLast4: cardLast4,
                palette: palette,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Límite mensual',
                style: TextStyle(color: palette.textMuted, fontSize: 11),
              ),
              Text(
                monthlyLimit > 0
                    ? '${(_usage * 100).round()}% utilizado'
                    : 'Límite no informado',
                style: TextStyle(color: palette.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            monthlyLimit > 0
                ? _formatMoney(monthlyLimit, currency)
                : 'Consulta con tu tutor',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: monthlyLimit > 0 ? _usage : 0,
              minHeight: 6,
              backgroundColor: palette.surfaceHigh,
              color: CiervoBrandColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  double get _usage {
    if (monthlyLimit <= 0) return 0;
    return (monthlySpent / monthlyLimit).clamp(0.0, 1.0).toDouble();
  }
}

class _CompactKidCard extends StatelessWidget {
  const _CompactKidCard({
    required this.userName,
    required this.cardLast4,
    required this.palette,
  });

  final String userName;
  final String cardLast4;
  final CiervoWalletPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      height: 116,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.cardGradient,
        ),
        border: Border.all(
          color: CiervoBrandColors.gold.withValues(alpha: 0.5),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CiervoBrandColors.gold.withValues(alpha: 0.12),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/notifications/ciervo_logo_gold.png',
                    width: 30,
                    height: 30,
                  ),
                  const Text(
                    'VIRTUAL',
                    style: TextStyle(
                      color: CiervoBrandColors.goldSoft,
                      fontSize: 7,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                userName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '•••• $cardLast4',
                style: const TextStyle(
                  color: CiervoBrandColors.goldSoft,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'CIERVO KIDS',
                  style: TextStyle(
                    color: CiervoBrandColors.gold,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KidQuickActionsRow extends StatelessWidget {
  const _KidQuickActionsRow({required this.palette, this.onMovementsTap});

  final CiervoWalletPalette palette;
  final VoidCallback? onMovementsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KidCircleAction(
            label: 'Solicitar\npago',
            icon: Icons.send_rounded,
            palette: palette,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const KidPayForMeRequestPage(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _KidCircleAction(
            label: 'Buscar\ncomercio',
            icon: Icons.storefront_outlined,
            palette: palette,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const KidBusinessesPage(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _KidCircleAction(
            label: 'Tarjetas\ny NFC',
            icon: Icons.credit_card_outlined,
            palette: palette,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const KidNfcDeviceRegistrationPage(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _KidCircleAction(
            label: 'Ver\nmovimientos',
            icon: Icons.receipt_long_outlined,
            palette: palette,
            onTap: onMovementsTap,
          ),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: palette.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CiervoBrandColors.gold.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: CiervoBrandColors.gold, size: 22),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 9,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyUsageCard extends StatelessWidget {
  const _MonthlyUsageCard({
    required this.spent,
    required this.limit,
    required this.currency,
    required this.palette,
  });

  final double spent;
  final double limit;
  final String currency;
  final CiervoWalletPalette palette;

  @override
  Widget build(BuildContext context) {
    final progress = limit <= 0
        ? 0.0
        : (spent / limit).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CiervoBrandColors.gold.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Este mes has solicitado',
                  style: TextStyle(color: palette.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatMoney(spent, currency),
                  style: const TextStyle(
                    color: CiervoBrandColors.gold,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  limit > 0
                      ? 'de ${_formatMoney(limit, currency)}'
                      : 'Tu tutor administra el límite',
                  style: TextStyle(color: palette.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: palette.surfaceHigh,
                  color: CiervoBrandColors.gold,
                ),
                Text(
                  limit > 0 ? '${(progress * 100).round()}%' : '—',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
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
    return Row(
      children: [
        Expanded(
          child: Text(
            'ÚLTIMOS MOVIMIENTOS',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'VER TODOS  →',
              style: TextStyle(
                color: CiervoBrandColors.goldSoft,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
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
    final color = isCredit
        ? CiervoBrandColors.income
        : CiervoBrandColors.expense;
    final prefix = isCredit ? '+' : '-';
    final title = '${item['description'] ?? item['type'] ?? 'Movimiento'}';
    final subtitle = '${item['createdAt'] ?? ''}';
    final status = '${item['status'] ?? ''}';
    final needsApproval =
        status.toLowerCase().contains('pending') ||
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
            '$prefix${_formatMoney(amount.abs(), '${item['currency'] ?? 'COP'}')}',
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
  return '$symbol${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
