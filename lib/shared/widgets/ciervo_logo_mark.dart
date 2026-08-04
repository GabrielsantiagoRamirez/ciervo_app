import 'package:flutter/material.dart';

import '../../features/wallet/presentation/widgets/ciervo_digital_card.dart';

/// Marca dorada CIERVO reutilizable (QR, servicios, acciones).
class CiervoLogoMark extends StatelessWidget {
  const CiervoLogoMark({this.size = 40, this.fallbackIconSize, super.key});

  final double size;
  final double? fallbackIconSize;

  /// Solo la cabeza del ciervo (legible en tamaños pequeños).
  static const assetPath = 'assets/branding/ciervo_head_gold.png';
  static const fullLogoPath = 'assets/notifications/ciervo_logo_gold.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Image.asset(
        fullLogoPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(
          Icons.pets,
          color: CiervoBrandColors.gold,
          size: fallbackIconSize ?? size * 0.85,
        ),
      ),
    );
  }
}
