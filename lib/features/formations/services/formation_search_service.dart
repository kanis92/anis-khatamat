import '../models/course.dart';
import '../models/course_module.dart';
import '../models/lesson.dart';
import '../models/formation_search_result.dart';

/// Local search service for Formation content
class FormationSearchService {
  /// Normalize text for search matching
  /// - Lowercase
  /// - Trim/collapse whitespace
  /// - Remove common French accents
  /// - Normalize Arabic diacritics
  static String normalizeText(String text) {
    // Lowercase
    var normalized = text.toLowerCase();

    // Trim and collapse whitespace
    normalized = normalized.trim().replaceAll(RegExp(r'\s+'), ' ');

    // French accent folding
    const accentMap = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
      'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c',
    };

    for (final entry in accentMap.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }

    // Arabic diacritic normalization (remove common harakat)
    // Fatha, Damma, Kasra, Sukun, Shadda, Tanween
    normalized = normalized.replaceAll(RegExp(r'[\u064B-\u065F]'), '');

    return normalized;
  }

  /// Calculate match score for query against text
  /// Returns 0.0 for no match, higher scores for better matches
  static double calculateMatchScore(String normalizedQuery, String normalizedText) {
    if (normalizedQuery.isEmpty || normalizedText.isEmpty) {
      return 0.0;
    }

    // Exact match
    if (normalizedText == normalizedQuery) {
      return 100.0;
    }

    // Starts with query
    if (normalizedText.startsWith(normalizedQuery)) {
      return 80.0;
    }

    // Contains query as whole word
    if (normalizedText.split(' ').contains(normalizedQuery)) {
      return 60.0;
    }

    // Contains query substring
    if (normalizedText.contains(normalizedQuery)) {
      return 40.0;
    }

    // Check if all query words are present
    final queryWords = normalizedQuery.split(' ');
    final textWords = normalizedText.split(' ');
    final matchingWords = queryWords.where((qw) =>
      textWords.any((tw) => tw.contains(qw))
    ).length;

    if (matchingWords == queryWords.length) {
      return 20.0; // All words present
    } else if (matchingWords > 0) {
      return 10.0 * (matchingWords / queryWords.length); // Partial match
    }

    return 0.0;
  }

  /// Search courses, modules, and lessons
  /// Returns results sorted by relevance (highest score first)
  static List<FormationSearchResult> search({
    required String query,
    required List<Course> courses,
    required Map<String, List<CourseModule>> courseModules,
    required Map<String, List<Lesson>> courseLessons,
    required String locale, // 'fr', 'en', 'ar'
  }) {
    if (query.trim().length < 2) {
      return []; // Minimum query length
    }

    final normalizedQuery = normalizeText(query);
    final results = <FormationSearchResult>[];

    // Search courses
    for (final course in courses) {
      if (!course.isPublished) continue;

      final title = _getLocalizedFromTranslations(
        course.translations,
        (t) => t.title,
        course.title,
        locale,
      );
      final description = _getLocalizedFromTranslations(
        course.translations,
        (t) => t.description,
        course.description,
        locale,
      );

      final titleScore = calculateMatchScore(normalizedQuery, normalizeText(title));
      final descScore = calculateMatchScore(normalizedQuery, normalizeText(description));

      final score = titleScore > 0 ? titleScore : descScore * 0.5;

      if (score > 0) {
        results.add(FormationSearchResult(
          type: FormationSearchResultType.course,
          targetId: course.id,
          title: title,
          score: score,
        ));
      }
    }

    // Search modules
    for (final course in courses) {
      if (!course.isPublished) continue;

      final modules = courseModules[course.id] ?? [];
      final courseTitle = _getLocalizedFromTranslations(
        course.translations,
        (t) => t.title,
        course.title,
        locale,
      );

      for (final module in modules) {
        final title = _getLocalizedFromTranslations(
          module.translations,
          (t) => t.title,
          module.title,
          locale,
        );

        final titleScore = calculateMatchScore(normalizedQuery, normalizeText(title));

        if (titleScore > 0) {
          results.add(FormationSearchResult(
            type: FormationSearchResultType.module,
            targetId: module.id,
            title: title,
            courseId: course.id,
            courseTitle: courseTitle,
            score: titleScore * 0.9, // Slightly lower than course exact match
          ));
        }
      }
    }

    // Search lessons
    for (final course in courses) {
      if (!course.isPublished) continue;

      final lessons = courseLessons[course.id] ?? [];
      final modules = courseModules[course.id] ?? [];
      final courseTitle = _getLocalizedFromTranslations(
        course.translations,
        (t) => t.title,
        course.title,
        locale,
      );

      for (final lesson in lessons) {
        final title = _getLocalizedFromTranslations(
          lesson.translations,
          (t) => t.title,
          lesson.title,
          locale,
        );

        final titleScore = calculateMatchScore(normalizedQuery, normalizeText(title));

        if (titleScore > 0) {
          // Find parent module
          final module = modules.where((m) => m.id == lesson.moduleId).firstOrNull;
          final moduleTitle = module != null
              ? _getLocalizedFromTranslations(
                  module.translations,
                  (t) => t.title,
                  module.title,
                  locale,
                )
              : null;

          results.add(FormationSearchResult(
            type: FormationSearchResultType.lesson,
            targetId: lesson.id,
            title: title,
            courseId: course.id,
            courseTitle: courseTitle,
            moduleTitle: moduleTitle,
            score: titleScore * 0.95, // Lessons slightly favored over modules
          ));
        }
      }
    }

    // Sort by score (descending)
    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }

  static String _getLocalizedFromTranslations<T>(
    Map<String, T>? translations,
    String Function(T) getter,
    String fallback,
    String locale,
  ) {
    if (translations == null) return fallback;
    final translation = translations[locale];
    if (translation == null) return fallback;
    return getter(translation);
  }
}
