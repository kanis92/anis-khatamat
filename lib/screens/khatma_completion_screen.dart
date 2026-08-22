import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_constants.dart';
import '../core/extensions/l10n_extensions.dart';
import '../core/models/khatma.dart';
import '../core/providers/reading_provider.dart';
import '../core/services/khatma_link_service.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/khatma_completion_utils.dart';
import '../widgets/khatma/khatma_completion_hizb_grid.dart';

/// Écran de clôture Khatma (WOW 01) — données réelles uniquement.
class KhatmaCompletionScreen extends ConsumerWidget {
  final Khatma khatma;
  final bool playCelebrationAnimation;

  const KhatmaCompletionScreen({
    super.key,
    required this.khatma,
    this.playCelebrationAnimation = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final stream = ref.watch(khatmaStreamProvider(khatma.id)).valueOrNull;
    final k = stream ?? khatma;

    final participantCount = KhatmaCompletionUtils.participantCount(k);
    final durationDays = KhatmaCompletionUtils.durationInDays(k);
    final sampleNames = KhatmaCompletionUtils.sampleParticipantNames(k);
    final closedAt = k.completedAt;

    String? durationLabel;
    if (durationDays != null) {
      durationLabel = durationDays <= 1
          ? l10n.completionDurationOneDay
          : l10n.completionDurationDays(durationDays);
    }

    String? closedLabel;
    if (closedAt != null) {
      closedLabel = l10n.completionClosedOn(
        DateFormat.yMMMd(locale).format(closedAt),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.creamLight,
      appBar: AppBar(
        title: Text(l10n.completionAlhamdulillah),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Semantics(
            header: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  l10n.completionAlhamdulillah,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.completionHeaderSubtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.darkGreen.withValues(alpha: 0.85),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppTheme.accentGold.withValues(alpha: 0.35),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    k.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGreen,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _InfoLine(
                    icon: Icons.menu_book_outlined,
                    text: l10n.completionHizbAccomplished(AppConstants.totalHizb),
                  ),
                  if (k.isGroup && participantCount > 0) ...[
                    const SizedBox(height: 8),
                    _InfoLine(
                      icon: Icons.groups_outlined,
                      text: l10n.completionParticipantsCount(participantCount),
                    ),
                  ],
                  if (durationLabel != null) ...[
                    const SizedBox(height: 8),
                    _InfoLine(icon: Icons.schedule_outlined, text: durationLabel),
                  ],
                  if (closedLabel != null) ...[
                    const SizedBox(height: 8),
                    _InfoLine(icon: Icons.event_outlined, text: closedLabel),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          KhatmaCompletionHizbGrid(animate: playCelebrationAnimation),
          if (k.isGroup && participantCount > 1) ...[
            const SizedBox(height: 24),
            Text(
              l10n.completionCollectiveMessage(participantCount),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.darkGreen.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
            ),
            if (sampleNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.completionWithParticipants(sampleNames.join(', ')),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.go(KhatmaLinkService.myKhatmasCreatePath),
            icon: const Icon(Icons.add_circle_outline),
            label: Text(l10n.completionStartNew),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: AppTheme.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _share(context, k),
            icon: const Icon(Icons.share_outlined),
            label: Text(l10n.completionShare),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go(KhatmaLinkService.myKhatmasPath),
            child: Text(l10n.completionBackToMyKhatmas),
          ),
        ],
      ),
    );
  }

  void _share(BuildContext context, Khatma k) {
    final l10n = context.l10n;
    final body = l10n.completionShareMessage(k.title);
    Share.share(
      KhatmaLinkService.completionShareText(
        localizedBody: body,
        khatmaId: k.id,
      ),
      subject: l10n.completionAlhamdulillah,
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.accentGold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.darkGreen.withValues(alpha: 0.9),
                ),
          ),
        ),
      ],
    );
  }
}

/// Bandeau sobre pour Khatma terminée (consultation ultérieure depuis route détail).
class KhatmaCompletedBanner extends StatelessWidget {
  final Khatma khatma;
  final VoidCallback onViewCompletion;

  const KhatmaCompletedBanner({
    super.key,
    required this.khatma,
    required this.onViewCompletion,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: AppTheme.accentGold.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.accentGold, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.completionFinishedBadge,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                  Text(
                    l10n.completionHizbAccomplished(AppConstants.totalHizb),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onViewCompletion,
              child: Text(l10n.completionViewClosure),
            ),
          ],
        ),
      ),
    );
  }
}
