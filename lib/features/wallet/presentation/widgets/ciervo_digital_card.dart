import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Paleta premium CIERVO CLUB (Wallet / Notificaciones).
abstract final class CiervoBrandColors {
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldSoft = Color(0xFFC8B27A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF161616);
  static const Color surfaceHigh = Color(0xFF1F1F1F);
  static const Color cream = Color(0xFFF5EEDC);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9A968E);
  static const Color income = Color(0xFF2EAD74);
  static const Color expense = Color(0xFFE25D5D);
}

/// Colores del wallet que respetan modo día / noche.
class CiervoWalletPalette {
  const CiervoWalletPalette({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.textPrimary,
    required this.textMuted,
    required this.cardGradient,
    required this.cardBorderAlpha,
  });

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color textPrimary;
  final Color textMuted;
  final List<Color> cardGradient;
  final double cardBorderAlpha;

  static CiervoWalletPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const CiervoWalletPalette(
        background: CiervoBrandColors.background,
        surface: CiervoBrandColors.surface,
        surfaceHigh: CiervoBrandColors.surfaceHigh,
        textPrimary: CiervoBrandColors.textPrimary,
        textMuted: CiervoBrandColors.textMuted,
        cardGradient: [Color(0xFF1A1712), Color(0xFF0D0D0D), Color(0xFF14110A)],
        cardBorderAlpha: 0.35,
      );
    }
    return const CiervoWalletPalette(
      background: AppColors.dayBackground,
      surface: AppColors.daySurface,
      surfaceHigh: AppColors.daySurfaceHigh,
      textPrimary: AppColors.dayText,
      textMuted: AppColors.dayTextMuted,
      cardGradient: [Color(0xFFFFF8E8), Color(0xFFF8F4EA), Color(0xFFE8DFC8)],
      cardBorderAlpha: 0.45,
    );
  }
}

class CiervoDigitalCard extends StatelessWidget {
  const CiervoDigitalCard({
    required this.holderName,
    required this.alias,
    required this.status,
    required this.mask,
    required this.isBlocked,
    this.onCustomizeAlias,
    this.onNfcTap,
    super.key,
  });

  final String holderName;
  final String alias;
  final String status;
  final String? mask;
  final bool isBlocked;
  final VoidCallback? onCustomizeAlias;
  final VoidCallback? onNfcTap;

  @override
  Widget build(BuildContext context) {
    final palette = CiervoWalletPalette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 340;
        final padding = isCompact ? AppSpacing.md : AppSpacing.lg;
        final logoHeight = isCompact ? 56.0 : 64.0;
        final aliasFontSize = isCompact ? 15.0 : 17.0;
        final showCustomizeButton = onCustomizeAlias != null;

        return AspectRatio(
          aspectRatio: showCustomizeButton ? 1.62 : 1.75,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.cardGradient,
              ),
              border: Border.all(
                color: CiervoBrandColors.gold.withValues(
                  alpha: palette.cardBorderAlpha,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: CiervoBrandColors.gold.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _WavePatternPainter()),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: logoHeight,
                              child: Image.asset(
                                'assets/notifications/ciervo_logo_gold.png',
                                fit: BoxFit.contain,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                            const Spacer(),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'CIERVO',
                                style: TextStyle(
                                  color: CiervoBrandColors.gold,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: isCompact ? 2.5 : 4,
                                  fontSize: isCompact ? 14 : 16,
                                ),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'ENTRETENIMIENTO SIN LÍMITES',
                                maxLines: 1,
                                style: TextStyle(
                                  color: CiervoBrandColors.goldSoft.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontSize: isCompact ? 7 : 8,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: isCompact ? AppSpacing.sm : AppSpacing.md,
                      ),
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'TARJETA DIGITAL',
                                      style: TextStyle(
                                        color: CiervoBrandColors.goldSoft,
                                        fontSize: isCompact ? 9 : 10,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: onNfcTap,
                                  child: Icon(
                                    Icons.nfc,
                                    color: CiervoBrandColors.gold,
                                    size: isCompact ? 18 : 20,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: isCompact ? AppSpacing.sm : AppSpacing.md,
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'NOMBRE / APODO',
                                      style: TextStyle(
                                        color: CiervoBrandColors.goldSoft,
                                        fontSize: isCompact ? 9 : 10,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        alias.isNotEmpty
                                            ? alias.toUpperCase()
                                            : holderName.toUpperCase(),
                                        textAlign: TextAlign.right,
                                        maxLines: 2,
                                        style: TextStyle(
                                          color: palette.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: aliasFontSize,
                                          letterSpacing: 0.5,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                    if (mask != null && mask!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          mask!,
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: palette.textMuted,
                                            fontSize: isCompact ? 10 : 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    Text(
                                      _statusLabel(status, isBlocked),
                                      style: TextStyle(
                                        color: isBlocked
                                            ? CiervoBrandColors.expense
                                            : CiervoBrandColors.income,
                                        fontSize: isCompact ? 10 : 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (showCustomizeButton)
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed: onCustomizeAlias,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: CiervoBrandColors.gold,
                                    side: BorderSide(
                                      color: CiervoBrandColors.gold.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isCompact ? 8 : 10,
                                      vertical: isCompact ? 4 : 5,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: isCompact ? 14 : 15,
                                  ),
                                  label: Text(
                                    'PERSONALIZAR',
                                    style: TextStyle(
                                      fontSize: isCompact ? 9 : 10,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _statusLabel(String status, bool blocked) {
    if (blocked) return 'Bloqueada';
    final normalized = status.toLowerCase();
    if (normalized.contains('virtual')) return 'Virtual · Activa';
    if (normalized.contains('physical') || normalized.contains('fisica')) {
      return 'Fisica · Activa';
    }
    if (normalized.contains('suspend')) return 'Suspendida';
    return 'Activa';
  }
}

class _WavePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CiervoBrandColors.gold.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 6; i++) {
      final path = Path();
      final y = size.height * (0.2 + i * 0.12);
      path.moveTo(0, y);
      path.quadraticBezierTo(size.width * 0.5, y + 18, size.width, y - 6);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
