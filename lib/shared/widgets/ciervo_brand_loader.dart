// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

class CiervoBrandLoader extends StatefulWidget {
  const CiervoBrandLoader({
    super.key,
    this.message = 'Preparando tu experiencia',
    this.compact = false,
  });

  final String message;
  final bool compact;

  @override
  State<CiervoBrandLoader> createState() => _CiervoBrandLoaderState();
}

class _CiervoBrandLoaderState extends State<CiervoBrandLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _glow = Tween<double>(begin: 0.22, end: 0.56).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxHeight.isFinite && constraints.maxHeight < 150;
        final effectiveCompact = widget.compact || tight;
        final size = tight ? 54.0 : (effectiveCompact ? 72.0 : 122.0);
        final showMessage = !tight || constraints.maxHeight > 96;
        return Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: _pulse.value,
                    child: Container(
                      width: size,
                      height: size,
                      padding: EdgeInsets.all(tight ? 4 : AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.62),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(_glow.value),
                            blurRadius: effectiveCompact ? 18 : 38,
                            spreadRadius: effectiveCompact ? 1 : 3,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        child: Image.asset(
                          'assets/icon/icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  if (showMessage) ...[
                    SizedBox(height: tight ? AppSpacing.xs : AppSpacing.md),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            letterSpacing: 0.4,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  SizedBox(
                    width: effectiveCompact ? 88 : 132,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: AppColors.primary.withOpacity(0.18),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
