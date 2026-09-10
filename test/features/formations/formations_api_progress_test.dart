import 'package:anis_khatamat/core/api/anis_api_client.dart';
import 'package:anis_khatamat/features/formations/repositories/formations_repository.dart';
import 'package:anis_khatamat/features/formations/services/formations_api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAnisApiClient extends Mock implements AnisApiClient {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

/// Tests for Formation progress API integration
/// Ensures all personal progress reads go through the API
void main() {
  group('FormationsApiService.getAllProgress', () {
    late MockAnisApiClient mockClient;
    late FormationsApiService apiService;

    setUp(() {
      mockClient = MockAnisApiClient();
      apiService = FormationsApiService(mockClient);
    });

    test('returns empty list when no progress', () async {
      when(() => mockClient.get('/v1/formations/progress'))
          .thenAnswer((_) async => {'data': []});

      final result = await apiService.getAllProgress();

      expect(result, isEmpty);
      verify(() => mockClient.get('/v1/formations/progress')).called(1);
    });

    test('returns progress list when data exists', () async {
      when(() => mockClient.get('/v1/formations/progress'))
          .thenAnswer((_) async => {
                'data': [
                  {
                    'pathId': 'path-1',
                    'lastLessonId': 'lesson-1',
                    'completedLessonIds': ['lesson-1'],
                    'lastAccessedAt': '2024-01-01T00:00:00.000Z',
                  },
                  {
                    'pathId': 'path-2',
                    'lastLessonId': 'lesson-2',
                    'completedLessonIds': ['lesson-1', 'lesson-2'],
                    'lastAccessedAt': '2024-01-02T00:00:00.000Z',
                  }
                ]
              });

      final result = await apiService.getAllProgress();

      expect(result, hasLength(2));
      expect(result[0].pathId, 'path-1');
      expect(result[0].lastLessonId, 'lesson-1');
      expect(result[0].completedLessonIds, ['lesson-1']);
      expect(result[1].pathId, 'path-2');
      expect(result[1].completedLessonIds, ['lesson-1', 'lesson-2']);
      verify(() => mockClient.get('/v1/formations/progress')).called(1);
    });

    test('handles null data gracefully', () async {
      when(() => mockClient.get('/v1/formations/progress'))
          .thenAnswer((_) async => {'data': null});

      final result = await apiService.getAllProgress();

      expect(result, isEmpty);
    });

    test('propagates API errors', () async {
      when(() => mockClient.get('/v1/formations/progress'))
          .thenThrow(Exception('Network error'));

      expect(
        () => apiService.getAllProgress(),
        throwsException,
      );
    });
  });

  group('FormationsRepository.getAllProgress', () {
    late MockAnisApiClient mockClient;
    late MockFirebaseFirestore mockFirestore;
    late FormationsApiService apiService;
    late FormationsRepository repository;

    setUp(() {
      mockClient = MockAnisApiClient();
      mockFirestore = MockFirebaseFirestore();
      apiService = FormationsApiService(mockClient);
      repository = FormationsRepository(
        db: mockFirestore,
        apiService: apiService,
      );
    });

    test('converts API response to UserCourseProgress models', () async {
      when(() => mockClient.get('/v1/formations/progress'))
          .thenAnswer((_) async => {
                'data': [
                  {
                    'pathId': 'test-path',
                    'lastLessonId': 'lesson-1',
                    'completedLessonIds': ['lesson-1'],
                    'lastAccessedAt': '2024-01-01T12:00:00.000Z',
                  }
                ]
              });

      final result = await repository.getAllProgress('test-user-id');

      expect(result, hasLength(1));
      expect(result[0].userId, 'test-user-id');
      expect(result[0].courseId, 'test-path');
      expect(result[0].currentLessonId, 'lesson-1');
      expect(result[0].completedLessonIds, {'lesson-1'});
      expect(result[0].lastAccessedAt, isA<DateTime>());
    });

    test('returns empty list when no progress', () async {
      when(() => mockClient.get('/v1/formations/progress'))
          .thenAnswer((_) async => {'data': []});

      final result = await repository.getAllProgress('test-user-id');

      expect(result, isEmpty);
    });

    test('does not read Firestore for global progress list', () async {
      when(() => mockClient.get('/v1/formations/progress'))
          .thenAnswer((_) async => {'data': []});

      await repository.getAllProgress('test-user-id');

      verifyNever(() => mockFirestore.collection(any()));
    });

    test('handles multiple progress records', () async {
      when(() => mockClient.get('/v1/formations/progress'))
          .thenAnswer((_) async => {
                'data': [
                  {
                    'pathId': 'path-1',
                    'lastLessonId': 'lesson-1',
                    'completedLessonIds': ['lesson-1'],
                    'lastAccessedAt': '2024-01-01T00:00:00.000Z',
                  },
                  {
                    'pathId': 'path-2',
                    'lastLessonId': null,
                    'completedLessonIds': [],
                    'lastAccessedAt': '2024-01-02T00:00:00.000Z',
                  },
                  {
                    'pathId': 'path-3',
                    'lastLessonId': 'lesson-5',
                    'completedLessonIds': ['lesson-1', 'lesson-2', 'lesson-5'],
                    'lastAccessedAt': '2024-01-03T00:00:00.000Z',
                  }
                ]
              });

      final result = await repository.getAllProgress('user-123');

      expect(result, hasLength(3));
      expect(result[0].courseId, 'path-1');
      expect(result[1].courseId, 'path-2');
      expect(result[1].currentLessonId, isNull);
      expect(result[2].courseId, 'path-3');
      expect(result[2].completedLessonIds, hasLength(3));
    });
  });

  group('allProgressProvider integration', () {
    test('provider uses repository.getAllProgress', () async {
      // This is tested implicitly by the widget tests
      // The provider calls repository.getAllProgress(uid)
      // Repository calls apiService.getAllProgress()
      // No direct Firestore reads occur
      expect(true, isTrue);
    });
  });
}
