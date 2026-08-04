import 'package:flutter/material.dart';

import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_logo_mark.dart';
import '../widgets/ciervo_digital_card.dart';

enum TransferDirectoryAction {
  search,
  ciervoId,
  username,
  contacts,
  favorites,
  scanQr,
  recent,
}

class TransferDirectoryActions extends StatelessWidget {
  const TransferDirectoryActions({
    required this.onSelected,
    this.selected,
    super.key,
  });

  final ValueChanged<TransferDirectoryAction> onSelected;
  final TransferDirectoryAction? selected;

  static const _items =
      <
        ({
          TransferDirectoryAction action,
          String label,
          IconData? icon,
          bool useCiervoLogo,
        })
      >[
        (
          action: TransferDirectoryAction.search,
          label: 'Buscar',
          icon: Icons.search,
          useCiervoLogo: false,
        ),
        (
          action: TransferDirectoryAction.ciervoId,
          label: 'CIERVO ID',
          icon: Icons.badge_outlined,
          useCiervoLogo: false,
        ),
        (
          action: TransferDirectoryAction.username,
          label: '@Usuario',
          icon: Icons.alternate_email,
          useCiervoLogo: false,
        ),
        (
          action: TransferDirectoryAction.contacts,
          label: 'Contactos',
          icon: Icons.people_outline,
          useCiervoLogo: false,
        ),
        (
          action: TransferDirectoryAction.favorites,
          label: 'Favoritos',
          icon: Icons.star_outline,
          useCiervoLogo: false,
        ),
        (
          action: TransferDirectoryAction.scanQr,
          label: 'Escanear QR',
          icon: null,
          useCiervoLogo: true,
        ),
        (
          action: TransferDirectoryAction.recent,
          label: 'Recientes',
          icon: Icons.history,
          useCiervoLogo: false,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = screenSizeOf(context);
    final crossAxisCount = switch (size) {
      ScreenSize.compact => 3,
      ScreenSize.medium => width < 480 ? 4 : 4,
      ScreenSize.expanded => 4,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final spacing = AppSpacing.sm;
        final tileW = (maxW - spacing * (crossAxisCount - 1)) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: AppSpacing.md,
          children: [
            for (final item in _items)
              SizedBox(
                width: tileW,
                child: _DirectoryActionTile(
                  label: item.label,
                  icon: item.icon,
                  useCiervoLogo: item.useCiervoLogo,
                  selected: selected == item.action,
                  onTap: () => onSelected(item.action),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DirectoryActionTile extends StatelessWidget {
  const _DirectoryActionTile({
    required this.label,
    required this.onTap,
    this.icon,
    this.useCiervoLogo = false,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final bool useCiervoLogo;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected
        ? CiervoBrandColors.gold.withValues(alpha: 0.16)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final fg = selected ? CiervoBrandColors.gold : scheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? CiervoBrandColors.gold.withValues(alpha: 0.7)
                        : scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: useCiervoLogo
                    ? const CiervoLogoMark(size: 28)
                    : Icon(icon ?? Icons.apps, color: fg, size: 24),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected
                      ? CiervoBrandColors.gold
                      : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
