import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Vista previa estilo mapa (sin API key) con cuadrícula y pin.
class LocationMapPreview extends StatelessWidget {
  const LocationMapPreview({
    required this.latitude,
    required this.longitude,
    this.height = 120,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(14)),
    super.key,
  });

  final double latitude;
  final double longitude;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _MapGridPainter(
                lineColor: colors.outlineVariant.withValues(alpha: 0.45),
                fillColor: Color.lerp(
                  colors.primaryContainer,
                  colors.surfaceContainerHighest,
                  0.55,
                )!,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    colors.surface.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
            const Center(
              child: Icon(
                Icons.location_on,
                size: 36,
                color: Colors.redAccent,
              ),
            ),
            Positioned(
              left: AppSpacing.sm,
              top: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter({
    required this.lineColor,
    required this.fillColor,
  });

  final Color lineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = fillColor);
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    const cols = 8;
    const rows = 5;
    for (var i = 1; i < cols; i++) {
      final x = size.width * i / cols;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var j = 1; j < rows; j++) {
      final y = size.height * j / rows;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final roadPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height * 0.62),
      Offset(size.width, size.height * 0.58),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.42, size.height),
      roadPaint,
    );
    final dotPaint = Paint()..color = lineColor.withValues(alpha: 0.25);
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final cx = size.width * (0.5 + 0.28 * math.cos(angle));
      final cy = size.height * (0.5 + 0.22 * math.sin(angle));
      canvas.drawCircle(Offset(cx, cy), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor || oldDelegate.fillColor != fillColor;
}
