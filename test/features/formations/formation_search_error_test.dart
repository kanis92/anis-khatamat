import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anis_khatamat/features/formations/providers/formation_search_providers.dart';
import 'package:anis_khatamat/features/formations/providers/formations_providers.dart';
import 'package:anis_khatamat/features/formations/models/formation_search_result.dart';
import 'package:anis_khatamat/features/formations/models/course.dart';

void main() {
  group('Formation Search Error Semantics', () {
    test('upstream provider error propagates as AsyncError, not empty results', () async {
      final container = ProviderContainer(
        overrides: [
          // Simulate upstream provider failure
          publishedCoursesProvider.overrideWith(
            (ref) => Stream.error(Exception('Firestore connection failed')),
          ),
        ],
      );

      // Set a valid search query
      container.read(searchQueryProvider.notifier).state = 'ablutions';

      // Wait for async state to settle and catch expected error
      try {
        await container.read(publishedCoursesProvider.future);
      } catch (_) {
        // Expected error
      }
      
      final searchResultsAsync = container.read(formationSearchResultsProvider);

      // INVARIANT: upstream error must NOT become AsyncValue.data([])
      expect(searchResultsAsync.hasError, true);
      expect(searchResultsAsync.isLoading, false);
      
      // Verify it's NOT a successful empty result
      expect(
        searchResultsAsync.whenOrNull(data: (results) => results),
        isNull,
      );

      container.dispose();
    });

    test('genuine zero results returns AsyncValue.data([])', () async {
      final container = ProviderContainer(
        overrides: [
          // Provide valid empty data (stream with empty list)
          publishedCoursesProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
        ],
      );

      // Set a valid search query
      container.read(searchQueryProvider.notifier).state = 'nonexistent';

      // Wait for async state to settle
      await container.read(publishedCoursesProvider.future);
      
      final searchResultsAsync = container.read(formationSearchResultsProvider);

      // Genuine zero results: hasValue = true, results = []
      expect(searchResultsAsync.hasValue, true);
      expect(searchResultsAsync.hasError, false);
      
      final results = searchResultsAsync.whenOrNull(
        data: (results) => results,
      );
      expect(results, isNotNull);
      expect(results, isEmpty);

      container.dispose();
    });

    test('short query (<2 chars) returns AsyncValue.data([])', () {
      final container = ProviderContainer();

      // Short query
      container.read(searchQueryProvider.notifier).state = 'a';

      final searchResultsAsync = container.read(formationSearchResultsProvider);

      // Short query: hasValue = true, results = []
      expect(searchResultsAsync.hasValue, true);
      expect(searchResultsAsync.hasError, false);
      
      final results = searchResultsAsync.whenOrNull(
        data: (results) => results,
      );
      expect(results, isNotNull);
      expect(results, isEmpty);

      container.dispose();
    });
  });
}
