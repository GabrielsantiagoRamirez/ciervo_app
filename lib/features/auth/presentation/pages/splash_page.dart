import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    this.message = 'Ciervo Club',
    this.showRotatingPhrases = true,
    super.key,
  });

  final String message;
  final bool showRotatingPhrases;

  static const rotatingPhrases = <String>[
    'Ciervo, tu mejor opción para entretenerte',
    'Consigue boletos más fácil y rápido',
    'Descubre planes día, noche y 24h',
    'Paga con QR, wallet y cashback Ciervo',
    'Comparte experiencias con tu círculo',
    'Reservas, cine, Move y más en un solo lugar',
  ];

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String? _versionLabel;
  int _phraseIndex = 0;
  Timer? _phraseTimer;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    if (widget.showRotatingPhrases) {
      _phraseTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        setState(() {
          _phraseIndex = (_phraseIndex + 1) % SplashPage.rotatingPhrases.length;
        });
      });
    }
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _versionLabel = 'v${info.version} (${info.buildNumber})');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final phrase = SplashPage.rotatingPhrases[_phraseIndex];
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFF161311), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: CiervoBrandLoader(message: widget.message)),
                    if (widget.showRotatingPhrases)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          0,
                          AppSpacing.xl,
                          AppSpacing.lg,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          child: Text(
                            phrase,
                            key: ValueKey(phrase),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.9,
                                  ),
                                  height: 1.35,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_versionLabel != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Text(
                    _versionLabel!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.72),
                      letterSpacing: 0.6,
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
