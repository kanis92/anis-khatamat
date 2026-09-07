import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_constants.dart';
import '../core/services/khatma_link_service.dart';
import '../core/theme/app_theme.dart';
import '../core/data/quran_hizb_data.dart';
import '../core/models/khatma.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/reading_provider.dart';
import '../core/extensions/l10n_extensions.dart';
import '../core/widgets/anis_button.dart';
import '../core/widgets/empty_state.dart';
import '../design_system/components/anis_surface.dart';

bool _isCustomName(String name, List<String> members) =>
    name != 'Moi' && !members.contains(name);

/// Écran détail d'une Khatma — DS-01 Premium UX
/// Focus: progression claire + action évidente + états gérés
class KhatmaDetailScreen extends ConsumerWidget {
  final Khatma khatma;

  const KhatmaDetailScreen({super.key, required this.khatma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(khatmaProgressProvider(khatma.id));
    final currentUserEmail = ref.watch(currentUserProvider)?.email ?? 'demo';
    final estimatedCompletionAsync =
        ref.watch(khatmaEstimatedCompletionProvider(khatma.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(khatma.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat Khatma',
            onPressed: () => context.push(
              KhatmaLinkService.chatPath(khatma.id),
              extra: {'khatma': khatma},
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book),
            onPressed: () => context.push('/mushaf/hafs'),
            tooltip: 'Ouvrir le Mushaf',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareKhatmaDetail(
              khatma,
              progressAsync.valueOrNull?.completedCount ?? 0,
            ),
            tooltip: 'Partager',
          ),
        ],
      ),
      body: progressAsync.when(
        data: (progress) => _KhatmaDetailContent(
          khatma: khatma,
          completedHizb: progress?.completedHizb ?? {},
          completedCount: progress?.completedCount ?? 0,
          currentUserEmail: currentUserEmail,
          lastActivity: progress?.lastUpdated,
          estimatedCompletion: estimatedCompletionAsync.valueOrNull,
          onToggle: (hizbNum) async {
            final user = ref.read(currentUserProvider);
            final userId = user?.email ?? 'demo';
            await ref.read(readingServiceProvider).toggleHizbCompleted(
                  khatma.id,
                  userId,
                  hizbNum,
                );
            ref.invalidate(khatmaProgressProvider(khatma.id));
            ref.invalidate(totalCompletedHizbProvider);
            ref.invalidate(khatmatProvider);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _ErrorState(
          error: err.toString(),
          onRetry: () => ref.invalidate(khatmaProgressProvider(khatma.id)),
        ),
      ),
    );
  }
}

void _shareKhatmaDetail(Khatma khatma, int completedCount) {
  final total = AppConstants.totalHizb;
  Share.share(
    KhatmaLinkService.progressShareMessage(
      khatma: khatma,
      completedCount: completedCount,
      totalHizb: total,
    ),
    subject: completedCount >= total && total > 0
        ? 'Khatma terminée - ANIS Khatamat'
        : 'Ma Khatma - ANIS Khatamat',
  );
}

class _KhatmaDetailContent extends StatelessWidget {
  final Khatma khatma;
  final Set<int> completedHizb;
  final int completedCount;
  final String currentUserEmail;
  final DateTime? lastActivity;
  final DateTime? estimatedCompletion;
  final Future<void> Function(int) onToggle;

  const _KhatmaDetailContent({
    required this.khatma,
    required this.completedHizb,
    required this.completedCount,
    required this.currentUserEmail,
    this.lastActivity,
    this.estimatedCompletion,
    required this.onToggle,
  });

  int? _findNextHizbToRead() {
    for (int hizbNum = 1; hizbNum <= AppConstants.totalHizb; hizbNum++) {
      if (!completedHizb.contains(hizbNum)) {
        final assignedTo = khatma.hizbAssignments[hizbNum] ?? '';
        final isMine = assignedTo == 'Moi' || assignedTo.isEmpty;
        if (isMine) {
          return hizbNum;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = completedCount >= AppConstants.totalHizb;
    final nextHizb = _findNextHizbToRead();
    final myAssignedCount = khatma.hizbAssignments.values
        .where((v) => v == 'Moi' || v.isEmpty)
        .length;

    return CustomScrollView(
      slivers: [
        // En-tête de progression
        SliverToBoxAdapter(
          child: _ProgressHeader(
            completed: completedCount,
            total: AppConstants.totalHizb,
            isCompleted: isCompleted,
            khatmaTitle: khatma.title,
            estimatedCompletion: estimatedCompletion,
          ),
        ),

        // Mon prochain Hizb (CTA principal)
        if (!isCompleted && nextHizb != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _NextHizbCard(
                hizbNum: nextHizb,
                onTap: () => context.push('/mushaf/hafs'),
              ),
            ),
          ),

        // État complété
        if (isCompleted)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _CompletedCard(
                khatma: khatma,
                completedCount: completedCount,
              ),
            ),
          ),

        // Objectifs (si présents)
        if (khatma.objectives != null && khatma.objectives!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _ObjectivesCard(message: khatma.objectives!),
            ),
          ),

        // Stats rapides
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _StatsRow(
              totalHizb: AppConstants.totalHizb,
              completed: completedCount,
              myAssigned: myAssignedCount,
              isGroup: khatma.isGroup,
            ),
          ),
        ),

        // Bouton Chat
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnisButton(
              label: 'Chat de la Khatma',
              icon: Icons.forum,
              variant: AnisButtonVariant.outline,
              fullWidth: true,
              onPressed: () => context.push(
                KhatmaLinkService.chatPath(khatma.id),
                extra: {'khatma': khatma},
              ),
            ),
          ),
        ),

