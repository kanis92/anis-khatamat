import 'dart:ui';

import '../models/course.dart';

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
