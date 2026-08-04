import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/staggered_reveal.dart';
import '../../../chat_payments/presentation/pages/chat_gift_page.dart';
import '../../../delivery/presentation/pages/customer_orders_page.dart';
import '../../../family_payments/presentation/pages/family_payment_methods_page.dart';
import '../../../financial_history/presentation/pages/financial_history_page.dart';
import '../../../kids/presentation/pages/kids_page.dart';
import '../../../move/presentation/pages/move_home_page.dart';
import '../../../pins/presentation/pages/pin_p2p_pay_page.dart';
import '../../../pins/presentation/pages/pins_page.dart';
import '../../../qr_hub/presentation/pages/qr_hub_page.dart';
import '../../../reservations/presentation/pages/reservations_page.dart';
import '../../../secure_shipment/presentation/pages/secure_shipment_create_page.dart';
import '../../../universal_nfc/presentation/pages/universal_nfc_pay_page.dart';
import '../../../vakupli/presentation/pages/vakupli_page.dart';
import '../../../wallet/domain/entities/wallet_card.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../../wallet/presentation/pages/nfc_physical_cards_page.dart';
import '../../../wallet/presentation/pages/payment_approval_request_page.dart';
import '../../../wallet/presentation/pages/request_money_page.dart';
import '../../../wallet/presentation/pages/transfer_page.dart';
import '../../../wallet/presentation/pages/wallet_page.dart';
import '../../../wallet/presentation/widgets/ciervo_digital_card.dart';

/// Accesos rápidos del ecosistema CIERVO (Home, al final del feed).
class HomeServicesGrid extends StatelessWidget {
  const HomeServicesGrid({this.onFindCommerce, super.key});

