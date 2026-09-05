import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri_date_time/hijri_date_time.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/extensions/l10n_extensions.dart';
import '../core/models/home_dashboard_state.dart';
import '../core/models/khatma_with_status.dart';
import '../core/utils/auth_diag.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/home_dashboard_provider.dart';
import '../core/providers/prayer_times_provider.dart';
import '../core/providers/reading_goal_provider.dart';
import '../core/providers/reading_provider.dart';
import '../core/services/khatma_link_service.dart';
import '../core/widgets/anis_icon.dart';
import '../core/widgets/connectivity_banner.dart' show connectivityProvider;
import '../core/widgets/mushaf_hizb_indicator.dart' show mushafNumber;
import '../design_system/anis_design_system.dart';

const _heroAsset = 'assets/images/anis_header.png';

/// Accueil ANIS — présentation premium (hero immersif + progression + actions).
///
/// Aucune donnée n'est fabriquée : chaque bloc s'appuie sur les providers et
/// modèles existants. Les routes des actions rapides pointent uniquement vers
/// des destinations réellement enregistrées dans le routeur.
class AnisHomePage extends ConsumerWidget {
  const AnisHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(homeDashboardProvider);
    final identity = _resolveIdentity(ref);

    return dashboardAsync.when(
      loading:
          () => _HomeShell(identity: identity, child: const _HomeLoadingBody()),
      error:
          (_, _) => _HomeShell(
            identity: identity,
            child: _HomeErrorBody(
              onRetry: () => ref.invalidate(homeDashboardProvider),
            ),
          ),
      data:
          (dashboard) => _HomeShell(
            identity: identity,
            onRefresh: () async {
              ref.invalidate(homeDashboardProvider);
              ref.invalidate(khatmatWithStatusProvider);
              ref.invalidate(totalCompletedHizbProvider);
              await ref.read(homeDashboardProvider.future);
            },
            child:
                dashboard.isEmpty
                    ? _HomeEmptyBody()
                    : _HomeDashboardBody(dashboard: dashboard),
          ),
    );
  }

  static ParticipantIdentity? _resolveIdentity(WidgetRef ref) =>
      ParticipantIdentity.fromFirebaseAuth(
        isDemoMode: ref.watch(demoModeProvider),
      );
}

/// Coque scrollable commune (hero + corps).
class _HomeShell extends ConsumerWidget {
  const _HomeShell({
    required this.identity,
    required this.child,
    this.onRefresh,
  });

  final ParticipantIdentity? identity;
  final Widget child;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.anisColors;
    final bottomInset = AnisResponsiveLayout.shellBodyBottomInset(context);

    Widget body = CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(child: _HomeHero(identity: identity)),
        SliverPadding(
          padding: EdgeInsetsDirectional.fromSTEB(
            AnisSpacing.page,
            AnisSpacing.lg,
            AnisSpacing.page,
            bottomInset,
          ),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    );

    if (onRefresh != null) {
      body = RefreshIndicator(
        onRefresh: onRefresh!,
        color: colors.actionPrimary,
        backgroundColor: colors.surfaceElevated,
        child: body,
      );
    }

    return ColoredBox(color: colors.surfaceBase, child: body);
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.identity});

  final ParticipantIdentity? identity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.anisText;
    final hijri = formatHijriDate();
    final time = DateFormat.Hm().format(DateTime.now());
    final name = identity?.displayLabel ?? l10n.guestBadge;
    final initial = identity?.displayInitial ?? '?';

    final heroHeight = (MediaQuery.sizeOf(context).height * 0.34).clamp(
      228.0,
      320.0,
    );

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _heroAsset,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.15),
            semanticLabel: l10n.home,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.52),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AnisSpacing.page,
                AnisSpacing.sm,
                AnisSpacing.page,
                AnisSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        tooltip: l10n.notifications,
                        onPressed: () => context.go('/notifications'),
                        icon: AnisIcon(
                          type: AnisIconType.bell,
                          size: AnisIconSize.lg,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AnisSpacing.sm),
                      Semantics(
                        label: name,
                        button: true,
                        child: InkWell(
                          onTap: () => context.go('/settings'),
                          customBorder: const CircleBorder(),
                          child: AnisAvatar(
                            initial: initial,
                            semanticLabel: name,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    l10n.welcomeGreeting,
                    style: text.titleLarge.copyWith(
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Color(0x66000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AnisSpacing.xs),
                  Text(
                    '$hijri  •  $time',
                    style: text.bodySecondary.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      shadows: const [
                        Shadow(color: Color(0x55000000), blurRadius: 6),
                      ],
                    ),
                  ),
                  const _HeroPrayerChip(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPrayerChip extends ConsumerWidget {
  const _HeroPrayerChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayer = ref.watch(nextPrayerProvider);
    if (prayer == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AnisSpacing.sm),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: AnisBadge(
          label: context.l10n.homePrayerPill(prayer.name, prayer.inStr),
          tone: AnisBadgeTone.active,
          anisIcon: AnisIconType.mihrab,
          semanticLabel: context.l10n.homeNextPrayerSemantic(prayer.name, prayer.inStr),
        ),
      ),
    );
  }
}

// ── Ramadan ──────────────────────────────────────────────────────────────────

class _RamadanSummaryCard extends StatelessWidget {
  const _RamadanSummaryCard({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;
    final locale = Localizations.localeOf(context).toString();
    final gregorian = formatGregorianDate(locale);
    final progress = (day / 30).clamp(0.0, 1.0);
    final label = _ramadanDayLabel(context, day);

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AnisSpacing.blockGap),
      child: AnisSurface(
        level: AnisSurfaceLevel.raised,
        radius: AnisRadius.lg,
        semanticLabel: label,
        child: Row(
          children: [
            AnisGlyph.anis(
              AnisIconType.calendar,
              size: AnisIconSize.lg,
              color: colors.accentGoldText,
            ),
            const SizedBox(width: AnisSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: text.sectionTitle),
                  const SizedBox(height: AnisSpacing.xxs),
                  Text(gregorian, style: text.bodySecondary),
                  const SizedBox(height: AnisSpacing.sm),
                  ClipRRect(
                    borderRadius: AnisRadius.pillAll,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: colors.progressTrack,
                      valueColor: AlwaysStoppedAnimation(
                        colors.accentGoldStrong,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AnisSpacing.sm),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textTertiary,
              semanticLabel: '',
            ),
          ],
        ),
      ),
    );
  }

  static String _ramadanDayLabel(BuildContext context, int day) {
    final l10n = context.l10n;
    return switch (Localizations.localeOf(context).languageCode) {
      'ar' => l10n.homeRamadanPillAr(day),
      'en' => l10n.homeRamadanPillEn(day),
      _ => l10n.homeRamadanPillFr(day),
    };
  }
}

