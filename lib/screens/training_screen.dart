import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/extensions/l10n_extensions.dart';
import '../core/theme/app_theme.dart';
import '../features/formations/models/course.dart';
import '../features/formations/models/user_progress.dart';
import '../features/formations/models/pedagogical_pillar.dart';
import '../features/formations/presentation/course_presentation.dart';
import '../features/formations/providers/formations_providers.dart';
import '../l10n/gen_l10n/app_localizations.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final coursesAsync = ref.watch(filteredCoursesProvider);
    final progressAsync = ref.watch(allProgressProvider);
    final selectedPillar = ref.watch(selectedPillarProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.formations),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Resume section
            progressAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (allProgress) {
                if (allProgress.isEmpty) return const SizedBox.shrink();
                
                // Find the most recently accessed in-progress course
                final inProgress = allProgress
                    .where((p) => 
                        p.lastAccessedAt != null && 
                        p.completedLessonIds.isNotEmpty)
                    .toList()
                  ..sort((a, b) => 
                      b.lastAccessedAt!.compareTo(a.lastAccessedAt!));
                
                if (inProgress.isEmpty) return const SizedBox.shrink();
                
                final recent = inProgress.first;
                return coursesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (courses) {
                    final course = courses
                        .cast<Course?>()
                        .firstWhere(
                          (c) => c?.id == recent.courseId, 
                          orElse: () => null,
                        );
                    if (course == null) return const SizedBox.shrink();
                    
                    return _ResumeCard(
                      course: course,
                      progress: recent,
                    );
                  },
                );
              },
            ),
            
            // Pillar filter (V1 pedagogical taxonomy)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: _PillarFilter(
                selectedPillar: selectedPillar,
                onPillarSelected: (pillar) {
                  ref.read(selectedPillarProvider.notifier).state = pillar;
                },
              ),
            ),
            
            // Course list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: coursesAsync.when(
                loading: () => const _LoadingState(),
                error: (error, _) => _ErrorState(
                  onRetry: () => ref.invalidate(publishedCoursesProvider),
                ),
                data: (courses) {
                  if (courses.isEmpty) {
                    return const _EmptyState();
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.formations,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ...courses.map((course) {
                        return _CourseCard(course: course);
                      }),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ResumeCard extends ConsumerWidget {
  const _ResumeCard({
    required this.course,
    required this.progress,
  });

  final Course course;
  final UserCourseProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final progressPercent = progress.progressPercent(course.totalLessons);

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.1),
            AppTheme.creamLight.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_outline,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.continueLearning,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            course.localizedTitle(context),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Text(
                '${progress.completedLessonIds.length}/${course.totalLessons}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '•',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                '${(progressPercent * 100).toInt()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPercent,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryGreen),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.push(
                  '/formations/${course.id}',
                  extra: {'course': course},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.continueAction),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillarFilter extends StatelessWidget {
  const _PillarFilter({
    required this.selectedPillar,
    required this.onPillarSelected,
  });

  final PedagogicalPillar? selectedPillar;
  final ValueChanged<PedagogicalPillar?> onPillarSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _CategoryChip(
            label: l10n.all,
            isSelected: selectedPillar == null,
            onTap: () => onPillarSelected(null),
          ),
          const SizedBox(width: 8),
          ...PedagogicalPillar.values.map((pillar) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CategoryChip(
                label: CoursePresentationLabels.pillar(
                  pillar,
                  AppLocalizations.of(context)!,
                ),
                isSelected: selectedPillar == pillar,
                onTap: () => onPillarSelected(pillar),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryGreen 
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryGreen 
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends ConsumerWidget {
  const _CourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressAsync = ref.watch(courseProgressProvider(course.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        onTap: () {
          context.push(
            '/formations/${course.id}',
            extra: {'course': course},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      course.localizedCategory(context),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    course.localizedLevel(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                course.localizedTitle(context),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                course.localizedDescription(context),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${course.totalLessons} leçons',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // Progress indicator if user has started
              progressAsync.when(
                data: (progress) {
                  if (progress == null || 
                      progress.completedLessonIds.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final percent = progress.progressPercent(course.totalLessons);
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(
                              AppTheme.primaryGreen,
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(percent * 100).toInt()}% terminé',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noFormationsAvailable,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.errorLoadingFormations,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
