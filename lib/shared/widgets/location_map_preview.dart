import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';



import '../../core/di/service_locator.dart';

import '../../core/geo/geo_repository.dart';

import '../../core/theme/app_spacing.dart';



/// Vista previa de mapa con dirección real vía `/api/geo/reverse`.

class LocationMapPreview extends StatefulWidget {

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

  State<LocationMapPreview> createState() => _LocationMapPreviewState();

}



class _LocationMapPreviewState extends State<LocationMapPreview> {

  String? _address;

  String? _mapsUrl;

  bool _loading = true;



  @override

  void initState() {

    super.initState();

    _loadAddress();

  }



  Future<void> _loadAddress() async {

    final result = await getIt<GeoRepository>().reverse(

      latitude: widget.latitude,

      longitude: widget.longitude,

    );

    if (!mounted) return;

    result.when(

      success: (geo) => setState(() {

        _loading = false;

        _address = geo.displayLine.isNotEmpty

            ? geo.displayLine

            : '${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}';

        _mapsUrl = geo.mapsUrl;

      }),

      failure: (_) => setState(() {

        _loading = false;

        _address =

            '${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}';

      }),

    );

  }



  Future<void> _openMaps() async {

    final url = _mapsUrl;

    if (url == null || url.isEmpty) {

      final fallback = Uri.parse(

        'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}',

      );

      await launchUrl(fallback, mode: LaunchMode.externalApplication);

      return;

    }

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  }



  @override

  Widget build(BuildContext context) {

    final colors = Theme.of(context).colorScheme;

    return ClipRRect(

      borderRadius: widget.borderRadius,

      child: SizedBox(

        height: widget.height,

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

                    colors.surface.withValues(alpha: 0.55),

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

              right: AppSpacing.sm,

              bottom: AppSpacing.sm,

              child: Material(

                color: colors.surface.withValues(alpha: 0.92),

                borderRadius: BorderRadius.circular(8),

                child: InkWell(

                  onTap: _openMaps,

                  borderRadius: BorderRadius.circular(8),

                  child: Padding(

                    padding: const EdgeInsets.symmetric(

                      horizontal: AppSpacing.sm,

                      vertical: AppSpacing.xs,

                    ),

                    child: Row(

                      children: [

                        Expanded(

                          child: Text(

                            _loading ? 'Obteniendo dirección…' : (_address ?? ''),

                            maxLines: 2,

                            overflow: TextOverflow.ellipsis,

                            style: Theme.of(context).textTheme.labelSmall,

                          ),

                        ),

                        const Icon(Icons.open_in_new, size: 16),

                      ],

                    ),

                  ),

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

      ..strokeWidth = 2.5

      ..style = PaintingStyle.stroke

      ..strokeCap = StrokeCap.round;



    final path1 = Path()

      ..moveTo(0, size.height * 0.62)

      ..quadraticBezierTo(

        size.width * 0.45,

        size.height * 0.48,

        size.width,

        size.height * 0.58,

      );

    canvas.drawPath(path1, roadPaint);



    final path2 = Path()

      ..moveTo(size.width * 0.35, 0)

      ..quadraticBezierTo(

        size.width * 0.42,

        size.height * 0.5,

        size.width * 0.38,

        size.height,

      );

    canvas.drawPath(path2, roadPaint);

  }



  @override

  bool shouldRepaint(covariant _MapGridPainter oldDelegate) =>

      oldDelegate.lineColor != lineColor || oldDelegate.fillColor != fillColor;

}


