import 'package:flutter/material.dart';

import '../anis_theme.dart';
import '../tokens/anis_geometry.dart';
import '../tokens/anis_motion.dart';

/// Bloc de chargement.
///
/// Un seul `AnimationController` par écran, porté par [AnisSkeletonGroup], au
/// lieu d'un contrôleur par bloc. Le battement s'arrête quand l'utilisateur a
/// demandé la réduction des animations : la forme reste, le mouvement disparaît.
class AnisSkeleton extends StatelessWidget {
  const AnisSkeleton({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.radius = AnisRadius.lg,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final pulse = _AnisSkeletonPulse.maybeOf(context)?.value ?? 0;

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Color.lerp(colors.surfaceSunken, colors.surfaceSoft, pulse),
      ),
    );
  }
}

/// Fournit le battement partagé aux [AnisSkeleton] descendants.
class AnisSkeletonGroup extends StatefulWidget {
  const AnisSkeletonGroup({super.key, required this.child});

  final Widget child;

  @override
  State<AnisSkeletonGroup> createState() => _AnisSkeletonGroupState();
}

class _AnisSkeletonGroupState extends State<AnisSkeletonGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AnisMotion.isReduced(context)) {
      _controller.stop();
      _controller.value = 0.4;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => _AnisSkeletonPulse(
        value: _controller.value,
        child: child!,
      ),
      child: widget.child,
    );
  }
}

class _AnisSkeletonPulse extends InheritedWidget {
  const _AnisSkeletonPulse({required this.value, required super.child});

  final double value;

  static _AnisSkeletonPulse? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AnisSkeletonPulse>();

  @override
  bool updateShouldNotify(_AnisSkeletonPulse old) => old.value != value;
}