bool _isRamadanMonth() => HijriDateTime.now().month == 9;

// ── Progression Coran ────────────────────────────────────────────────────────

class _QuranProgressCard extends ConsumerWidget {
  const _QuranProgressCard({required this.dashboard});

  final HomeDashboardState dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(readingGoalProgressProvider).valueOrNull;
    final primary = dashboard.primary;
    final l10n = context.l10n;
    final text = context.anisText;
    final colors = context.anisColors;
    final completed =
        ref.watch(totalCompletedHizbProvider).valueOrNull ??
        dashboard.summary.userCompletedHizb;
    final total = AppConstants.totalHizb;
    final fraction = total > 0 ? completed / total : 0.0;
    final percent = (fraction * 100).round();

    final reservation = primary?.userReservation;
    final mushafLabel =
        reservation?.inProgress == true ? l10n.resume : l10n.openMushaf;

    void openMushaf() {
      if (reservation?.inProgress == true && primary != null) {
        context.push(
          KhatmaLinkService.detailPath(primary.status.khatma.id),
          extra: {'khatma': primary.status.khatma},
        );
        return;
      }
      context.push('/mushaf');
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AnisSpacing.blockGap),
      child: AnisSurface(
        tone: AnisSurfaceTone.inverse,
        level: AnisSurfaceLevel.raised,
        radius: AnisRadius.xl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homePersonalProgress,
              style: text.sectionTitle.copyWith(color: colors.textOnInverse),
            ),
            const SizedBox(height: AnisSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnisProgressRing(
                  value: fraction,
                  tone: AnisProgressRingTone.onInverse,
                  centerLabel: l10n.completionProgressFraction(
                    completed,
                    total,
                  ),
                  semanticLabel: l10n.homePersonalProgress,
                ),
                const SizedBox(width: AnisSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$percent %',
                        style: text.numberLarge.copyWith(
                          color: colors.textOnInverse,
                        ),
                      ),
                      const SizedBox(height: AnisSpacing.xxs),
                      Text(
                        l10n.hizbCompleted,
                        style: text.bodySecondary.copyWith(
                          color: colors.textOnInverse.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (goal != null && goal.target > 0) ...[
              const SizedBox(height: AnisSpacing.lg),
              AnisProgressBar(
                value: goal.target == 0 ? 0 : goal.completed / goal.target,
                label: l10n.homeGoalToday,
                valueLabel: l10n.readingGoalProgress(
                  goal.completed,
                  goal.target,
                ),
                semanticLabel: l10n.homeGoalToday,
              ),
            ],
            const SizedBox(height: AnisSpacing.xl),
            _IvoryCta(label: mushafLabel, onPressed: openMushaf),
          ],
        ),
      ),
    );
  }
}

