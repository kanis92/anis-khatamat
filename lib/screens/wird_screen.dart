import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/models/subdivision_marker.dart';
import '../core/models/wird.dart';
import '../core/models/wird_plan_state.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/wird_provider.dart';
import '../core/resolvers/subdivision_definition_resolver.dart';
import '../core/services/hizb_navigation_service.dart';
import '../core/utils/hizb_formatter.dart';
import '../core/widgets/anis_icon.dart';
import '../design_system/anis_design_system.dart';
import '../l10n/gen_l10n/app_localizations.dart';
import 'wird_plan_widgets.dart';

/// Wird — Compagnon de lecture quotidienne du Quran
///
/// Hiérarchie éditoriale premium autour de 3 questions:
/// 1. Qu'ai-je lu aujourd'hui? (Lecture du jour)
/// 2. Quel est mon objectif? (Contexte de l'objectif)
/// 3. Où continuer? (Position de reprise)
///
/// Principes:
/// - Rub' = unité canonique interne (tracking), segmentation discrète (UI)
/// - Langage adapté à l'objectif: 1 Rub', 1/2 Hizb, 1 Hizb, 2 Hizb
/// - Séparation claire: accomplissement TODAY ≠ position RESUME
/// - Émeraude + ivoire, or sobre pour complétion significative
/// - Pas de gamification, gradients, streaks, badges ou fake data
class WirdScreen extends ConsumerWidget {
  const WirdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wirdAsync = ref.watch(wirdProvider);
    final progressAsync = ref.watch(wirdTodayProgressProvider);
    final completedIdsAsync = ref.watch(wirdTodayCompletedRubIdsProvider);

