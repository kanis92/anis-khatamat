import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/formation_search_result.dart';
import '../models/course_module.dart';
import '../models/lesson.dart';
import '../services/formation_search_service.dart';
import 'formations_providers.dart';

/// Current search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Search results based on current query and loaded data
final formationSearchResultsProvider =
    Provider<List<FormationSearchResult>>((ref) {
  final query = ref.watch(searchQueryProvider);

  if (query.trim().length < 2) {
    return [];
  }

  // Watch canonical data
  final coursesAsync = ref.watch(publishedCoursesProvider);
  final courses = coursesAsync.valueOrNull ?? [];

  if (courses.isEmpty) {
    return [];
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

  return FormationSearchService.search(
    query: query,
    courses: courses,
    courseModules: courseModulesMap,
    courseLessons: courseLessonsMap,
    locale: locale,
  );
});
