import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../core/data/quran_hizb_data.dart';
import '../core/models/khatma.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/reading_provider.dart';

/// Écran détail d'une Khatma : liste des 60 Hizb avec coches pour marquer comme lu
class KhatmaDetailScreen extends ConsumerWidget {
  final Khatma khatma;

  const KhatmaDetailScreen({super.key, required this.khatma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(khatmaProgressProvider(khatma.id));
    final progress = progressAsync.valueOrNull;
    final completedHizb = progress?.completedHizb ?? {};
    final completedCount = progress?.completedCount ?? 0;

    return _KhatmaDetailContent(
      khatma: khatma,
      completedHizb: completedHizb,
      completedCount: completedCount,
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
    );
  }
}

class _KhatmaDetailContent extends StatelessWidget {
  final Khatma khatma;
  final Set<int> completedHizb;
  final int completedCount;
  final Future<void> Function(int) onToggle;

  const _KhatmaDetailContent({
    required this.khatma,
    required this.completedHizb,
    required this.completedCount,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(khatma.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            onPressed: () => context.push('/mushaf/hafs'),
            tooltip: 'Ouvrir le Mushaf',
          ),
        ],
      ),
      body: Column(
        children: [
          _ProgressHeader(
            completed: completedCount,
            total: AppConstants.totalHizb,
            isGroup: khatma.isGroup,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: AppConstants.totalHizb,
              itemBuilder: (context, i) {
                final hizbNum = i + 1;
                final isCompleted = completedHizb.contains(hizbNum);
                final assignedTo = khatma.hizbAssignments[hizbNum] ?? '';
                final isMine = assignedTo == 'Moi' || assignedTo.isEmpty;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    value: isCompleted,
                    onChanged: isMine
                        ? (_) => onToggle(hizbNum)
                        : null,
                    title: Text(
                      'Hizb $hizbNum',
                      style: TextStyle(
                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted ? AppTheme.primaryGreen : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          QuranHizbData.hizbList[i]['range'] ?? '',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                        if (assignedTo.isNotEmpty)
                          Text(
                            'Assigné à: $assignedTo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    secondary: isCompleted
                        ? Icon(Icons.check_circle, color: AppTheme.primaryGreen)
                        : null,
                    activeColor: AppTheme.primaryGreen,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int completed;
  final int total;
  final bool isGroup;

  const _ProgressHeader({
    required this.completed,
    required this.total,
    required this.isGroup,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hizb complétés',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '$completed / $total',
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
            minHeight: 8,
          ),
          if (completed == total && total > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, color: AppTheme.accentGold),
                  const SizedBox(width: 8),
                  Text(
                    'Khatma terminée ! ماشاء الله',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold,
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
