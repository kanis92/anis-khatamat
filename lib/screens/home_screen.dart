import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/extensions/l10n_extensions.dart';
import '../core/models/home_dashboard_state.dart';
import '../core/models/khatma_with_status.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/home_dashboard_provider.dart';
import '../core/providers/reading_goal_provider.dart';
import '../core/providers/reading_provider.dart';
import '../core/services/khatma_link_service.dart';
import '../core/utils/auth_diag.dart';
import '../core/widgets/anis_icon.dart';
import '../core/widgets/connectivity_banner.dart' show connectivityProvider;
import '../core/widgets/mushaf_hizb_indicator.dart' show mushafNumber;
import '../design_system/anis_design_system.dart';

/// Accueil ANIS — premier écran migré sur le design system V1.
///
/// Aucune donnée n'est fabriquée : chaque bloc n'apparaît que si sa source
/// existe réellement. Les blocs conditionnels sont l'objectif de lecture
/// (invisible tant qu'aucun objectif n'est défini), la prochaine prière
/// (invisible sans position), la formation en cours et la bannière hors ligne.
class AnisHomePage extends ConsumerWidget {
  const AnisHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(homeDashboardProvider);
    final header = _HomeHeader(identity: _resolveIdentity(ref));

    return dashboardAsync.when(
      loading: () => _HomeLoading(header: header),
      error: (_, _) => _HomeError(header: header),
      data:
          (dashboard) =>
              dashboard.isEmpty
                  ? _HomeEmpty(header: header)
                  : _HomeDashboard(header: header, dashboard: dashboard),
    );
  }

  static ParticipantIdentity? _resolveIdentity(WidgetRef ref) =>
      ParticipantIdentity.fromFirebaseAuth(
        isDemoMode: ref.watch(demoModeProvider),
      );
}

/// En-tête commun à tous les états de la Home.
///
/// Le nom affiché vient de l'identité Firebase résolue au runtime. Sans
/// identité, l'en-tête annonce « Invité » : jamais de nom de repli inventé.
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.identity});

  final ParticipantIdentity? identity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prayer = ref.watch(nextPrayerProvider);
    final name = identity?.displayLabel ?? l10n.guestBadge;
    final initial = identity?.displayInitial ?? '?';

    // Le badge n'apparaît que lorsqu'il ajoute une information : inutile de
    // répéter « Invité » sous un titre qui dit déjà « Invité ».
    final showGuestBadge =
        !(identity?.isMemberEmail ?? false) && name != l10n.guestBadge;

    final chips = <Widget>[
      if (showGuestBadge)
        AnisBadge(
          label: l10n.guestBadge,
          tone: AnisBadgeTone.notice,
          anisIcon: AnisIconType.user,
        ),
      if (prayer != null)
        AnisBadge(
          label: '${prayer.name} · ${prayer.inStr}',
          tone: AnisBadgeTone.active,
          anisIcon: AnisIconType.mihrab,
          semanticLabel: '${l10n.nextPrayer} : ${prayer.name} ${prayer.inStr}',
        ),
    ];

    return AnisPageHeader(
      eyebrow: l10n.welcomeGreeting,
      title: name,
      showSignature: false,
      leading: AnisAvatar(initial: initial, semanticLabel: name),
      actions: [
        AnisIconAction.anis(
          anisIcon: AnisIconType.bell,
          tooltip: l10n.notifications,
          onPressed: () => context.push('/notifications'),
        ),
      ],
      bottom:
          chips.isEmpty
              ? null
              : Wrap(
                spacing: AnisSpacing.sm,
                runSpacing: AnisSpacing.sm,
                children: chips,
              ),
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading({required this.header});

  final Widget header;

  @override
  Widget build(BuildContext context) {
    return AnisScaffold(
      header: header,
      body: const AnisSkeletonGroup(
        child: Column(
          children: [
            AnisSkeleton(height: 168, radius: AnisRadius.xl),
            SizedBox(height: AnisSpacing.blockGap),
            AnisSkeleton(height: 84, radius: AnisRadius.md),
            SizedBox(height: AnisSpacing.blockGap),
            AnisSkeleton(height: 96, radius: AnisRadius.md),
            SizedBox(height: AnisSpacing.blockGap),
            AnisSkeleton(height: 140, radius: AnisRadius.md),
          ],
        ),
      ),
    );
  }
}

