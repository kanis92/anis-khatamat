import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/reading_provider.dart';
import '../core/extensions/l10n_extensions.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final completedAsync = ref.watch(totalCompletedHizbProvider);
    final completedHizb = completedAsync.valueOrNull ?? 0;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeCard(userEmail: user?.email ?? l10n.user, l10n: l10n),
            const SizedBox(height: 24),
            _SectionTitle(title: l10n.quickActions),
            const SizedBox(height: 16),
            _QuickActionsGrid(
              l10n: l10n,
              onCreateKhatma: () => context.go('/khatma'),
              onAchievements: () => context.push('/achievements'),
              onTraining: () => context.go('/training'),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: l10n.progression),
            const SizedBox(height: 16),
            _ProgressCard(
              completedHizb: completedHizb,
              totalHizb: AppConstants.totalHizb,
              l10n: l10n,
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: l10n.upcomingReadings),
            const SizedBox(height: 16),
            _UpcomingCard(
              khatmatCount: ref.watch(khatmatProvider).valueOrNull?.length ?? 0,
              l10n: l10n,
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String userEmail;
  final dynamic l10n;

  const _WelcomeCard({required this.userEmail, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.waving_hand,
                size: 40,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.welcomeGreeting,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.welcomeSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final dynamic l10n;
  final VoidCallback onCreateKhatma;
  final VoidCallback onAchievements;
  final VoidCallback onTraining;

  const _QuickActionsGrid({
    required this.l10n,
    required this.onCreateKhatma,
    required this.onAchievements,
    required this.onTraining,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _ActionCard(
          icon: Icons.add_circle_outline,
          label: l10n.createKhatma,
          color: AppTheme.primaryGreen,
          onTap: onCreateKhatma,
        ),
        _ActionCard(
          icon: Icons.emoji_events_outlined,
          label: l10n.achievements,
          color: AppTheme.accentGold,
          onTap: () => context.push('/achievements'),
        ),
        _ActionCard(
          icon: Icons.school_outlined,
          label: l10n.training,
          color: Colors.blue,
          onTap: onTraining,
        ),
        _ActionCard(
          icon: Icons.menu_book_outlined,
          label: l10n.mushaf,
          color: Colors.teal,
          onTap: () => context.push('/mushaf'),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int completedHizb;
  final int totalHizb;
  final dynamic l10n;

  const _ProgressCard({
    required this.completedHizb,
    required this.totalHizb,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalHizb > 0 ? completedHizb / totalHizb : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.hizbCompleted,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '$completedHizb / $totalHizb',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final int khatmatCount;
  final dynamic l10n;

  const _UpcomingCard({this.khatmatCount = 0, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final hasKhatmat = khatmatCount > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: AppTheme.primaryGreen, size: 24),
                const SizedBox(width: 12),
                Text(
                  hasKhatmat
                      ? l10n.khatmatInProgress(khatmatCount)
                      : l10n.noReadingsScheduled,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hasKhatmat
                  ? l10n.continueReading
                  : l10n.createKhatmaToStart,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