  /// Lleva al descubrimiento de comercios en Home (búsqueda / listado).
  final VoidCallback? onFindCommerce;

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
        title: 'Leer QR',
        subtitle: 'Escanear',
        useCiervoLogo: true,
        onTap: () => _push(context, const ScanQrPage()),
      ),
      _ServiceTileData(
        title: 'Vaku',
        subtitle: 'Planes en grupo',
        useCiervoLogo: true,
        onTap: () => _push(context, const VakupliPage()),
      ),
      _ServiceTileData(
        title: 'Mi wallet',
        subtitle: 'Saldo y movimientos',
        useCiervoLogo: true,
        onTap: () => _push(context, const WalletPage()),
      ),
      _ServiceTileData(
        title: 'Paga por mí',
        subtitle: 'Enviar pago',
        icon: Icons.volunteer_activism_outlined,
        onTap: () => _push(context, const RequestMoneyPage()),
      ),
      _ServiceTileData(
        title: 'Autorizarme',
        subtitle: 'el pago en línea',
        icon: Icons.verified_user_outlined,
        onTap: () => _push(context, const PaymentApprovalRequestPage()),
      ),
      _ServiceTileData(
        title: 'Paga por PIN',
        subtitle: 'Asignar PIN',
        icon: Icons.pin_outlined,
        onTap: () => _openPinFlow(context),
      ),
      _ServiceTileData(
        title: 'Tickets',
        subtitle: 'Cine y eventos',
        icon: Icons.confirmation_number_outlined,
        onTap: () => context.push('/tickets'),
      ),
      _ServiceTileData(
        title: 'Marketplace',
        subtitle: 'Promos y tiendas',
        icon: Icons.storefront_outlined,
        onTap: () => context.push('/marketplace'),
      ),
      _ServiceTileData(
        title: 'Reservas',
        subtitle: 'Restaurantes, planes y más',
        icon: Icons.event_available_outlined,
        onTap: () => _push(context, const ReservationsPage()),
      ),
      _ServiceTileData(
        title: 'Envíos de regalo',
        subtitle: 'Enviar detalles con amor',
        icon: Icons.card_giftcard_outlined,
        onTap: () => _push(context, const ChatGiftPage()),
      ),
      _ServiceTileData(
        title: 'Crear envío',
        subtitle: 'Dinero al instante',
        icon: Icons.send_outlined,
        badge: 'Nuevo',
        onTap: () => _openMoneyOrSecureShipment(context),
      ),
      _ServiceTileData(
        title: 'Solicitudes Kids',
        subtitle: 'Ver solicitudes',
        icon: Icons.family_restroom_outlined,
        onTap: () => context.push('/master/payment-requests'),
      ),
      _ServiceTileData(
        title: 'Solicita delivery',
        subtitle: 'Pide lo que quieras',
        icon: Icons.delivery_dining_outlined,
        onTap: () => _openDelivery(context),
      ),
      _ServiceTileData(
        title: 'Busca tu comercio',
        subtitle: 'Descubre comercios cerca de ti',
        icon: Icons.storefront_outlined,
        useCiervoBadge: true,
        onTap: () => _openFindCommerce(context),
      ),
      _ServiceTileData(
        title: 'Registrar tarjeta Kids',
        subtitle: 'Vincular tarjeta',
        icon: Icons.credit_card_outlined,
        onTap: () => _push(context, const KidsPage()),
      ),
      _ServiceTileData(
        title: 'Cuenta respaldo Kids',
        subtitle: 'Configurar respaldo',
        icon: Icons.shield_outlined,
        onTap: () => _push(context, const FamilyPaymentMethodsPage()),
      ),
      _ServiceTileData(
        title: 'Historial',
        subtitle: 'Todos tus movimientos',
        icon: Icons.history,
        onTap: () => _push(context, const FinancialHistoryPage()),
      ),
      _ServiceTileData(
        title: 'Ciervo Move',
        subtitle: 'Transporte seguro',
        icon: Icons.directions_car_outlined,
        onTap: () => _push(context, const MoveHomePage()),
      ),
      _ServiceTileData(
        title: 'NFC Universal',
        subtitle: 'Paga sin contacto',
        icon: Icons.contactless_outlined,
        onTap: () => _push(context, const UniversalNfcPayPage()),
      ),
      _ServiceTileData(
        title: 'Tarjeta física',
        subtitle: 'Pide tu tarjeta',
        icon: Icons.credit_card,
        onTap: () => _openPhysicalCard(context),
      ),
    ];
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<WalletCard?> _primaryCard() async {
    final result = await getIt<WalletRepository>().cards();
    return result.when(
      success: (cards) {
        if (cards.isEmpty) return null;
        for (final card in cards) {
          if (card.isPrimary) return card;
        }
        return cards.first;
      },
      failure: (_) => null,
    );
  }

  Future<void> _openMoneyOrSecureShipment(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Transferir dinero'),
              subtitle: const Text('Envío instantáneo CIERVO'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final card = await _primaryCard();
                if (!context.mounted) return;
                _push(context, TransferPage(card: card));
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Envío seguro'),
              subtitle: const Text('Paquete con protección CIERVO'),
              onTap: () {
                Navigator.pop(sheetContext);
                _push(context, const SecureShipmentCreatePage());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openDelivery(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Elige un comercio en Inicio y pide delivery desde su ficha.',
        ),
      ),
    );
    if (onFindCommerce != null) {
      onFindCommerce!();
      return;
    }
    _push(context, const CustomerOrdersPage());
  }

  void _openFindCommerce(BuildContext context) {
    if (onFindCommerce != null) {
      onFindCommerce!();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Usa la búsqueda de Inicio para encontrar comercios.'),
      ),
    );
  }

  Future<void> _openPinFlow(BuildContext context) async {
    final card = await _primaryCard();
    if (!context.mounted) return;
    if (card == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitas una wallet activa para PIN.')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: const Text('Administrar PIN'),
              onTap: () {
                Navigator.pop(sheetContext);
                _push(context, PinsPage(card: card));
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Cobrar con PIN'),
              onTap: () {
                Navigator.pop(sheetContext);
                _push(context, PinP2PPayPage(card: card));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPhysicalCard(BuildContext context) async {
    final card = await _primaryCard();
    if (!context.mounted) return;
    _push(context, NfcPhysicalCardsPage(walletCard: card));
  }
}

class _ServiceTileData {
  const _ServiceTileData({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon,
    this.useCiervoLogo = false,
    this.badge,
    this.useCiervoBadge = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData? icon;
  final bool useCiervoLogo;
  final String? badge;
  final bool useCiervoBadge;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.tile});

  final _ServiceTileData tile;

  static const double _iconSize = 44;
  static const double _logoSize = 52;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? CiervoBrandColors.gold
        : const Color(0xFF6B5420);
    final subtitleColor = isDark
        ? CiervoBrandColors.goldSoft
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final border = CiervoBrandColors.gold.withValues(
      alpha: isDark ? 0.55 : 0.45,
    );
    final tileBg = isDark
        ? Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
        : CiervoBrandColors.gold.withValues(alpha: 0.10);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tile.onTap,
        borderRadius: AppRadii.card,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadii.card,
            border: Border.all(color: border, width: 1.2),
            color: tileBg,
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
                          color: titleColor,
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
                          color: subtitleColor,
                          height: 1.15,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (tile.badge != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE25D5D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tile.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
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
