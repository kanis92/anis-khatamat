import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri_date_time/hijri_date_time.dart';

import '../core/models/wird_plan.dart';
import '../core/models/wird_plan_state.dart';
import '../core/providers/wird_provider.dart';
import '../core/services/wird_plan_service.dart';
import '../core/utils/hizb_formatter.dart';
import '../core/utils/quran_reading_formatter.dart';
import '../design_system/anis_design_system.dart';
import '../l10n/gen_l10n/app_localizations.dart';

/// Bottom sheet pour créer ou modifier un plan personnel de Khatma.
///
/// Options proposées :
/// 1. Objectif quotidien libre (aucun plan)
/// 2. 1 Khatma / mois hégirien
/// 3. 1 Khatma / mois grégorien
///
/// Pour chaque plan mensuel, l'utilisateur choisit :
/// - Commencer maintenant (reste du mois en cours)
/// - Commencer le prochain mois (1er jour du mois suivant)
void showWirdPlanSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.anisColors.surfaceBase,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AnisRadius.lg),
      ),
    ),
    builder: (context) => const _WirdPlanSheet(),
  );
}

class _WirdPlanSheet extends ConsumerStatefulWidget {
  const _WirdPlanSheet();

  @override
  ConsumerState<_WirdPlanSheet> createState() => _WirdPlanSheetState();
}

class _WirdPlanSheetState extends ConsumerState<_WirdPlanSheet> {
  WirdPlanType? _selectedType;
  bool _startNextMonth = false;
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AnisSpacing.page,
          right: AnisSpacing.page,
          top: AnisSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AnisSpacing.page,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Text(
                l10n.readingPlanTitle,
                style: text.sectionTitle.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AnisSpacing.md),
              
              // Options
              _buildOptionTile(
                context,
                type: null,
                title: l10n.readingPlanFreeGoalTitle,
                subtitle: l10n.readingPlanFreeGoalSubtitle,
              ),
              const SizedBox(height: AnisSpacing.sm),
              _buildOptionTile(
                context,
                type: WirdPlanType.hijriMonth,
                title: l10n.readingPlanHijriMonthTitle,
                subtitle: l10n.readingPlanHijriMonthSubtitle,
              ),
              const SizedBox(height: AnisSpacing.sm),
              _buildOptionTile(
                context,
                type: WirdPlanType.gregorianMonth,
                title: l10n.readingPlanGregorianMonthTitle,
                subtitle: l10n.readingPlanGregorianMonthSubtitle,
              ),
              
              // Timing choice (for monthly plans)
              if (_selectedType != null) ...[
                const SizedBox(height: AnisSpacing.lg),
                Text(
                  l10n.readingPlanStartingLabel,
                  style: text.label.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: AnisSpacing.sm),
                _buildTimingOption(
                  context,
                  startNext: false,
                  label: l10n.readingPlanStartNowLabel,
                  description: _getStartNowDescription(),
                ),
                const SizedBox(height: AnisSpacing.xs),
                _buildTimingOption(
                  context,
                  startNext: true,
                  label: l10n.readingPlanStartNextLabel,
                  description: _getStartNextDescription(),
                ),
                
                // Preview
                const SizedBox(height: AnisSpacing.lg),
                _buildPlanPreview(context),
              ],
              
              const SizedBox(height: AnisSpacing.lg),
              
