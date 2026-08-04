import 'package:flutter/material.dart';

/// Revela hijos con fade + scale leve, en cascada (carga natural).
class StaggeredReveal extends StatefulWidget {
  const StaggeredReveal({
    required this.child,
    this.index = 0,
    this.baseDelay = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 420),
    this.beginScale = 0.96,
    super.key,
  });

  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration duration;
  final double beginScale;

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: widget.beginScale, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    final delayMs = widget.baseDelay.inMilliseconds * widget.index;
    Future<void>.delayed(Duration(milliseconds: delayMs.clamp(0, 700)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