    return Scaffold(
      backgroundColor: context.anisColors.surfaceBase,
      body: wirdAsync.when(
        loading: () => const _WirdLoadingBody(),
        error: (_, __) => const _WirdErrorBody(),
        data: (wird) {
          final progress = progressAsync.valueOrNull ?? 0;
          final completedIds = completedIdsAsync.valueOrNull ?? {};
          return _WirdBody(
            wird: wird,
            todayProgress: progress,
            completedRubIds: completedIds,
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
    required this.completedRubIds,
  });

  final Wird wird;
  final int todayProgress;
  final Set<int> completedRubIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.anisColors;
    final text = context.anisText;

    return FutureBuilder<(int hizb, (int, int)? sequentialPos)>(
      future: _determineCurrentHizbWithPosition(ref, wird),
      builder: (context, snapshot) {
        final currentHizb = snapshot.data?.$1 ?? 1;
        final sequentialPos = snapshot.data?.$2;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Header premium
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.actionPrimary,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AnisSpacing.page,
                      AnisSpacing.md,
                      AnisSpacing.page,
                      AnisSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.wirdMyWird,
                                style: text.sectionTitle.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => showWirdPlanSheet(context, ref),
                              icon: const Icon(
                                Icons.calendar_month_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                              tooltip: l10n.wirdPlanTooltip,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showGoalConfig(context, ref),
                              icon: const Icon(
                                Icons.tune_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                              tooltip: l10n.wirdConfigureTooltip,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Builder(
                          builder: (ctx) {
                            final today = DateTime.now();
                            final formatted = DateFormat(
                              'EEEE d MMMM yyyy',
                              Localizations.localeOf(ctx).toString()
                            ).format(today);
                            return Text(
                              formatted,
                              style: text.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                                letterSpacing: 0.2,
                              ),
                            );
                          },
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
                AnisSpacing.xl,
                AnisSpacing.page,
                AnisSpacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: Consumer(
                  builder: (context, ref, _) {
                    // Objectif autoritaire du jour
                    final targetAsync = ref.watch(wirdTodayAuthoritativeTargetProvider);
                    final target = targetAsync.valueOrNull ?? wird.dailyTargetRubs;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Qu'ai-je lu aujourd'hui?
                        _DailyReadingSection(
                          progress: todayProgress,
                          target: target,
                        ),
                        const SizedBox(height: AnisSpacing.xxl),

                        // 2. Ma Khatma Personnelle (si plan actif)
                        Consumer(
                          builder: (context, ref, _) {
                            final planStateAsync = ref.watch(wirdPlanStateProvider);
                            return planStateAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (state) {
                                if (state == WirdPlanState.none) {
                                  return const SizedBox.shrink();
                                }
                                return const Column(
                                  children: [
                                    WirdPlanCard(),
                                    SizedBox(height: AnisSpacing.xxl),
                                  ],
                                );
                              },
                            );
                          },
                        ),

                        // 3. Où continuer?
                        _ResumePositionSection(
                          wird: wird,
                          currentHizb: currentHizb,
                          sequentialPosition: sequentialPos,
                        ),
                        const SizedBox(height: AnisSpacing.xl),

                        // 4. CTA primaire
                        _ResumeReadingCTA(
                          wird: wird,
                          onPressed: () => _resumeReading(context, ref, wird),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Détermine le Hizb actuel et la position séquentielle si disponible.
  /// 
  /// **Retourne:** (Hizb number, optional (surah, ayah))
  /// 
  /// **Priorité:**
  /// 1. Position séquentielle Quran (surah:ayah) si disponible — la plus précise
  /// 2. Page de reprise (wird.lastPage) sinon — fallback navigation
  Future<(int, (int, int)?)> _determineCurrentHizbWithPosition(WidgetRef ref, Wird wird) async {
    final service = ref.read(wirdServiceProvider);
    final userId = ref.read(currentUserProvider)?.email ?? 'demo';
    
    try {
      final sequentialPos = await service.getLastSequentialQuranPosition(userId);
      
      if (sequentialPos != null) {
        // Utiliser SubdivisionDefinition pour déterminer le Hizb
        final resolver = SubdivisionDefinitionResolver.production();
        final definition = resolver.resolve(wird.subdivisionDefinitionId);
        
        final (surah, ayah) = sequentialPos;
        final marker = definition.getActiveMarkerAt(
          surah,
          ayah,
          granularity: SubdivisionGranularity.rub,
        );
        
        if (marker != null) {
          final hizb = (marker.segmentId ~/ 4) + 1;
          return (hizb.clamp(1, 60), sequentialPos);
        }
      }
    } catch (_) {
      // Fallback sur page si erreur
    }
    
    // Fallback: utiliser lastPage
    final lastPage = wird.lastPage;
    if (lastPage == null || lastPage < 1 || lastPage > 604) {
      return (1, null);
    }
    
    return (HizbNavigationService.displayedHizb(lastPage), null);
  }


  void _showGoalConfig(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
}

// ── Lecture du jour ─────────────────────────────────────────────────────────

/// Section 1: Qu'ai-je lu aujourd'hui?
/// Affiche la progression quotidienne dans l'unité appropriée avec
/// une segmentation discrète (pas de grandes cartes Rub').
class _DailyReadingSection extends StatelessWidget {
  const _DailyReadingSection({
    required this.progress,
    required this.target,
  });

  final int progress;
  final int target;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;
    final l10n = AppLocalizations.of(context)!;
    
    final isComplete = progress >= target && target > 0;
    
    // Déterminer l'unité d'affichage et calculer les fractions exactes
    final showInHizb = target >= 4;
    
    String progressText;
    String targetLabel;
    String? remainingText;
    
    if (showInHizb) {
      progressText = formatRubsAsHizb(progress);
      targetLabel = formatTargetAsHizb(target);
      remainingText = formatRemainingAsHizb(target - progress);
    } else if (target == 2) {
      // Objectif 1/2 Hizb: parler en Rub' mais avec contexte ½ Hizb
      progressText = '$progress';
      targetLabel = '2 Rub\' (½ Hizb)';
      
      if (!isComplete) {
        final remaining = target - progress;
        remainingText = remaining == 1 ? l10n.wirdRemainingOneRub : l10n.wirdRemainingManyRubs(remaining);
      }
    } else {
      // Objectif 1 Rub': explicite
      progressText = '$progress';
      targetLabel = '$target Rub\'';
      
      if (!isComplete) {
        final remaining = target - progress;
        remainingText = remaining == 1 ? l10n.wirdRemainingOneRub : l10n.wirdRemainingManyRubs(remaining);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre section avec signature géométrique islamique subtile
        Row(
          children: [
            Container(
              width: 3,
              height: 24,
              decoration: BoxDecoration(
                color: colors.actionPrimary,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: AnisSpacing.sm),
            Expanded(
              child: Text(
                l10n.wirdDailySectionTitle,
                style: text.sectionTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AnisSpacing.md),
        
        // Carte progression
        AnisSurface(
          level: AnisSurfaceLevel.raised,
          radius: AnisRadius.xl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Objectif label discret
              Text(
                l10n.wirdObjectiveLabel(targetLabel),
                style: text.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AnisSpacing.lg),
              
              if (isComplete) ...[
                // État accompli - compact et raffiné
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AnisSpacing.md,
                    vertical: AnisSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accentGoldStrong.withValues(alpha: 0.08),
                    borderRadius: AnisRadius.lgAll,
                    border: Border.all(
                      color: colors.accentGoldStrong.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colors.accentGoldStrong.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: colors.accentGoldStrong,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: AnisSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.wirdDailyCompleted(targetLabel),
                              style: text.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.accentGoldText,
                                letterSpacing: 0.2,
                              ),
                            ),
                            Text(
                              l10n.completionAlhamdulillah,
                              style: text.caption.copyWith(
                                color: colors.textSecondary,
                                fontStyle: FontStyle.italic,
                                fontSize: 11,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Progression en cours
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      progressText,
                      style: text.titleLarge.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: colors.actionPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ $targetLabel',
                      style: text.title.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AnisSpacing.lg),
                
                // Segmentation discrète (4 segments toujours, échelle interne Rub')
                _DiscreteProgressBar(
                  completed: progress,
                  total: target,
                ),
                
                // Ligne "Il vous reste..." basée sur progression canonique exacte
                if (remainingText != null) ...[
                  const SizedBox(height: AnisSpacing.md),
                  Text(
                    remainingText,
                    style: text.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Barre de progression segmentée discrète
/// Toujours 4 segments visuels (Rub' = unité interne canonique)
/// mais échelle adaptée à l'objectif pour éviter confusion
class _DiscreteProgressBar extends StatelessWidget {
  const _DiscreteProgressBar({
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    
    // Toujours afficher 4 segments (1 Hizb = 4 Rub')
    // Mais l'échelle visuelle s'adapte à l'objectif
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          Expanded(
            child: _ProgressSegment(
              isCompleted: i < (completed.clamp(0, 4)),
              colors: colors,
            ),
          ),
          if (i < 3) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({
    required this.isCompleted,
    required this.colors,
  });

  final bool isCompleted;
  final AnisColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: isCompleted
            ? colors.actionPrimary
            : colors.surfaceElevated,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// ── Position de reprise ──────────────────────────────────────────────────────

/// Section 2: Où continuer?
/// Affiche le contexte de reprise avec Hizb N et métadonnées réelles uniquement.
/// Séparation claire: RESUME ≠ TODAY's accomplishment.
class _ResumePositionSection extends StatelessWidget {
  const _ResumePositionSection({
    required this.wird,
    required this.currentHizb,
    this.sequentialPosition,
  });

  final Wird wird;
  final int currentHizb;
  final (int surah, int ayah)? sequentialPosition;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;
    final l10n = AppLocalizations.of(context)!;
    
    final hasPosition = wird.lastMushafType != null && wird.lastPage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre section
        Text(
          l10n.wirdContinueSectionTitle,
          style: text.sectionTitle.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AnisSpacing.sm),
        Text(
          l10n.wirdContinueSubtitle,
          style: text.caption.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AnisSpacing.md),
        
        // Carte contexte - traitement éditorial
        AnisSurface(
          level: AnisSurfaceLevel.raised,
          radius: AnisRadius.lg,
          child: Row(
            children: [
              // Accent éditorial vertical (inspiration architecture islamique)
              Container(
                width: 4,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.actionPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AnisSpacing.md),
              
              // Métadonnées de reprise
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hizb en contexte éditorial
                    Text(
                      l10n.wirdHizbNumber(currentHizb),
                      style: text.title.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.actionPrimary,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (sequentialPosition != null) ...[
                      // Position précise Sourate:Ayah (universelle, certifiée)
                      Text(
                        l10n.wirdSurahAyah(sequentialPosition!.$1, sequentialPosition!.$2),
                        style: text.label.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                      // Page uniquement pour Hafs (pagination certifiée)
                      if (hasPosition && wird.lastMushafType == 'hafs') ...[
                        const SizedBox(height: 2),
                        Text(
                          l10n.wirdPageNumber(wird.lastPage!),
                          style: text.caption.copyWith(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ] else if (hasPosition) ...[
                      // Sans position séquentielle: contexte de lecture uniquement
                      if (wird.lastMushafType == 'hafs')
                        // Hafs: pagination certifiée
                        Text(
                          l10n.wirdPageNumber(wird.lastPage!),
                          style: text.label.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        // Warsh/Women: contexte
                        Text(
                          l10n.wirdReadingMushaf(_getMushafLabel(context, wird.lastMushafType!)),
                          style: text.label.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ] else
                      Text(
                        l10n.wirdNoReadingInProgress,
                        style: text.label.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMushafLabel(BuildContext context, String mushafType) {
    final l10n = AppLocalizations.of(context)!;
    switch (mushafType) {
      case 'hafs':
        return l10n.mushafHafs;
      case 'warsh':
        return l10n.mushafWarsh;
      case 'women':
        return l10n.mushafWomen;
      default:
        return mushafType;
    }
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
    final l10n = AppLocalizations.of(context)!;
    final hasPosition = wird.lastMushafType != null && wird.lastPage != null;

    return AnisPrimaryButton(
      label: hasPosition ? l10n.wirdResumeReading : l10n.wirdStartReading,
      anisIcon: AnisIconType.bookOpen,
      onPressed: onPressed,
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
    final colors = context.anisColors;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AnisSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  l10n.wirdDailyGoalTitle,
                  style: text.title,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AnisSpacing.xs),
            Text(
              l10n.wirdDailyGoalSubtitle,
              style: text.bodySecondary.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AnisSpacing.xl),
            ...[1, 2, 4, 8].map((rubs) {
              final isSelected = rubs == currentGoal;
              return Padding(
                padding: const EdgeInsets.only(bottom: AnisSpacing.sm),
                child: _GoalOption(
                  rubs: rubs,
                  isSelected: isSelected,
                  onTap: () async {
                    await updateWirdDailyGoal(ref, rubs);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              );
            }),
            const SizedBox(height: AnisSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  const _GoalOption({
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
      borderRadius: AnisRadius.lgAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AnisRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AnisSpacing.lg,
            vertical: AnisSpacing.md,
          ),
          child: Row(
            children: [
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                )
              else
                Icon(
                  Icons.circle_outlined,
                  color: colors.textTertiary,
                  size: 20,
                ),
              const SizedBox(width: AnisSpacing.md),
              Expanded(
                child: Text(
                  Wird.labelForTarget(rubs, (s) => s),
                  style: text.label.copyWith(
                    color: isSelected ? Colors.white : colors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Text(l10n.wirdLoadError),
    );
  }
}
