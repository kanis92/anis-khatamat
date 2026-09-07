import 'dart:ui';

import '../models/course.dart';
import '../models/course_module.dart';
import '../models/lesson.dart';

class ResolvedCourseContent {
  const ResolvedCourseContent({
    required this.title,
    required this.description,
    required this.linkedFeatures,
    required this.source,
  });

  final String title;
  final String description;
  final List<LinkedFeature> linkedFeatures;

  /// `ar` | `en` | `fr` | `legacy`
  final String source;
}

class ResolvedModuleContent {
  const ResolvedModuleContent({
    required this.title,
    required this.description,
    required this.source,
  });

  final String title;
  final String? description;
  final String source;
}

class ResolvedLessonContent {
  const ResolvedLessonContent({
    required this.title,
    required this.description,
    required this.contentText,
    required this.summary,
    required this.actionToApply,
    required this.source,
  });

  final String title;
  final String? description;
  final String? contentText;
  final List<String> summary;
  final String? actionToApply;
  final String source;
}

/// requested locale → French translation → legacy French fields.
class CourseContentResolver {
  const CourseContentResolver._();

  static ResolvedCourseContent resolve(Course course, Locale locale) {
    final requested = locale.languageCode;
    final translations = course.translations;

    final requestedT = translations?[requested];
    if (requestedT != null && requestedT.title.isNotEmpty) {
      return ResolvedCourseContent(
        title: requestedT.title,
        description: requestedT.description,
        linkedFeatures: requestedT.linkedFeatures.isNotEmpty
            ? requestedT.linkedFeatures
            : course.linkedFeatures,
        source: requested,
      );
    }

    final frT = translations?['fr'];
    if (frT != null && frT.title.isNotEmpty) {
      return ResolvedCourseContent(
        title: frT.title,
        description: frT.description,
        linkedFeatures: frT.linkedFeatures.isNotEmpty
            ? frT.linkedFeatures
            : course.linkedFeatures,
        source: 'fr',
      );
    }

    return ResolvedCourseContent(
      title: course.title,
      description: course.description,
      linkedFeatures: course.linkedFeatures,
      source: 'legacy',
    );
  }
}

class ModuleContentResolver {
  const ModuleContentResolver._();

  static ResolvedModuleContent resolve(CourseModule module, Locale locale) {
    final requested = locale.languageCode;
    final translations = module.translations;

    final requestedT = translations?[requested];
    if (requestedT != null && requestedT.title.isNotEmpty) {
      return ResolvedModuleContent(
        title: requestedT.title,
        description: requestedT.description,
        source: requested,
      );
    }

    final frT = translations?['fr'];
    if (frT != null && frT.title.isNotEmpty) {
      return ResolvedModuleContent(
        title: frT.title,
        description: frT.description,
        source: 'fr',
      );
    }

    return ResolvedModuleContent(
      title: module.title,
      description: module.description,
      source: 'legacy',
    );
  }
}

class LessonContentResolver {
  const LessonContentResolver._();

  static ResolvedLessonContent resolve(Lesson lesson, Locale locale) {
    final requested = locale.languageCode;
    final translations = lesson.translations;

    final requestedT = translations?[requested];
    if (requestedT != null && requestedT.title.isNotEmpty) {
      return ResolvedLessonContent(
        title: requestedT.title,
        description: requestedT.description,
        contentText: requestedT.contentText,
        summary: requestedT.summary,
        actionToApply: requestedT.actionToApply,
        source: requested,
      );
    }

    final frT = translations?['fr'];
    if (frT != null && frT.title.isNotEmpty) {
      return ResolvedLessonContent(
        title: frT.title,
        description: frT.description,
        contentText: frT.contentText,
        summary: frT.summary,
        actionToApply: frT.actionToApply,
        source: 'fr',
      );
    }

    return ResolvedLessonContent(
      title: lesson.title,
      description: lesson.description,
      contentText: lesson.contentText,
      summary: lesson.summary,
      actionToApply: lesson.actionToApply,
      source: 'legacy',
    );
  }
}
