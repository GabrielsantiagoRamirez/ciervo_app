import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../shared/widgets/staggered_reveal.dart';
import '../../../kid_businesses/presentation/pages/kid_businesses_page.dart';
import '../../../kid_family_chat/presentation/pages/kid_family_page.dart';
import '../../../kid_nfc/presentation/pages/kid_nfc_device_registration_page.dart';
import '../../../kid_pay_for_me/presentation/pages/kid_pay_for_me_list_page.dart';
import '../../../kid_pay_for_me/presentation/pages/kid_pay_for_me_request_page.dart';
import '../../../kid_wallet/presentation/pages/kid_wallet_page.dart';
import '../../../wallet/presentation/widgets/ciervo_digital_card.dart';

/// Accesos rápidos del ecosistema CIERVO adaptados a la app Kids.
class KidServicesGrid extends StatelessWidget {
  const KidServicesGrid({this.onViewMovements, super.key});

  /// Si está en wallet, puede hacer scroll a movimientos en lugar de navegar.
  final VoidCallback? onViewMovements;

  @override
  Widget build(BuildContext context) {
    final tiles = _tiles(context);
    final columns = switch (screenSizeOf(context)) {
      ScreenSize.compact => 2,
      ScreenSize.medium => 2,
      ScreenSize.expanded => 4,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Servicios CIERVO', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Todo lo que puedes hacer desde aquí',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = AppSpacing.sm;
            final tileW =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < tiles.length; i++)
                  SizedBox(
                    width: tileW,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: StaggeredReveal(
                        index: i,
                        baseDelay: const Duration(milliseconds: 35),
                        child: _ServiceTile(tile: tiles[i]),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<_ServiceTileData> _tiles(BuildContext context) {
    return [
      _ServiceTileData(
        title: 'Pagar con QR',
        subtitle: 'Escanear en comercio',
        useCiervoLogo: true,
        onTap: () => context.push('/kids-v2/qr'),
      ),
      _ServiceTileData(
        title: 'Solicitar pago',
        subtitle: 'Pide a tu familia',
        icon: Icons.volunteer_activism_outlined,
        onTap: () => _push(context, const KidPayForMeRequestPage()),
      ),
      _ServiceTileData(
        title: 'Mis solicitudes',
        subtitle: 'Ver pedidos Pinduck',
        icon: Icons.family_restroom_outlined,
        onTap: () => _push(context, const KidPayForMeListPage()),
      ),
      _ServiceTileData(
        title: 'Busca tu comercio',
        subtitle: 'Comercios permitidos',
        icon: Icons.storefront_outlined,
        useCiervoBadge: true,
        onTap: () => _push(context, const KidBusinessesPage()),
      ),
      _ServiceTileData(
        title: 'Chat familia',
        subtitle: 'Mensajes con tu hogar',
        icon: Icons.chat_bubble_outline,
        onTap: () => _push(context, const KidFamilyPage()),
      ),
      _ServiceTileData(
        title: 'Tarjetas y NFC',
        subtitle: 'Registrar dispositivo',
        icon: Icons.credit_card_outlined,
        onTap: () => _push(context, const KidNfcDeviceRegistrationPage()),
      ),
      _ServiceTileData(
        title: 'Pagar con NFC',
        subtitle: 'Elige un comercio',
        icon: Icons.contactless_outlined,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Abre un comercio permitido y paga con NFC desde ahí.',
              ),
            ),
          );
          _push(context, const KidBusinessesPage());
        },
      ),
      _ServiceTileData(
        title: 'Mi wallet',
        subtitle: 'Saldo y límites',
        icon: Icons.account_balance_wallet_outlined,
        onTap: () => _push(context, const KidWalletPage()),
      ),
      _ServiceTileData(
        title: 'Tickets',
        subtitle: 'Cine y eventos',
        icon: Icons.confirmation_number_outlined,
        onTap: () => context.push('/tickets'),
      ),
      _ServiceTileData(
        title: 'Historial',
        subtitle: 'Tus movimientos',
        icon: Icons.history,
        onTap: () {
          if (onViewMovements != null) {
            onViewMovements!();
            return;
          }
          _push(context, const KidWalletPage());
        },
      ),
    ];
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _ServiceTileData {
  const _ServiceTileData({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon,
    this.useCiervoLogo = false,
    this.useCiervoBadge = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData? icon;
  final bool useCiervoLogo;
  final bool useCiervoBadge;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.tile});

  final _ServiceTileData tile;

  static const double _iconSize = 44;
  static const double _logoSize = 52;

  @override
  Widget build(BuildContext context) {
    final border = CiervoBrandColors.gold.withValues(alpha: 0.55);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tile.onTap,
        borderRadius: AppRadii.card,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadii.card,
            border: Border.all(color: border, width: 1.2),
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (tile.useCiervoLogo)
                        Image.asset(
                          'assets/branding/ciervo_head_gold.png',
                          width: _logoSize,
                          height: _logoSize,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.pets,
                            color: CiervoBrandColors.gold,
                            size: _iconSize,
                          ),
                        )
                      else
                        Icon(
                          tile.icon ?? Icons.apps,
                          color: CiervoBrandColors.gold,
                          size: _iconSize,
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        tile.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: CiervoBrandColors.gold,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tile.subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: CiervoBrandColors.goldSoft,
                          height: 1.15,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (tile.useCiervoBadge)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Image.asset(
                    'assets/branding/ciervo_head_gold.png',
                    width: 18,
                    height: 18,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.pets,
                      size: 14,
                      color: CiervoBrandColors.gold,
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
