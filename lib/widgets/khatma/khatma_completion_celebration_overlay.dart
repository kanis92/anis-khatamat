import 'package:flutter/material.dart';

import '../../core/extensions/l10n_extensions.dart';
import '../../core/theme/app_theme.dart';

/// Transition sobre après le 60e Hizb (première clôture uniquement).
class KhatmaCompletionCelebrationOverlay {
  KhatmaCompletionCelebrationOverlay._();

  static Future<void> show(
    BuildContext context, {
    required int completed,
    required int total,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppTheme.darkGreen.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (ctx, _, __) => _CelebrationContent(
        completed: completed,
        total: total,
      ),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

class _CelebrationContent extends StatelessWidget {
  final int completed;
  final int total;

  const _CelebrationContent({
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.completionProgressFraction(completed, total),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                      ),
                  semanticsLabel: l10n.completionProgressFraction(completed, total),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.completionAlhamdulillah,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.completionAccomplished,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.white.withValues(alpha: 0.92),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.completionDua,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.white.withValues(alpha: 0.75),
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
