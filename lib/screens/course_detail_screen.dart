import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/extensions/l10n_extensions.dart';
import '../core/theme/app_theme.dart';
import '../features/formations/models/course.dart';
import '../features/formations/models/course_module.dart';
import '../features/formations/models/lesson.dart';
import '../features/formations/presentation/course_content_resolver.dart';
import '../features/formations/presentation/course_presentation.dart';
import '../features/formations/presentation/pillar_presentation.dart';
import '../features/formations/providers/formations_providers.dart';

class CourseDetailScreen extends ConsumerWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final content = CourseContentResolver.resolve(course, locale);
    
    final modulesAsync = ref.watch(courseModulesProvider(course.id));
    final lessonsAsync = ref.watch(courseLessonsProvider(course.id));
    final progressAsync = ref.watch(courseProgressProvider(course.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(content.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.all(20),
              color: AppTheme.creamLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pillar badge
                  if (course.pillar != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        course.pillar!.label(context),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    content.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Level
                  Text(
                    course.localizedLevel(context),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  // Description
                  const SizedBox(height: 16),
                  Text(
                    content.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  // Progress bar if any
                  progressAsync.whenData((progress) {
                    if (progress != null && course.totalLessons > 0) {
                      final percent = (progress.completedLessonIds.length / course.totalLessons * 100).round();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress.completedLessonIds.length / course.totalLessons,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryGreen,
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.progressPercent(percent),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }).value ?? const SizedBox.shrink(),

                  // CTA button
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleStartContinue(context, ref, progressAsync.value),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _getCtaLabel(context, progressAsync.value, course.totalLessons),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Programme section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.programme,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  modulesAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          l10n.errorLoadingFormations,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ),
                    data: (modules) {
                      if (modules.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              l10n.moduleCount(0),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        );
                      }

                      return lessonsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, _) => Center(child: Text(l10n.errorLoadingFormations)),
                        data: (allLessons) {
                          final progress = progressAsync.valueOrNull;
                          return Column(
                            children: modules.map((module) {
                              final moduleLessons = allLessons
                                  .where((l) => l.moduleId == module.id)
                                  .toList()
                                ..sort((a, b) => a.order.compareTo(b.order));

                              return _ModuleCard(
                                module: module,
                                lessons: moduleLessons,
                                courseId: course.id,
                                completedLessonIds: progress?.completedLessonIds.toSet() ?? {},
                              );
                            }).toList(),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCtaLabel(BuildContext context, dynamic progressValue, int totalLessons) {
    final l10n = context.l10n;
    
    if (progressValue == null) {
      return l10n.startLearningPath;
    }

    final completedCount = progressValue.completedLessonIds.length;
    if (totalLessons > 0 && completedCount >= totalLessons) {
      return l10n.completedLearningPath;
    }

    return l10n.continueLearningPath;
  }

  void _handleStartContinue(BuildContext context, WidgetRef ref, dynamic progressValue) {
    final lessons = ref.read(courseLessonsProvider(course.id)).valueOrNull ?? [];
    if (lessons.isEmpty) return;

    lessons.sort((a, b) => a.order.compareTo(b.order));

    String targetLessonId;

    if (progressValue == null || progressValue.lastLessonId == null) {
      // No progress - start with first lesson
      targetLessonId = lessons.first.id;
    } else {
      // Resume from last lesson or next incomplete
      final lastLessonId = progressValue.lastLessonId;
      final lastIndex = lessons.indexWhere((l) => l.id == lastLessonId);
      
      if (lastIndex == -1 || lastIndex >= lessons.length - 1) {
        targetLessonId = lessons.first.id;
      } else {
        targetLessonId = lessons[lastIndex + 1].id;
      }
    }

    context.push(
      '/formations/${course.id}/lessons/$targetLessonId',
      extra: {'course': course},
    );
  }
}

class _ModuleCard extends ConsumerWidget {
  final CourseModule module;
  final List<Lesson> lessons;
  final String courseId;
  final Set<String> completedLessonIds;

  const _ModuleCard({
    required this.module,
    required this.lessons,
    required this.courseId,
    required this.completedLessonIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final content = ModuleContentResolver.resolve(module, locale);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (content.description != null && content.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                content.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              l10n.lessonCount(lessons.length),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 12),
            
            // Lessons list
            ...lessons.map((lesson) {
              final isCompleted = completedLessonIds.contains(lesson.id);
              final lessonContent = LessonContentResolver.resolve(lesson, locale);

              return InkWell(
                onTap: () {
                  context.push(
                    '/formations/$courseId/lessons/${lesson.id}',
                    extra: {'courseId': courseId},
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.circle_outlined,
                        size: 20,
                        color: isCompleted ? AppTheme.primaryGreen : Colors.grey[400],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          lessonContent.title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isCompleted ? Colors.grey[600] : Colors.black87,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