              // Confirm button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _confirmSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.actionPrimary,
                    foregroundColor: colors.textOnAction,
                    elevation: 0,
                    disabledBackgroundColor: colors.actionDisabledSurface,
                    disabledForegroundColor: colors.actionDisabledText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AnisRadius.md),
                    ),
                  ),
                  child: _isCreating
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(colors.textOnAction),
                          ),
                        )
                      : Text(
                          _selectedType == null
                              ? l10n.readingPlanActivateFreeGoal
                              : l10n.readingPlanCreatePlan,
                          style: text.label.copyWith(color: colors.textOnAction),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required WirdPlanType? type,
    required String title,
    required String subtitle,
  }) {
    final colors = context.anisColors;
    final text = context.anisText;
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() {
        _selectedType = type;
        _startNextMonth = false;
      }),
      borderRadius: BorderRadius.circular(AnisRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AnisSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? colors.surfaceSoft : colors.surfaceElevated,
          border: Border.all(
            color: isSelected ? colors.actionPrimary : colors.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AnisRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? colors.actionPrimary : colors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AnisSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.body.copyWith(
                      color: colors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: text.bodySecondary.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingOption(
    BuildContext context, {
    required bool startNext,
    required String label,
    required String description,
  }) {
    final colors = context.anisColors;
    final text = context.anisText;
    final isSelected = _startNextMonth == startNext;

    return InkWell(
      onTap: () => setState(() => _startNextMonth = startNext),
      borderRadius: BorderRadius.circular(AnisRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AnisSpacing.md,
          vertical: AnisSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.surfaceSoft : colors.surfaceElevated,
          border: Border.all(
            color: isSelected ? colors.actionPrimary : colors.borderSubtle,
          ),
          borderRadius: BorderRadius.circular(AnisRadius.sm),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? colors.actionPrimary : colors.textTertiary,
              size: 18,
            ),
            const SizedBox(width: AnisSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: text.body.copyWith(
                      color: colors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    description,
                    style: text.caption.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanPreview(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;
    final l10n = AppLocalizations.of(context)!;
    final summary = _calculatePlanSummary();
    
    if (summary == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AnisSpacing.md),
      decoration: BoxDecoration(
        color: colors.noticeSurface,
        border: Border.all(color: colors.noticeBorder),
        borderRadius: BorderRadius.circular(AnisRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.readingPlanPreviewTitle,
            style: text.label.copyWith(color: colors.noticeText),
          ),
          const SizedBox(height: AnisSpacing.sm),
          _buildPreviewRow(
            context,
            l10n.readingPlanPreviewPeriod,
            summary.period,
          ),
          _buildPreviewRow(
            context,
            l10n.readingPlanPreviewReadingDays,
            l10n.readingPlanPreviewReadingDaysValue(summary.days),
          ),
          _buildPreviewRow(
            context,
            l10n.readingPlanPreviewPace,
            summary.pace,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(BuildContext context, String label, String value) {
    final colors = context.anisColors;
    final text = context.anisText;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: text.caption.copyWith(color: colors.textSecondary)),
          Text(
            value,
            style: text.caption.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getStartNowDescription() {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedType == WirdPlanType.hijriMonth) {
      final hijri = HijriDateTime.now();
      return l10n.readingPlanStartNowHijriDescription(_getHijriMonthName(hijri.month));
    } else if (_selectedType == WirdPlanType.gregorianMonth) {
      final now = DateTime.now();
      final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day + 1;
      return l10n.readingPlanStartNowGregorianDescription(daysLeft);
    }
    return '';
  }

  String _getStartNextDescription() {
    if (_selectedType == WirdPlanType.hijriMonth) {
      final hijri = HijriDateTime.now();
      final nextMonth = hijri.month == 12 ? 1 : hijri.month + 1;
      return '1er ${_getHijriMonthName(nextMonth)}';
    } else if (_selectedType == WirdPlanType.gregorianMonth) {
      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      return '1er ${_getGregorianMonthName(nextMonth.month)}';
    }
    return '';
  }

  _PlanSummary? _calculatePlanSummary() {
    if (_selectedType == null) return null;

    final planService = WirdPlanService();
    final now = DateTime.now();
    
    WirdPlan plan;
    if (_selectedType == WirdPlanType.hijriMonth) {
      plan = planService.createHijriMonthPlan(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        startGregorian: now,
        startNextMonth: _startNextMonth,
      );
    } else {
      plan = planService.createGregorianMonthPlan(
        subdivisionDefinitionId: 'hafs_quran_foundation_rub_240_v1',
        startGregorian: now,
        startNextMonth: _startNextMonth,
      );
    }

    final days = planService.calculateRemainingDays(
      plan,
      plan.baselineDate.add(const Duration(days: 1)),
    );
    final rubsPerDay = (240 / days).ceil();
    final locale = Localizations.localeOf(context).languageCode;
    final pace = formatDailyPace(rubsPerDay, locale);

    String period;
    if (_selectedType == WirdPlanType.hijriMonth) {
      final hijriStart = HijriDateTime.fromGregorian(
        plan.baselineDate.add(const Duration(days: 1)),
      );
      final hijriEnd = HijriDateTime.fromGregorian(plan.endDate!);
      period = '${hijriStart.day} ${_getHijriMonthName(hijriStart.month)} - '
          '${hijriEnd.day} ${_getHijriMonthName(hijriEnd.month)}';
    } else {
      final start = plan.baselineDate.add(const Duration(days: 1));
      final end = plan.endDate!;
      period = '${start.day} ${_getGregorianMonthName(start.month)} - '
          '${end.day} ${_getGregorianMonthName(end.month)}';
    }

    return _PlanSummary(period: period, days: days, pace: pace);
  }

  Future<void> _confirmSelection() async {
    setState(() => _isCreating = true);

    try {
      if (_selectedType == null) {
        // Clear active plan (return to free daily mode)
        await clearWirdPlan(ref);
      } else {
        // Create and activate plan
        final planService = ref.read(wirdPlanServiceProvider);
        final wird = await ref.read(wirdProvider.future);
        final now = DateTime.now();

        WirdPlan plan;
        if (_selectedType == WirdPlanType.hijriMonth) {
          plan = planService.createHijriMonthPlan(
            subdivisionDefinitionId: wird.subdivisionDefinitionId,
            startGregorian: now,
            startNextMonth: _startNextMonth,
          );
        } else {
          plan = planService.createGregorianMonthPlan(
            subdivisionDefinitionId: wird.subdivisionDefinitionId,
            startGregorian: now,
            startNextMonth: _startNextMonth,
          );
        }

        await activateWirdPlan(ref, plan);
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: context.anisColors.dangerSurface,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  String _getHijriMonthName(int month) {
    const names = [
      'Muharram', 'Safar', 'Rabi\' al-awwal', 'Rabi\' al-thani',
      'Jumada al-awwal', 'Jumada al-thani', 'Rajab', 'Sha\'ban',
      'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah'
    ];
    return names[month - 1];
  }

  String _getGregorianMonthName(int month) {
    const names = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return names[month - 1];
  }
}

class _PlanSummary {
  final String period;
  final int days;
  final String pace;

  _PlanSummary({
    required this.period,
    required this.days,
    required this.pace,
  });
}

/// Widget compact affichant le plan personnel actif dans le WirdScreen.
///
/// Affiche :
/// - Identité du cycle (mois hijri/grégorien)
/// - Progression globale
/// - Jours restants
/// - Allocation recommandée aujourd'hui
/// - Badge d'état si scheduled/completed/expired
class WirdPlanCard extends ConsumerWidget {
  const WirdPlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.anisColors;
    final text = context.anisText;

    final wirdAsync = ref.watch(wirdProvider);
    final stateAsync = ref.watch(wirdPlanStateProvider);
    final progressAsync = ref.watch(wirdPlanProgressProvider);
    final remainingRubsAsync = ref.watch(wirdPlanRemainingRubsProvider);
    final remainingDaysAsync = ref.watch(wirdPlanRemainingDaysProvider);

    return wirdAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (wird) {
        final plan = wird.activePlan;
        if (plan == null) return const SizedBox.shrink();

        return stateAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (state) {
            // Don't show if state is none
            if (state == WirdPlanState.none) return const SizedBox.shrink();

            final progress = progressAsync.valueOrNull ?? {};
            final remainingRubs = remainingRubsAsync.valueOrNull ?? 0;
            final remainingDays = remainingDaysAsync.valueOrNull ?? 0;

            return Container(
              padding: const EdgeInsets.all(AnisSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(AnisRadius.md),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and edit button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'MA KHATMA PERSONNELLE',
                          style: text.caption.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => showWirdPlanSheet(context, ref),
                        borderRadius: BorderRadius.circular(AnisRadius.sm),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AnisSpacing.sm),

                  // Plan identity
                  Text(
                    _getPlanIdentity(plan),
                    style: text.body.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AnisSpacing.sm),

                  // State badge if applicable
                  if (state != WirdPlanState.active)
                    _buildStateBadge(context, state),

                  // Metrics
                  const SizedBox(height: AnisSpacing.sm),
                  _buildMetricRow(
                    context,
                    'Progression',
                    formatProgressAsHizb(progress.length, plan.totalRubTarget),
                  ),
                  if (state == WirdPlanState.active) ...[
                    _buildMetricRow(
                      context,
                      'Jours restants',
                      '$remainingDays ${remainingDays > 1 ? "jours" : "jour"}',
                    ),
                  ],

                  // Action for completed/expired states
                  if (state == WirdPlanState.completed ||
                      state == WirdPlanState.expired) ...[
                    const SizedBox(height: AnisSpacing.sm),
                    _buildPlanAction(context, ref, state, remainingRubs),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStateBadge(BuildContext context, WirdPlanState state) {
    final colors = context.anisColors;
    final text = context.anisText;

    Color badgeColor;
    String label;

    switch (state) {
      case WirdPlanState.scheduled:
        badgeColor = colors.textSecondary;
        label = 'Programmé';
      case WirdPlanState.completed:
        badgeColor = colors.hizbCompletedBorder;
        label = 'Khatma accomplie — Al-hamdu lillāh';
      case WirdPlanState.expired:
        badgeColor = colors.accentGoldText;
        label = 'Échéance passée';
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AnisSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AnisSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AnisRadius.sm),
        ),
        child: Text(
          label,
          style: text.caption.copyWith(
            color: badgeColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(BuildContext context, String label, String value) {
    final colors = context.anisColors;
    final text = context.anisText;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: text.caption.copyWith(color: colors.textSecondary)),
          Text(
            value,
            style: text.caption.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanAction(
    BuildContext context,
    WidgetRef ref,
    WirdPlanState state,
    int remainingRubs,
  ) {
    final colors = context.anisColors;
    final text = context.anisText;

    if (state == WirdPlanState.completed) {
      return SizedBox(
        height: 36,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => showWirdPlanSheet(context, ref),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.actionPrimary,
            side: BorderSide(color: colors.actionPrimary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AnisRadius.sm),
            ),
          ),
          child: Text(
            'Créer un nouveau plan',
            style: text.label.copyWith(color: colors.actionPrimary),
          ),
        ),
      );
    } else if (state == WirdPlanState.expired) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Il reste ${formatRubsAsReadingPace(remainingRubs, 'fr')} à lire',
            style: text.caption.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AnisSpacing.sm),
          // Option: Continue current Khatma (keep plan as reference)
          Text(
            'Vous pouvez continuer votre lecture sans deadline',
            style: text.caption.copyWith(color: colors.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AnisSpacing.xs),
          SizedBox(
            height: 36,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => showWirdPlanSheet(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.actionSecondaryText,
                side: BorderSide(color: colors.actionSecondaryBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AnisRadius.sm),
                ),
              ),
              child: Text(
                'Gérer mon plan',
                style: text.label.copyWith(color: colors.actionSecondaryText),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  String _getPlanIdentity(WirdPlan plan) {
    if (plan.type == WirdPlanType.hijriMonth) {
      final start = plan.baselineDate.add(const Duration(days: 1));
      final hijriStart = HijriDateTime.fromGregorian(start);
      return 'Mois de ${_getHijriMonthName(hijriStart.month)}';
    } else {
      final start = plan.baselineDate.add(const Duration(days: 1));
      return 'Mois de ${_getGregorianMonthName(start.month)}';
    }
  }

  String _getHijriMonthName(int month) {
    const names = [
      'Muharram', 'Safar', 'Rabi\' al-awwal', 'Rabi\' al-thani',
      'Jumada al-awwal', 'Jumada al-thani', 'Rajab', 'Sha\'ban',
      'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah'
    ];
    return names[month - 1];
  }

  String _getGregorianMonthName(int month) {
    const names = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return names[month - 1];
  }
}
