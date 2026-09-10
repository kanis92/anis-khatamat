import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/formation_search_result.dart';
import '../models/course_module.dart';
import '../models/lesson.dart';
import '../services/formation_search_service.dart';
import 'formations_providers.dart';

/// Current search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Search results based on current query and loaded data
/// Returns AsyncValue to distinguish between:
/// - data([]) = genuine zero results
/// - error = upstream provider failure
final formationSearchResultsProvider =
    Provider<AsyncValue<List<FormationSearchResult>>>((ref) {
  final query = ref.watch(searchQueryProvider);

  if (query.trim().length < 2) {
    return const AsyncValue.data([]);
  }

  // Watch canonical data and propagate errors
  final coursesAsync = ref.watch(publishedCoursesProvider);

  return coursesAsync.when(
    data: (courses) {
      if (courses.isEmpty) {
        return const AsyncValue.data([]);
      }

      // Build modules map
      final courseModulesMap = <String, List<CourseModule>>{};
      for (final course in courses) {
        final modulesAsync = ref.watch(courseModulesProvider(course.id));
        courseModulesMap[course.id] = modulesAsync.valueOrNull ?? [];
      }

      // Build lessons map
      final courseLessonsMap = <String, List<Lesson>>{};
      for (final course in courses) {
        final lessonsAsync = ref.watch(courseLessonsProvider(course.id));
        courseLessonsMap[course.id] = lessonsAsync.valueOrNull ?? [];
      }

      // Get current locale (fallback to 'fr')
      // In a real implementation, this would come from a locale provider
      const locale = 'fr';

      final results = FormationSearchService.search(
        query: query,
        courses: courses,
        courseModules: courseModulesMap,
        courseLessons: courseLessonsMap,
        locale: locale,
      );

      return AsyncValue.data(results);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});
