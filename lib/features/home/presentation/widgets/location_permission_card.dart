import 'package:flutter/material.dart';

import '../../../../core/location/location_permission_status.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_card.dart';

class LocationPermissionCard extends StatelessWidget {
  const LocationPermissionCard({
    required this.status,
    required this.onAllow,
    required this.onContinueWithoutLocation,
    required this.onOpenSettings,
    required this.onOpenLocationSettings,
    super.key,
  });

  final AppLocationPermissionStatus status;
  final VoidCallback onAllow;
  final VoidCallback onContinueWithoutLocation;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenLocationSettings;

  @override
  Widget build(BuildContext context) {
    final blocked = status == AppLocationPermissionStatus.deniedForever;
    final serviceDisabled =
        status == AppLocationPermissionStatus.serviceDisabled;

    return CiervoCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            serviceDisabled
                ? Icons.location_disabled_outlined
                : Icons.location_on_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Experiencias cerca de ti',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ciervo usa tu ubicacion para mostrarte experiencias, comercios, eventos y promociones cercanas.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: CiervoButton(
                  label: blocked
                      ? 'Abrir ajustes'
                      : serviceDisabled
                      ? 'Activar GPS'
                      : 'Permitir',
                  icon: blocked || serviceDisabled
                      ? Icons.settings_outlined
                      : Icons.my_location_outlined,
                  onPressed: blocked
                      ? onOpenSettings
                      : serviceDisabled
                      ? onOpenLocationSettings
                      : onAllow,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: CiervoButton(
                  label: 'Sin ubicacion',
                  variant: CiervoButtonVariant.secondary,
                  icon: Icons.search_outlined,
                  onPressed: onContinueWithoutLocation,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
