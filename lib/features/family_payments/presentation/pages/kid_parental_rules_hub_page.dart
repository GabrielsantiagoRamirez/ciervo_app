import 'package:flutter/material.dart';

import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import 'kid_approval_rules_page.dart';
import 'kid_auto_payment_page.dart';
import 'kid_family_limits_page.dart';
import 'kid_geofence_page.dart';
import 'kid_merchant_rules_page.dart';
import 'parent_payment_history_page.dart';
import 'kid_payment_source_page.dart';
import 'kid_schedule_rules_page.dart';

class KidParentalRulesHubPage extends StatelessWidget {
  const KidParentalRulesHubPage({
    required this.kidId,
    required this.kidName,
    super.key,
  });

  final String kidId;
  final String kidName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reglas · $kidName')),
      body: ListView(
        padding: pagePaddingOf(context),
        children: [
          Text(
            'Configura límites, comercios, horarios y pagos automáticos.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          _RuleTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Fuente de pago',
            subtitle: 'Tarjeta del tutor cuando no hay saldo Kids.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => KidPaymentSourcePage(
                  kidId: kidId,
                  kidName: kidName,
                ),
              ),
            ),
          ),
          _RuleTile(
            icon: Icons.speed_outlined,
            title: 'Límites',
            subtitle: 'Por compra, diario y mensual.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => KidFamilyLimitsPage(kidId: kidId),
              ),
            ),
          ),
          _RuleTile(
            icon: Icons.storefront_outlined,
            title: 'Comercios',
            subtitle: 'Categorías y comercios permitidos o bloqueados.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => KidMerchantRulesPage(kidId: kidId),
              ),
            ),
          ),
          _RuleTile(
            icon: Icons.schedule_outlined,
            title: 'Horarios',
            subtitle: 'Días y franjas permitidas.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => KidScheduleRulesPage(kidId: kidId),
              ),
            ),
          ),
          _RuleTile(
            icon: Icons.flash_on_outlined,
            title: 'Pago automático',
            subtitle: 'Respaldo automático con tarjeta del tutor.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => KidAutoPaymentPage(kidId: kidId),
              ),
            ),
          ),
          _RuleTile(
            icon: Icons.rule_folder_outlined,
            title: 'Reglas de aprobación',
            subtitle: 'Montos y categorías que requieren aprobación.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => KidApprovalRulesPage(kidId: kidId),
              ),
            ),
          ),
          _RuleTile(
            icon: Icons.location_on_outlined,
            title: 'Geocerca',
            subtitle: 'Zona segura para pagos.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => KidGeofencePage(kidId: kidId),
              ),
            ),
          ),
          _RuleTile(
            icon: Icons.receipt_long_outlined,
            title: 'Historial de pagos',
            subtitle: 'Movimientos del menor.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => KidPaymentHistoryPage(kidId: kidId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CiervoCard(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