class _HomeError extends ConsumerWidget {
  const _HomeError({required this.header});

  final Widget header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AnisScaffold(
      header: header,
      body: AnisEmptyState(
        glyph: const AnisGlyph.material(
          Icons.cloud_off_rounded,
          size: AnisIconSize.xl,
        ),
        title: l10n.homeLoadError,
        message: l10n.homeLoadErrorHint,
        primaryActionLabel: l10n.retry,
        onPrimaryAction: () => ref.invalidate(homeDashboardProvider),
      ),
    );
  }
}

class _HomeEmpty extends StatelessWidget {
  const _HomeEmpty({required this.header});

  final Widget header;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnisScaffold(
      header: header,
      body: AnisEmptyState(
        showSignature: true,
        title: l10n.homeEmptyTitle,
        message: l10n.homeEmptyHint,
        primaryActionLabel: l10n.createKhatma,
        onPrimaryAction: () => context.go('/khatma?create=1'),
        secondaryActionLabel: l10n.joinCollectiveKhatma,
        onSecondaryAction: () => context.go('/khatma'),
      ),
    );
  }
}

class _HomeDashboard extends ConsumerWidget {
  const _HomeDashboard({required this.header, required this.dashboard});

  final Widget header;
  final HomeDashboardState dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final primary = dashboard.primary;
    final goal = ref.watch(readingGoalProgressProvider).valueOrNull;
    final formation = ref.watch(formationProgressProvider).valueOrNull;
    final others =
        dashboard.activeKhatmas
            .where((s) => s.khatma.id != primary?.status.khatma.id)
            .take(3)
            .toList();

    return AnisScaffold(
      header: header,
      onRefresh: () async {
        ref.invalidate(homeDashboardProvider);
        ref.invalidate(khatmatWithStatusProvider);
        await ref.read(homeDashboardProvider.future);
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _OfflineNotice(),
          if (primary != null) ...[
            _PrimaryKhatmaCard(highlight: primary),
            const SizedBox(height: AnisSpacing.blockGap),
          ],
          if (goal != null && goal.target > 0) ...[
            _ReadingGoalCard(goal: goal),
            const SizedBox(height: AnisSpacing.blockGap),
          ],
          _SummaryRow(summary: dashboard.summary),
          if (dashboard.lastActivity != null) ...[
            const SizedBox(height: AnisSpacing.blockGap),
            _LastActivityTile(activity: dashboard.lastActivity!),
          ],
          if (formation != null) ...[
            const SizedBox(height: AnisSpacing.blockGap),
            AnisListTile(
              title: formation.courseTitle,
              subtitle: formation.lessonTitle,
              leading: _homeListLeadingAnis(context, AnisIconType.training),
              onTap: () => context.go('/training'),
              semanticLabel:
                  '${l10n.myTraining} : ${formation.courseTitle}. ${formation.lessonTitle}',
            ),
          ],
          const SizedBox(height: AnisSpacing.sectionGap),
          AnisSectionHeader(title: l10n.quickActions),
          const _QuickAccessRow(),
          if (others.isNotEmpty) ...[
            const SizedBox(height: AnisSpacing.sectionGap),
            AnisSectionHeader(
              title: l10n.myKhatmat,
              actionLabel: l10n.seeAll,
              onAction: () => context.go('/khatma'),
              actionIcon: Icons.arrow_forward_rounded,
            ),
            for (var i = 0; i < others.length; i++) ...[
              if (i > 0) const SizedBox(height: AnisSpacing.sm),
              _KhatmaRow(status: others[i]),
            ],
          ],
        ],
      ),
    );
  }
}

/// Carte de la Khatma à reprendre — bloc dominant de l'écran.
///
/// L'anneau porte la progression, le badge porte le Hizb réservé, le bouton
/// porte l'action. Le libellé du bouton distingue « Reprendre » d'une lecture
/// déjà entamée de « Continuer » sur une Khatma sans réservation en cours.
class _PrimaryKhatmaCard extends StatelessWidget {
  const _PrimaryKhatmaCard({required this.highlight});

  final PrimaryKhatmaHighlight highlight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.anisText;
    final khatma = highlight.status.khatma;
    final reservation = highlight.userReservation;
    final isCollective = khatma.reservationMode;

