import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Grille 60/60 — visualisation sobre de complétude (réutilisable pour carte partageable).
class KhatmaCompletionHizbGrid extends StatefulWidget {
  final bool animate;

  const KhatmaCompletionHizbGrid({
    super.key,
    this.animate = false,
  });

  @override
  State<KhatmaCompletionHizbGrid> createState() =>
      _KhatmaCompletionHizbGridState();
}

class _KhatmaCompletionHizbGridState extends State<KhatmaCompletionHizbGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${AppConstants.totalHizb} Hizb accomplis',
      child: FadeTransition(
        opacity: _fade,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: AppConstants.totalHizb,
          itemBuilder: (context, index) {
            final n = index + 1;
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.35),
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: AppTheme.primaryGreen.withValues(alpha: 0.9),
                    semanticLabel: 'Hizb $n terminé',
                  ),
                  Text(
                    '$n',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGreen.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
