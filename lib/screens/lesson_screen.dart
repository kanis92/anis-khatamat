import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/extensions/l10n_extensions.dart';
import '../core/theme/app_theme.dart';
import '../features/formations/models/lesson.dart';
import '../features/formations/models/saved_formation_item.dart';
import '../features/formations/presentation/course_content_resolver.dart';
import '../features/formations/providers/formations_providers.dart';
import '../features/formations/providers/saved_formations_providers.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String lessonId;

  const LessonScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    // Record that user opened this lesson
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(formationsNotifierProvider.notifier).updateCurrentLesson(
        courseId: widget.courseId,
        lessonId: widget.lessonId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);

    final lessonAsync = ref.watch(lessonDetailProvider(
      LessonParams(widget.courseId, widget.lessonId),
    ));

    final progressAsync = ref.watch(courseProgressProvider(widget.courseId));

    return lessonAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            l10n.errorLoadingFormations,
            style: TextStyle(color: Colors.red[700]),
          ),
        ),
      ),
      data: (lesson) {
        if (lesson == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Lesson not found')),
          );
        }

        final content = LessonContentResolver.resolve(lesson, locale);
        final isCompleted = progressAsync.valueOrNull?.completedLessonIds.contains(lesson.id) ?? false;

        return Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/formations/${widget.courseId}');
                }
              },
            ),
            title: Text(content.title),
            actions: [
              _SaveLessonButton(
                courseId: widget.courseId,
                lessonId: widget.lessonId,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Extra bottom padding for bottom navigation
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Description (if present)
                if (content.description != null && content.description!.isNotEmpty) ...[
                  Text(
                    content.description!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Main content
                if (content.contentText != null && content.contentText!.isNotEmpty)
                  _ContentSection(text: content.contentText!),

                // Summary section
                if (content.summary.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SummarySection(summaryPoints: content.summary),
                ],

                // Action to apply
                if (content.actionToApply != null && content.actionToApply!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _ActionSection(action: content.actionToApply!),
                ],

                // Quran reference
                if (lesson.quranRef != null) ...[
                  const SizedBox(height: 24),
                  _QuranReferenceSection(quranRef: lesson.quranRef!),
                ],

                // Quiz (if present) - Note: Quiz data exists but interactive UI deferred
                // Hiding for now to avoid broken promise
                // if (lesson.quiz.isNotEmpty) ...[
                //   const SizedBox(height: 24),
                //   _QuizSection(quiz: lesson.quiz),
                // ],

                // Completion button
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCompleted || _isCompleting
                        ? null
                        : () => _handleComplete(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted
                          ? Colors.grey[400]
                          : AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isCompleting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isCompleted
                                ? l10n.completedLearningPath
                                : l10n.markAsCompleted,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                // Navigation
                const SizedBox(height: 16),
                _NavigationButtons(
                  courseId: widget.courseId,
                  currentLessonId: widget.lessonId,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleComplete() async {
    if (_isCompleting) return;

    setState(() => _isCompleting = true);

    try {
      await ref.read(formationsNotifierProvider.notifier).markLessonCompleted(
        courseId: widget.courseId,
        lessonId: widget.lessonId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.completedLearningPath),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }
}

class _ContentSection extends StatelessWidget {
  final String text;

  const _ContentSection({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: MarkdownBody(
        data: text,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          h1: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
          h2: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
          h3: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          strong: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.6,
          ),
          listBullet: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final List<String> summaryPoints;

  const _SummarySection({required this.summaryPoints});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.creamLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.lessonSummary,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 12),
          for (final point in summaryPoints)
            Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    point,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  final String action;

  const _ActionSection({required this.action});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.accentGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.lessonAction,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            action,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _QuranReferenceSection extends StatelessWidget {
  final QuranReference quranRef;

  const _QuranReferenceSection({required this.quranRef});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.lessonQuran,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatQuranReference(quranRef),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              // Navigate to Mushaf with this reference
              context.push(
                '/mushaf/hafs',
                extra: {'surah': quranRef.surah, 'verse': quranRef.startAyah},
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: BorderSide(color: AppTheme.primaryGreen),
            ),
            child: const Text('Ouvrir dans le Mushaf'),
          ),
        ],
      ),
    );
  }

  String _formatQuranReference(QuranReference ref) {
    if (ref.startAyah == null) {
      return 'Sourate ${ref.surah}';
    } else if (ref.endAyah == null) {
      return 'Sourate ${ref.surah}, Verset ${ref.startAyah}';
    } else {
      return 'Sourate ${ref.surah}, Versets ${ref.startAyah}-${ref.endAyah}';
    }
  }
}


class _NavigationButtons extends ConsumerWidget {
  final String courseId;
  final String currentLessonId;

  const _NavigationButtons({
    required this.courseId,
    required this.currentLessonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lessonsAsync = ref.watch(courseLessonsProvider(courseId));

    return lessonsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (lessons) {
        final sortedLessons = [...lessons]
          ..sort((a, b) => a.order.compareTo(b.order));
        final currentIndex =
            sortedLessons.indexWhere((l) => l.id == currentLessonId);

        if (currentIndex == -1) return const SizedBox.shrink();

        final hasPrevious = currentIndex > 0;
        final hasNext = currentIndex < sortedLessons.length - 1;

        return Row(
          children: [
            if (hasPrevious)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final previousLesson = sortedLessons[currentIndex - 1];
                    context.go(
                      '/formations/$courseId/lessons/${previousLesson.id}',
                      extra: {'courseId': courseId},
                    );
                  },
                  icon: const Icon(Icons.chevron_left),
                  label: Text(l10n.previousLesson),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: BorderSide(color: AppTheme.primaryGreen),
                  ),
                ),
              )
            else
              const Spacer(),

            const SizedBox(width: 16),

            if (hasNext)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final nextLesson = sortedLessons[currentIndex + 1];
                    context.go(
                      '/formations/$courseId/lessons/${nextLesson.id}',
                      extra: {'courseId': courseId},
                    );
                  },
                  icon: const Icon(Icons.chevron_right),
                  label: Text(l10n.nextLesson),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else
              const Spacer(),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SAVE LESSON BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _SaveLessonButton extends ConsumerWidget {
  const _SaveLessonButton({
    required this.courseId,
    required this.lessonId,
  });

  final String courseId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isSaved = ref.watch(
      isSavedProvider((type: SavedItemType.lesson, targetId: lessonId)),
    );

    return IconButton(
      icon: Icon(
        isSaved ? Icons.bookmark : Icons.bookmark_border,
        color: isSaved ? AppTheme.accentGold : null,
      ),
      tooltip: isSaved ? l10n.saved : l10n.saveForLater,
      onPressed: () async {
        final notifier = ref.read(savedFormationsNotifierProvider);
        await notifier.toggleSaved(
          type: SavedItemType.lesson,
          targetId: lessonId,
          courseId: courseId,
        );
      },
    );
  }
}