    final progressLabel =
        isCollective ? l10n.homeCollectiveProgress : l10n.homePersonalProgress;
    final done =
        isCollective
            ? highlight.globalCompletedHizb
            : (highlight.userPersonalCompleted ?? 0);
    final value = isCollective ? highlight.globalPercent / 100.0 : done / 60.0;

    return AnisSurface(
      level: AnisSurfaceLevel.raised,
      radius: AnisRadius.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnisProgressRing(
                value: value,
                semanticLabel: '$progressLabel : $done / 60',
              ),
              const SizedBox(width: AnisSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.khatmaInProgress,
                      style: text.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AnisSpacing.xxs),
                    Text(
                      khatma.title,
                      style: text.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AnisSpacing.sm),
                    Text(
                      '$progressLabel · ${l10n.completionProgressFraction(done, 60)}',
                      style: text.bodySecondary,
                    ),
                    if (khatma.isGroup || isCollective) ...[
                      const SizedBox(height: AnisSpacing.xxs),
                      Text(
                        l10n.completionParticipantsCount(
                          highlight.participantCount,
                        ),
                        style: text.caption,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (reservation != null) ...[
            const SizedBox(height: AnisSpacing.lg),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AnisBadge(
                label:
                    reservation.inProgress
                        ? l10n.homeHizbInProgress(
                          mushafNumber(context, reservation.hizbNumber),
                        )
                        : l10n.homeHizbReserved(
                          mushafNumber(context, reservation.hizbNumber),
                        ),
                tone:
                    reservation.inProgress
                        ? AnisBadgeTone.accent
                        : AnisBadgeTone.active,
                showSignature: true,
              ),
            ),
          ],
          const SizedBox(height: AnisSpacing.xl),
          AnisPrimaryButton(
            label:
                reservation?.inProgress == true
                    ? l10n.resume
                    : l10n.continueAction,
            anisIcon: AnisIconType.khatma,
            onPressed:
                () => context.push(
                  KhatmaLinkService.detailPath(khatma.id),
                  extra: {'khatma': khatma},
                ),
          ),
        ],
      ),
    );
  }
}

/// Objectif de lecture.
///
/// N'est construit que lorsqu'un objectif existe réellement en préférences.
/// Aucune UI de l'application ne permet aujourd'hui d'en définir un : ce bloc
/// est donc en pratique invisible, et le restera jusqu'à ce que cette
/// fonctionnalité soit ouverte côté produit.
class _ReadingGoalCard extends StatelessWidget {
  const _ReadingGoalCard({required this.goal});

  final GoalProgress goal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.anisText;
    final colors = context.anisColors;

    return AnisSurface(
      tone: AnisSurfaceTone.soft,
      level: AnisSurfaceLevel.flat,
      radius: AnisRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.homeGoalToday, style: text.sectionTitle),
              ),
              if (goal.isAchieved)
                AnisBadge(
                  label: l10n.readingGoalAchieved,
                  tone: AnisBadgeTone.accent,
                  icon: Icons.check_rounded,
                ),
            ],
          ),
          const SizedBox(height: AnisSpacing.md),
          AnisProgressBar(
            value: goal.target == 0 ? 0 : goal.completed / goal.target,
            label: l10n.readingGoal,
            valueLabel: l10n.readingGoalProgress(goal.completed, goal.target),
            semanticLabel: l10n.homeGoalToday,
          ),
          if (goal.isAchieved) ...[
            const SizedBox(height: AnisSpacing.sm),
            Text(
              l10n.readingGoalAchieved,
              style: text.bodySecondary.copyWith(color: colors.accentGoldText),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});

  final HomeDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Hauteur commune aux trois tuiles sans contrainte verticale infinie : la
    // rangée est dans une zone de défilement.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AnisMetricTile(
              value: '${summary.activeCount}',
              label: l10n.inProgress,
              emphasize: true,
            ),
          ),
          const SizedBox(width: AnisSpacing.sm),
          Expanded(
            child: AnisMetricTile(
              value: '${summary.completedCount}',
              label: l10n.completed,
            ),
          ),
          const SizedBox(width: AnisSpacing.sm),
          Expanded(
            child: AnisMetricTile(
              value: '${summary.userCompletedHizb}',
              label: l10n.hizbCompleted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LastActivityTile extends StatelessWidget {
  const _LastActivityTile({required this.activity});

  final HomeLastActivity activity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final date = _formatShortDate(context, activity.at);

    return AnisListTile(
      title: activity.label,
      subtitle: '${l10n.lastActivity} · $date',
      leadingIcon: Icons.history_rounded,
      showChevron: false,
    );
  }
}

/// Date courte dans la locale active.
///
/// Le repli protège les locales dont les symboles de date ne seraient pas
/// chargés : une date au format par défaut vaut mieux qu'un écran en erreur.
String _formatShortDate(BuildContext context, DateTime at) {
  final locale = Localizations.localeOf(context).toString();
  try {
    return DateFormat.MMMd(locale).format(at);
  } catch (_) {
    return DateFormat.MMMd().format(at);
  }
}

class _KhatmaRow extends StatelessWidget {
  const _KhatmaRow({required this.status});

  final KhatmaWithStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final khatma = status.khatma;
    final subtitle =
        khatma.isGroup || khatma.reservationMode
            ? l10n.groupKhatma
            : l10n.individual;

    return AnisListTile(
      title: khatma.title,
      subtitle: subtitle,
      leading: _homeListLeadingAnis(context, AnisIconType.khatma),
      onTap:
          () => context.push(
            KhatmaLinkService.detailPath(khatma.id),
            extra: {'khatma': khatma},
          ),
    );
  }
}

