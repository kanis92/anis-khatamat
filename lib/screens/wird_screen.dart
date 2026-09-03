import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/wird.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/wird_provider.dart';
import '../core/widgets/anis_icon.dart';
import '../design_system/anis_design_system.dart';

/// Wird V1 — Pratique personnelle quotidienne du Coran
///
/// Minimal foundation:
/// - objectif quotidien
/// - progression du jour
/// - CTA "Reprendre ma lecture"
/// - continuité 7 jours
/// - configuration rapide
class WirdScreen extends ConsumerWidget {
  const WirdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wirdAsync = ref.watch(wirdProvider);
    final progressAsync = ref.watch(wirdTodayProgressProvider);
    final continuityAsync = ref.watch(wirdContinuityProvider);

    return Scaffold(
      backgroundColor: context.anisColors.surfaceBase,
      body: wirdAsync.when(
        loading: () => const _WirdLoadingBody(),
        error: (_, __) => const _WirdErrorBody(),
        data: (wird) {
          final progress = progressAsync.valueOrNull ?? 0;
          final continuity = continuityAsync.valueOrNull ?? 0;
          return _WirdBody(
            wird: wird,
            todayProgress: progress,
            continuity: continuity,
          );
        },
      ),
    );
  }
}

class _WirdBody extends ConsumerWidget {
  const _WirdBody({
    required this.wird,
    required this.todayProgress,
    required this.continuity,
  });

  final Wird wird;
  final int todayProgress;
  final int continuity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.anisColors;
    final text = context.anisText;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // Hero Wird
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.actionPrimary,
                  colors.actionPrimary.withValues(alpha: 0.85),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AnisSpacing.page,
                  AnisSpacing.md,
                  AnisSpacing.page,
                  AnisSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnisIcon(
                          type: AnisIconType.bookOpen,
                          size: AnisIconSize.lg,
                          color: Colors.white,
                        ),
                        const SizedBox(width: AnisSpacing.sm),
                        Text(
                          'Mon Wird',
                          style: text.sectionTitle.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _showGoalConfig(context, ref),
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Colors.white,
                          ),
                          tooltip: 'Configurer objectif',
                        ),
                      ],
                    ),
                    const SizedBox(height: AnisSpacing.xl),
                    Text(
                      'Objectif du jour',
                      style: text.bodySecondary.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: AnisSpacing.xs),
                    Text(
                      Wird.labelForTarget(wird.dailyTargetRubs, (s) => s),
                      style: text.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Contenu principal
        SliverPadding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AnisSpacing.page,
            AnisSpacing.lg,
            AnisSpacing.page,
            AnisSpacing.page + kBottomNavigationBarHeight,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progression aujourd'hui
                  _ProgressCard(
                  progress: todayProgress,
                  target: wird.dailyTargetRubs,
                ),
                const SizedBox(height: AnisSpacing.blockGap),

                // CTA Reprendre lecture
                _ResumeReadingCTA(
                  wird: wird,
                  onPressed: () => _resumeReading(context, ref, wird),
                ),
                const SizedBox(height: AnisSpacing.blockGap),

                // Continuité 7 jours
                _ContinuityCard(
                  activeDays: continuity,
                  hasReadToday: _hasReadToday(wird),
                ),
                const SizedBox(height: AnisSpacing.blockGap),

                // Guide rapide
                _QuickGuideCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showGoalConfig(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _GoalConfigSheet(currentGoal: wird.dailyTargetRubs),
    );
  }

  void _resumeReading(BuildContext context, WidgetRef ref, Wird wird) async {
    final service = ref.read(wirdServiceProvider);
    final position = await service.getLastPosition(ref.read(currentUserProvider)?.email ?? 'demo');

    if (position != null && context.mounted) {
      // Reprendre à la dernière position
      context.push('/mushaf/${position.type}', extra: {
        'resumePage': position.page,
      });
    } else if (context.mounted) {
      // Première lecture: ouvrir sélection Mushaf
      context.push('/mushaf');
    }
  }

  bool _hasReadToday(Wird wird) {
    if (wird.lastReadAt == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastRead = DateTime(
      wird.lastReadAt!.year,
      wird.lastReadAt!.month,
      wird.lastReadAt!.day,
    );
    return today == lastRead;
  }
}

