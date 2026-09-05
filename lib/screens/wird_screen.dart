import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../core/models/subdivision_marker.dart';
import '../core/models/wird.dart';
import '../core/models/wird_plan_state.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/wird_provider.dart';
import '../core/resolvers/subdivision_definition_resolver.dart';
import '../core/services/hizb_navigation_service.dart';
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
                        const SizedBox(height: AnisSpacing.xl),

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
                                return Column(
                                  children: [
                                    _MonthlyKhatmaCard(wird: wird),
                                    const SizedBox(height: AnisSpacing.xl),
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
                        const SizedBox(height: AnisSpacing.lg),

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

/// Décompose un nombre de Rub' en Hizb entiers + quarts résiduels.
/// 
/// Exemple: 9 Rub' = (2 Hizb entiers, 1 quart)
///          10 Rub' = (2 Hizb entiers, 2 quarts)
///          8 Rub' = (2 Hizb entiers, 0 quarts)
(int wholeHizb, int quarters) _rubsToHizbAndQuarters(int rubs) {
  final wholeHizb = rubs ~/ 4;
  final quarters = rubs % 4;
  return (wholeHizb, quarters);
}

/// Section 1: Qu'ai-je lu aujourd'hui?
/// 
/// UX Model:
/// - Objectif PRIMAIRE en Hizb entiers (pas de fractions géantes)
/// - Quarts résiduels SECONDAIRES si nécessaires
/// - Progression simple et lisible
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
    
    // Décomposer l'objectif en Hizb entiers + quarts
    final (targetWholeHizb, targetQuarters) = _rubsToHizbAndQuarters(target);
    final (progressWholeHizb, progressQuarters) = _rubsToHizbAndQuarters(progress);
    
    // Label primaire: Hizb entiers
    final String primaryObjective;
    if (targetWholeHizb > 0) {
      primaryObjective = '$targetWholeHizb ${l10n.wirdHizbUnit}';
    } else {
      // Rare: objectif < 1 Hizb, utiliser Rub' explicitement
      primaryObjective = '$target Rub\'';
    }
    
    // Label secondaire: quarts supplémentaires si fractionnaire
    final String? secondaryObjective = targetQuarters > 0
        ? (targetQuarters == 1
            ? l10n.wirdPlusQuarterNext(1)
            : l10n.wirdPlusQuartersNext(targetQuarters))
        : null;
    
    // Modèle sémantique de progression (pas de fractions)
    final String? progressLabel;
    final String? progressSubLabel;
    
    if (isComplete) {
      progressLabel = null; // Handled separately below
      progressSubLabel = null;
    } else if (progressWholeHizb > 0) {
      // Au moins 1 Hizb terminé
      progressLabel = progressWholeHizb == 1
          ? l10n.wirdHizbCompleted_one
          : l10n.wirdHizbCompleted_other(progressWholeHizb);
      // Si des quarts dans le Hizb suivant
      progressSubLabel = progressQuarters > 0 ? l10n.wirdNextHizbInProgress : null;
    } else if (progressQuarters > 0) {
      // Moins d'1 Hizb, mais progression en cours
      progressLabel = l10n.wirdNextHizbInProgress;
      progressSubLabel = null;
    } else {
      // Aucune progression
      progressLabel = null;
      progressSubLabel = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre section
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
              // Label "Objectif aujourd'hui"
              Text(
                l10n.wirdTodayObjective,
                style: text.caption.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AnisSpacing.xs),
              
              // Objectif primaire (Hizb entiers)
              Text(
                primaryObjective,
                style: text.titleLarge.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.actionPrimary,
                  height: 1.2,
                ),
              ),
              
              // Objectif secondaire (quarts si applicable)
              if (secondaryObjective != null) ...[
                const SizedBox(height: 4),
                Text(
                  secondaryObjective,
                  style: text.caption.copyWith(
                    color: colors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              const SizedBox(height: AnisSpacing.md),
              
              if (isComplete) ...[
                // État accompli - compact
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
                              l10n.wirdDailyCompleted(primaryObjective),
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
                // Progression en cours - modèle sémantique
                if (progressLabel != null) ...[
                  Text(
                    progressLabel,
                    style: text.label.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.actionPrimary,
                    ),
                  ),
                  if (progressSubLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      progressSubLabel,
                      style: text.caption.copyWith(
                        color: colors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: AnisSpacing.md),
                ],
                
                // Barre de progression exacte (ratio canonique)
                _ContinuousProgressBar(
                  completed: progress,
                  total: target,
                  colors: colors,
                ),
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
// ── Barre de progression continue ────────────────────────────────────────────

/// Barre de progression continue représentant exactement le ratio canonique.
/// 
/// Exemple: 7 / 9 Rub' = 77.78% de progression exacte.
/// Pas de segments fixes, pas de fausse complétion.
class _ContinuousProgressBar extends StatelessWidget {
  const _ContinuousProgressBar({
    required this.completed,
    required this.total,
    required this.colors,
  });

  final int completed;
  final int total;
  final AnisColors colors;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.actionPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Khatma personnelle mensuelle ─────────────────────────────────────────────

/// Carte "Ma Khatma personnelle" avec ring de progression premium.
/// 
/// Affiche la progression MENSUELLE TOTALE (pas juste TODAY).
/// Ring basé sur la progression exacte en Rub' (canonique / 240).
/// Affichage simplifié: Hizb entiers complétés ou pourcentage.
class _MonthlyKhatmaCard extends ConsumerWidget {
  const _MonthlyKhatmaCard({required this.wird});
  
  final Wird wird;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.anisColors;
    final text = context.anisText;
    final l10n = AppLocalizations.of(context)!;
    
    final plan = wird.activePlan;
    if (plan == null) return const SizedBox.shrink();
    
    // Progression du cycle Khatma actuel (pas seulement depuis plan)
    final progressAsync = ref.watch(wirdCycleProgressProvider);
    
    return progressAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (completedRubIds) {
        final cycleCompleted = completedRubIds.length;
        
        // Pourcentage entier (floor) de la Khatma
        final percentComplete = ((cycleCompleted / 240) * 100).floor();
        
        // Calculer jours restants
        final now = DateTime.now();
        final endDate = plan.endDate;
        final daysRemaining = endDate != null 
            ? endDate.difference(now).inDays.clamp(0, 999)
            : 0;
        
        // Déterminer le mois
        final monthName = endDate != null
            ? DateFormat.MMMM(Localizations.localeOf(context).toString()).format(endDate)
            : '';
        
        // Hizb entiers complétés
        final completedHizb = (cycleCompleted / 4).floor();
        
        return AnisSurface(
          level: AnisSurfaceLevel.raised,
          radius: AnisRadius.xl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Titre
              Text(
                l10n.wirdPersonalKhatma,
                style: text.sectionTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              
              if (monthName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  monthName,
                  style: text.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
              
              const SizedBox(height: AnisSpacing.md),
              
              // Ring de progression premium avec % au centre
              Center(
                child: SizedBox(
                  width: 145,
                  height: 145,
                  child: _MonthlyRingWithPercentage(
                    completedRubs: cycleCompleted,
                    totalRubs: 240,
                    percentComplete: percentComplete,
                  ),
                ),
              ),
              
              const SizedBox(height: AnisSpacing.md),
              
              // Contexte stable en-dessous
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    completedHizb > 0
                        ? (completedHizb == 1
                            ? l10n.wirdHizbCompletedOutOf(completedHizb, 60)
                            : l10n.wirdHizbCompletedOutOf_other(completedHizb, 60))
                        : l10n.wirdKhatmaInProgress,
                    style: text.label.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  if (daysRemaining > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.wirdDaysRemaining(daysRemaining),
                      style: text.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Ring de progression avec pourcentage stable au centre.
class _MonthlyRingWithPercentage extends StatelessWidget {
  const _MonthlyRingWithPercentage({
    required this.completedRubs,
    required this.totalRubs,
    required this.percentComplete,
  });

  final int completedRubs;
  final int totalRubs;
  final int percentComplete;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;
    final l10n = AppLocalizations.of(context)!;
    
    final progress = totalRubs > 0 ? completedRubs / totalRubs : 0.0;
    
    return CustomPaint(
      size: const Size(160, 160),
      painter: _MonthlyRingPainter(
        progress: progress,
        primaryColor: colors.actionPrimary,
        accentColor: colors.accentGoldStrong,
        trackColor: colors.surfaceElevated,
      ),
      child: SizedBox(
        width: 160,
        height: 160,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentComplete%',
                style: text.titleLarge.copyWith(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: colors.actionPrimary,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.wirdOfMyKhatma,
                style: text.caption.copyWith(
                  fontSize: 12,
                  color: colors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
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
        const SizedBox(height: AnisSpacing.xs),
        Text(
          l10n.wirdContinueSubtitle,
          style: text.caption.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AnisSpacing.sm),
        
        // Carte contexte - traitement éditorial
        AnisSurface(
          level: AnisSurfaceLevel.raised,
          radius: AnisRadius.lg,
          child: Row(
            children: [
              // Accent éditorial vertical (inspiration architecture islamique)
              Container(
                width: 4,
                height: 52,
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

// ── Monthly Ring Painter ─────────────────────────────────────────────────────

/// CustomPainter pour le ring de progression mensuelle premium.
/// 
/// Architecture en layers pour effet LED lumineux:
/// 1. Dormant 360° body (toujours visible)
/// 2. Progress outer bloom (derrière l'arc complété)
/// 3. Progress luminous body (arc principal riche)
/// 4. Inner light core (highlight crisp intérieur)
/// 5. Optional gold refinement (endpoint si >5%)
class _MonthlyRingPainter extends CustomPainter {
  _MonthlyRingPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
    required this.trackColor,
  });

  final double progress;
  final Color primaryColor;
  final Color accentColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 10.0;
    final startAngle = -math.pi / 2;

    // ══════════════════════════════════════════════════════════════════════
    // A. DORMANT 360° BODY — CERCLE COMPLET (richer emerald base)
    // ══════════════════════════════════════════════════════════════════════
    
    // Émeraude désaturé/sombre plus riche (plus de primaryColor, moins de trackColor)
    final dormantBase = Color.lerp(trackColor, primaryColor, 0.35)!;
    
    // Outer edge
    final dormantOuterPaint = Paint()
      ..color = dormantBase.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 1.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);

    canvas.drawCircle(center, radius - strokeWidth / 2, dormantOuterPaint);

    // Dormant body principal (plus d'opacité pour richer appearance)
    final dormantPaint = Paint()
      ..color = dormantBase.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, dormantPaint);

    // Inner edge
    final dormantInnerPaint = Paint()
      ..color = dormantBase.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.4
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, dormantInnerPaint);

    // ══════════════════════════════════════════════════════════════════════
    // B-D. PROGRESS ARC ILLUMINÉ — UNE BANDE LUMINEUSE UNIFIÉE
    // ══════════════════════════════════════════════════════════════════════
    
    if (progress > 0) {
      final sweepAngle = math.pi * 2 * progress;
      final arcRect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

      // ────────────────────────────────────────────────────────────────────
      // B. OUTER BLOOM — Lumière émise (tightened)
      // ────────────────────────────────────────────────────────────────────
      
      final outerBloomPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawArc(arcRect, startAngle, sweepAngle, false, outerBloomPaint);

      final innerBloomPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawArc(arcRect, startAngle, sweepAngle, false, innerBloomPaint);

      // ────────────────────────────────────────────────────────────────────
      // C. LUMINOUS BODY — Bande principale avec gradient intégré
      // ────────────────────────────────────────────────────────────────────
      
      // Gradient radial from edges (darker) to center (brighter)
      // Créer impression de lumière intérieure sans second stroke séparé
      final darkerEmerald = Color.lerp(primaryColor, Colors.black, 0.15)!;
      final richEmerald = primaryColor;
      final brightEmerald = Color.lerp(primaryColor, const Color(0xFF10B981), 0.25)!;
      
      // Body avec gradient pour effet de profondeur lumineux
      final luminousBodyPaint = Paint()
        ..shader = LinearGradient(
          colors: [darkerEmerald, richEmerald, brightEmerald],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(arcRect, startAngle, sweepAngle, false, luminousBodyPaint);

      // ────────────────────────────────────────────────────────────────────
      // D. SUBTLE INNER HIGHLIGHT — Narrow, soft, integrated
      // ────────────────────────────────────────────────────────────────────
      
      // Highlight très subtil au centre de la bande (pas un contour séparé)
      final subtleHighlightPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawArc(arcRect, startAngle, sweepAngle, false, subtleHighlightPaint);

      // ────────────────────────────────────────────────────────────────────
      // E. GOLD ENDPOINT — Extremely subtle, skip at very low progress
      // ────────────────────────────────────────────────────────────────────
      
      if (progress > 0.08) { // Only show gold after 8% to avoid distraction at 2%
        final endAngle = startAngle + sweepAngle;
        final endpointCenter = Offset(
          center.dx + (radius - strokeWidth / 2) * math.cos(endAngle),
          center.dy + (radius - strokeWidth / 2) * math.sin(endAngle),
        );

        // Gold glow minimal
        final goldGlowPaint = Paint()
          ..color = accentColor.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        canvas.drawCircle(endpointCenter, 3, goldGlowPaint);

        // Gold point très petit
        final goldPointPaint = Paint()
          ..color = accentColor.withValues(alpha: 0.7)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(endpointCenter, 1, goldPointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.trackColor != trackColor;
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