/// Accès rapides.
///
/// Les quatre destinations reprennent celles de la section d'accès rapides déjà
/// écrite mais jamais montée. Trois d'entre elles (`/bookmarks`, `/prayer-times`,
/// `/statistics`) sont des routes enregistrées qui n'avaient aucun point
/// d'entrée dans l'interface : leur exposition ici est un choix produit à
/// confirmer, pas une fonctionnalité nouvelle.
class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.anisColors;

    return AnisQuickActionRow(
      actions: [
        AnisQuickAction(
          glyph: AnisGlyph.anis(
            AnisIconType.bookOpen,
            size: AnisIconSize.lg,
            color: colors.actionPrimary,
          ),
          label: l10n.mushaf,
          onTap: () => context.push('/mushaf'),
        ),
        AnisQuickAction(
          glyph: AnisGlyph.anis(
            AnisIconType.bookmark,
            size: AnisIconSize.lg,
            color: colors.actionPrimary,
          ),
          label: l10n.bookmarks,
          onTap: () => context.push('/bookmarks'),
        ),
        AnisQuickAction(
          glyph: AnisGlyph.anis(
            AnisIconType.mihrab,
            size: AnisIconSize.lg,
            color: colors.actionPrimary,
          ),
          label: l10n.prayerTimes,
          onTap: () => context.push('/prayer-times'),
        ),
        AnisQuickAction(
          glyph: AnisGlyph.anis(
            AnisIconType.chart,
            size: AnisIconSize.lg,
            color: colors.actionPrimary,
          ),
          label: l10n.statistics,
          onTap: () => context.push('/statistics'),
        ),
      ],
    );
  }
}

/// Bandeau hors ligne.
///
/// S'appuie sur le `connectivityProvider` existant. Reste invisible tant que la
/// connectivité est inconnue ou présente : jamais de faux signal.
class _OfflineNotice extends ConsumerWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(connectivityProvider).valueOrNull;
    if (results == null) return const SizedBox.shrink();

    final offline =
        results.isEmpty ||
        results.every(
          (r) => r == ConnectivityResult.none || r == ConnectivityResult.other,
        );
    if (!offline) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AnisSpacing.blockGap),
      child: AnisNotice(
        message: context.l10n.offlineNotice,
        icon: Icons.wifi_off_rounded,
      ),
    );
  }
}

/// Bloc d'icône ANIS pour [AnisListTile.leading].
Widget _homeListLeadingAnis(BuildContext context, AnisIconType type) {
  final colors = context.anisColors;
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: colors.actionPrimary.withValues(alpha: AnisOpacity.subtleFill),
      borderRadius: AnisRadius.smAll,
    ),
    alignment: Alignment.center,
    child: AnisGlyph.anis(
      type,
      size: AnisIconSize.md,
      color: colors.actionPrimary,
    ),
  );
}