// ── Progression Card ─────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progress,
    required this.target,
  });

  final int progress;
  final int target;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;
    final fraction = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

    return AnisSurface(
      level: AnisSurfaceLevel.raised,
      radius: AnisRadius.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progression aujourd\'hui', style: text.sectionTitle),
          const SizedBox(height: AnisSpacing.lg),
          Row(
            children: [
              AnisProgressRing(
                value: fraction,
                centerLabel: '$progress/$target',
                semanticLabel: 'Progression: $progress sur $target Rub\'',
              ),
              const SizedBox(width: AnisSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$progress Rub\'',
                      style: text.title,
                    ),
                    const SizedBox(height: AnisSpacing.xs),
                    Text(
                      target > progress
                          ? 'Encore ${target - progress} Rub\''
                          : '✓ Objectif atteint !',
                      style: text.bodySecondary.copyWith(
                        color: target > progress
                            ? colors.textSecondary
                            : colors.actionPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── CTA Reprendre lecture ────────────────────────────────────────────────────

class _ResumeReadingCTA extends ConsumerWidget {
  const _ResumeReadingCTA({
    required this.wird,
    required this.onPressed,
  });

  final Wird wird;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pour V2, on vérifie lastMushafType et lastPage
    final hasPosition = wird.lastMushafType != null && wird.lastPage != null;

    return AnisPrimaryButton(
      label: hasPosition ? 'Reprendre ma lecture' : 'Commencer ma lecture',
      anisIcon: AnisIconType.bookOpen,
      onPressed: onPressed,
    );
  }
}

// ── Continuité Card ──────────────────────────────────────────────────────────

class _ContinuityCard extends StatelessWidget {
  const _ContinuityCard({
    required this.activeDays,
    required this.hasReadToday,
  });

  final int activeDays;
  final bool hasReadToday;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;

    return AnisSurface(
      level: AnisSurfaceLevel.subtle,
      radius: AnisRadius.lg,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasReadToday
                  ? colors.accentGoldStrong.withValues(alpha: 0.15)
                  : colors.textTertiary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              hasReadToday ? '🔥' : '⏳',
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: AnisSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continuité 7 jours',
                  style: text.label,
                ),
                const SizedBox(height: AnisSpacing.xxs),
                Text(
                  '$activeDays jours actifs',
                  style: text.bodySecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Guide rapide ─────────────────────────────────────────────────────────────

class _QuickGuideCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;

    return AnisSurface(
      level: AnisSurfaceLevel.subtle,
      radius: AnisRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: colors.accentGoldText,
                size: 20,
              ),
              const SizedBox(width: AnisSpacing.xs),
              Text('Guide rapide', style: text.label),
            ],
          ),
          const SizedBox(height: AnisSpacing.sm),
          Text(
            '• Appuyez sur "Reprendre" pour continuer votre lecture\n'
            '• Votre position est sauvegardée automatiquement\n'
            '• Configurez votre objectif quotidien (icône ⚙️)',
            style: text.caption,
          ),
        ],
      ),
    );
  }
}

// ── Configuration objectif ───────────────────────────────────────────────────

class _GoalConfigSheet extends ConsumerWidget {
  const _GoalConfigSheet({required this.currentGoal});

  final int currentGoal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.anisText;

    return Container(
      padding: const EdgeInsets.all(AnisSpacing.page),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Objectif quotidien',
            style: text.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AnisSpacing.lg),
          Wrap(
            spacing: AnisSpacing.sm,
            runSpacing: AnisSpacing.sm,
            alignment: WrapAlignment.center,
            children: [1, 2, 4, 8].map((rubs) {
              final isSelected = rubs == currentGoal;
              return _GoalChip(
                rubs: rubs,
                isSelected: isSelected,
                onTap: () async {
                  await updateWirdDailyGoal(ref, rubs);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AnisSpacing.lg),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.rubs,
    required this.isSelected,
    required this.onTap,
  });

  final int rubs;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;

    return Material(
      color: isSelected ? colors.actionPrimary : colors.surfaceElevated,
      borderRadius: AnisRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AnisRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AnisSpacing.lg,
            vertical: AnisSpacing.md,
          ),
          child: Text(
            Wird.labelForTarget(rubs, (s) => s),
            style: text.label.copyWith(
              color: isSelected ? Colors.white : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── États ────────────────────────────────────────────────────────────────────

class _WirdLoadingBody extends StatelessWidget {
  const _WirdLoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _WirdErrorBody extends StatelessWidget {
  const _WirdErrorBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Impossible de charger votre Wird'),
    );
  }
}