        // Infos Khatma
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _KhatmaInfoCard(
              khatma: khatma,
              currentUserEmail: currentUserEmail,
              lastActivity: lastActivity,
              estimatedCompletion: estimatedCompletion,
              l10n: context.l10n,
            ),
          ),
        ),

        // Liste des Hizb
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final hizbNum = i + 1;
                final isHizbCompleted = completedHizb.contains(hizbNum);
                final assignedTo = khatma.hizbAssignments[hizbNum] ?? '';
                final isMine = assignedTo == 'Moi' || assignedTo.isEmpty;
                final isNext = hizbNum == nextHizb;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HizbListItem(
                    hizbNum: hizbNum,
                    isCompleted: isHizbCompleted,
                    assignedTo: assignedTo,
                    isMine: isMine,
                    isNext: isNext && !isHizbCompleted,
                    khatmaMembers: khatma.members,
                    onToggle: isMine ? () => onToggle(hizbNum) : null,
                    l10n: context.l10n,
                  ),
                );
              },
              childCount: AppConstants.totalHizb,
            ),
          ),
        ),

        // Espace en bas
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }
}

/// Mon prochain Hizb à lire — CTA principal
class _NextHizbCard extends StatelessWidget {
  final int hizbNum;
  final VoidCallback onTap;

