import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_component_styles.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class PlaceDetailLocationCard extends StatelessWidget {
  const PlaceDetailLocationCard({
    required this.locationLabel,
    required this.distanceKm,
    this.latitude,
    this.longitude,
    super.key,
  });

  final String locationLabel;
  final double distanceKm;
  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final canOpenMap = latitude != null && longitude != null;

    return InkWell(
      borderRadius: AppRadii.card,
      onTap: canOpenMap ? _openMap : null,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: AppRadii.card,
          gradient: AppComponentStyles.cardOverlayGradient,
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: isDark ? AppColors.shadowWarm : AppColors.shadowWarmSoft,
              blurRadius: isDark ? 24 : 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: AppRadii.card,
              ),
            ),
            Center(
              child: Icon(
                Icons.location_on,
                size: 44,
                color: colorScheme.primary.withValues(alpha: 0.85),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Text(
                '$locationLabel • ${distanceKm.toStringAsFixed(1)} km',
                style: AppTextStyles.label.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMap() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