class _IvoryCta extends StatelessWidget {
  const _IvoryCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AnisPalette.ivory,
        borderRadius: AnisRadius.mdAll,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AnisRadius.mdAll,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AnisIconSize.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AnisSpacing.lg,
                vertical: AnisSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnisIcon(
                    type: AnisIconType.bookOpen,
                    size: AnisIconSize.md,
                    color: colors.surfaceInverse,
                  ),
                  const SizedBox(width: AnisSpacing.sm),
                  Flexible(
                    child: Text(
                      label,
                      style: text.label.copyWith(color: colors.surfaceInverse),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Actions rapides ──────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnisSectionHeader(title: l10n.quickActions),
        const SizedBox(height: AnisSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = AnisSpacing.sm;
            final tileWidth = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: tileWidth,
                  child: _QuickActionTile(
                    icon: AnisIconType.bookOpen,
                    title: l10n.mushaf,
                    subtitle: l10n.quickActionMushafSubtitle,
                    onTap: () => context.push('/mushaf'),
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _QuickActionTile(
                    icon: AnisIconType.khatma,
                    title: l10n.khatma,
                    subtitle: l10n.quickActionKhatmaSubtitle,
                    onTap: () => context.go('/khatma'),
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _QuickActionTile(
                    icon: AnisIconType.training,
                    title: l10n.quickActionFormationsTitle,
                    subtitle: l10n.quickActionFormationsSubtitle,
                    onTap: () => context.go('/training'),
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _QuickActionTile(
                    icon: AnisIconType.bell,
                    title: l10n.notifications,
                    subtitle: l10n.quickActionNotificationsSubtitle,
                    onTap: () => context.go('/notifications'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final AnisIconType icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;

    return AnisSurface(
      level: AnisSurfaceLevel.subtle,
      radius: AnisRadius.md,
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      padding: const EdgeInsetsDirectional.all(AnisSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 100,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.actionPrimary.withValues(
                  alpha: AnisOpacity.subtleFill,
                ),
                borderRadius: AnisRadius.smAll,
              ),
              alignment: Alignment.center,
              child: AnisGlyph.anis(
                icon,
                size: AnisIconSize.md,
                color: colors.actionPrimary,
              ),
            ),
            const SizedBox(height: AnisSpacing.sm),
            Text(
              title,
              style: text.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AnisSpacing.xxs),
            Text(
              subtitle,
              style: text.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── États & dashboard ────────────────────────────────────────────────────────

class _HomeLoadingBody extends StatelessWidget {
  const _HomeLoadingBody();

  @override
  Widget build(BuildContext context) {
    return const AnisSkeletonGroup(
      child: Column(
        children: [
          AnisSkeleton(height: 88, radius: AnisRadius.lg),
          SizedBox(height: AnisSpacing.blockGap),
          AnisSkeleton(height: 196, radius: AnisRadius.xl),
          SizedBox(height: AnisSpacing.blockGap),
          AnisSkeleton(height: 120, radius: AnisRadius.lg),
          SizedBox(height: AnisSpacing.blockGap),
          AnisSkeleton(height: 120, radius: AnisRadius.lg),
        ],
      ),
    );
  }
}

class _HomeErrorBody extends StatelessWidget {
  const _HomeErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnisEmptyState(
      glyph: const AnisGlyph.material(
        Icons.cloud_off_rounded,
        size: AnisIconSize.xl,
      ),
      title: l10n.homeLoadError,
      message: l10n.homeLoadErrorHint,
      primaryActionLabel: l10n.retry,
      onPrimaryAction: onRetry,
    );
  }
}

class _HomeEmptyBody extends ConsumerWidget {
  const _HomeEmptyBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isRamadanMonth())
          _RamadanSummaryCard(day: HijriDateTime.now().day),
        const _QuranProgressCard(dashboard: HomeDashboardState.empty),
        const _QuickActionsGrid(),
        const SizedBox(height: AnisSpacing.sectionGap),
        AnisEmptyState(
          showSignature: true,
          title: l10n.homeEmptyTitle,
          message: l10n.homeEmptyHint,
          primaryActionLabel: l10n.createKhatma,
          onPrimaryAction: () => context.go('/khatma?create=1'),
          secondaryActionLabel: l10n.joinCollectiveKhatma,
          onSecondaryAction: () => context.go('/khatma'),
        ),
      ],
    );
  }
}

class _HomeDashboardBody extends ConsumerWidget {
  const _HomeDashboardBody({required this.dashboard});

  final HomeDashboardState dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final formation = ref.watch(formationProgressProvider).valueOrNull;
    final others =
        dashboard.activeKhatmas
            .where((s) => s.khatma.id != dashboard.primary?.status.khatma.id)
            .take(3)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _OfflineNotice(),
        if (_isRamadanMonth())
          _RamadanSummaryCard(day: HijriDateTime.now().day),
        _QuranProgressCard(dashboard: dashboard),
        const _QuickActionsGrid(),
        if (!dashboard.isEmpty) ...[
          const SizedBox(height: AnisSpacing.blockGap),
          _SummaryRow(summary: dashboard.summary),
        ],
        if (dashboard.primary != null) ...[
          const SizedBox(height: AnisSpacing.sectionGap),
          AnisSectionHeader(title: l10n.khatmaInProgress),
          const SizedBox(height: AnisSpacing.md),
          _PrimaryKhatmaCard(highlight: dashboard.primary!),
        ],
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
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});

  final HomeDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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

    return AnisListTile(
      title: khatma.title,
      subtitle: l10n.groupKhatma,
      leading: _homeListLeadingAnis(context, AnisIconType.khatma),
      onTap:
          () => context.push(
            KhatmaLinkService.detailPath(khatma.id),
            extra: {'khatma': khatma},
          ),
    );
  }
}

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