  const _NextHizbCard({
    required this.hizbNum,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hizbData = QuranHizbData.getHizbData(hizbNum);
    final range = hizbData['range'] ?? '';

    return AnisSurface(
      tone: AnisSurfaceTone.elevated,
      level: AnisSurfaceLevel.raised,
      backgroundColor: Colors.white,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon prochain Hizb',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hizb $hizbNum',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: AppTheme.primaryGreen,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              range,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne de stats rapides
class _StatsRow extends StatelessWidget {
  final int totalHizb;
  final int completed;
  final int myAssigned;
  final bool isGroup;

  const _StatsRow({
    required this.totalHizb,
    required this.completed,
    required this.myAssigned,
    required this.isGroup,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = totalHizb - completed;
    
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle,
            label: 'Complétés',
            value: '$completed',
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.schedule,
            label: 'Restants',
            value: '$remaining',
            color: AppTheme.accentGold,
          ),
        ),
        if (isGroup && myAssigned > 0) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.person,
              label: 'Mes Hizb',
              value: '$myAssigned',
              color: Colors.blue,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnisSurface(
      tone: AnisSurfaceTone.elevated,
      level: AnisSurfaceLevel.soft,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Carte Hizb individuel dans la liste
class _HizbListItem extends StatelessWidget {
  final int hizbNum;
  final bool isCompleted;
  final String assignedTo;
  final bool isMine;
  final bool isNext;
  final List<String> khatmaMembers;
  final VoidCallback? onToggle;
  final AppLocalizations l10n;

  const _HizbListItem({
    required this.hizbNum,
    required this.isCompleted,
    required this.assignedTo,
    required this.isMine,
    required this.isNext,
    required this.khatmaMembers,
    this.onToggle,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final hizbData = QuranHizbData.getHizbData(hizbNum);
    final range = hizbData['range'] ?? '';
    final displayName = assignedTo.isNotEmpty ? assignedTo : l10n.unassigned;
    final nameColor = assignedTo.isNotEmpty
        ? (_isCustomName(assignedTo, khatmaMembers)
            ? AppTheme.customNameColor
            : AppTheme.primaryGreen)
        : Colors.grey;

    return AnisSurface(
      tone: isNext ? AnisSurfaceTone.soft : AnisSurfaceTone.elevated,
      level: AnisSurfaceLevel.soft,
      onTap: isMine ? onToggle : null,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Checkbox/état
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppTheme.primaryGreen
                  : Colors.grey[200],
              border: Border.all(
                color: isCompleted
                    ? AppTheme.primaryGreen
                    : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hizb $hizbNum',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isNext ? AppTheme.accentGold : null,
                          ),
                    ),
                    if (isNext) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SUIVANT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  range,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  style: TextStyle(
                    color: nameColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    fontStyle:
                        assignedTo.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          // Indicateur visuel
          if (isCompleted)
            Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20)
          else if (isMine)
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
        ],
      ),
    );
  }
}

/// En-tête de progression
class _ProgressHeader extends StatelessWidget {
  final int completed;
  final int total;
  final bool isCompleted;
  final String khatmaTitle;
  final DateTime? estimatedCompletion;

  const _ProgressHeader({
    required this.completed,
    required this.total,
    required this.isCompleted,
    required this.khatmaTitle,
    this.estimatedCompletion,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    final percent = total > 0 ? ((completed / total) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.08),
            AppTheme.accentGold.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // Pourcentage circulaire
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircularProgress(
                progress: progress,
                percent: percent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$completed',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '/',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[400],
                      ),
                ),
              ),
              Text(
                '$total',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                'Hizb',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            QuranHizbData.hizbConventionLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
          ),
          // Estimation
          if (!isCompleted && estimatedCompletion != null && completed > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insights, size: 16, color: AppTheme.primaryGreen),
                  const SizedBox(width: 6),
                  Text(
                    'Fin estimée : ${DateFormat.yMMMd('fr').format(estimatedCompletion!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Progression circulaire
class _CircularProgress extends StatelessWidget {
  final double progress;
  final int percent;

  const _CircularProgress({
    required this.progress,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Carte Khatma terminée
class _CompletedCard extends StatelessWidget {
  final Khatma khatma;
  final int completedCount;

  const _CompletedCard({
    required this.khatma,
    required this.completedCount,
  });

  void _shareCompletion() {
    Share.share(
      '🕌 Khatma terminée ! ماشاء الله\n\n'
      'J\'ai complété la Khatma "${khatma.title}" - 60 Hizb du Coran.\n\n'
      'Téléchargez ANIS Khatamat pour suivre vos Khatmat.',
      subject: 'Khatma terminée - ANIS Khatamat',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnisSurface(
      tone: AnisSurfaceTone.soft,
      level: AnisSurfaceLevel.raised,
      child: Column(
        children: [
          Icon(
            Icons.emoji_events,
            size: 64,
            color: AppTheme.accentGold,
          ),
          const SizedBox(height: 16),
          Text(
            'Khatma terminée !',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentGold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'ماشاء الله',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
          ),
          const SizedBox(height: 20),
          AnisButton(
            label: 'Partager cette réussite',
            icon: Icons.share,
            variant: AnisButtonVariant.accent,
            fullWidth: true,
            onPressed: _shareCompletion,
          ),
        ],
      ),
    );
  }
}

/// Carte objectifs
class _ObjectivesCard extends StatelessWidget {
  final String message;

  const _ObjectivesCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return AnisSurface(
      tone: AnisSurfaceTone.elevated,
      level: AnisSurfaceLevel.subtle,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote, color: Colors.grey[400], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                    color: Colors.grey[700],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte infos Khatma
class _KhatmaInfoCard extends StatelessWidget {
  final Khatma khatma;
  final String currentUserEmail;
  final DateTime? lastActivity;
  final DateTime? estimatedCompletion;
  final AppLocalizations l10n;

  const _KhatmaInfoCard({
    required this.khatma,
    required this.currentUserEmail,
    this.lastActivity,
    this.estimatedCompletion,
    required this.l10n,
  });

  String _creatorDisplay() {
    if (khatma.createdBy.isEmpty) return l10n.user;
    if (khatma.createdBy == currentUserEmail || khatma.createdBy == 'demo') {
      return 'Moi';
    }
    return khatma.createdBy;
  }

  @override
  Widget build(BuildContext context) {
    return AnisSurface(
      tone: AnisSurfaceTone.elevated,
      level: AnisSurfaceLevel.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.person_outline,
            label: '${l10n.createdBy} ${_creatorDisplay()}',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.calendar_today,
            label:
                '${l10n.createdOn} ${DateFormat.yMMMd('fr').format(khatma.createdAt)}',
          ),
          if (lastActivity != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.update,
              label:
                  '${l10n.lastActivity}: ${DateFormat.yMMMd('fr').format(lastActivity!)}',
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
        ),
      ],
    );
  }
}

/// État d'erreur
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: EmptyState(
          fallbackIcon: Icons.error_outline,
          title: 'Erreur de chargement',
          subtitle: 'Impossible de charger les données de la Khatma.\n$error',
          actionLabel: 'Réessayer',
          onAction: onRetry,
        ),
      ),
    );
  }
}
