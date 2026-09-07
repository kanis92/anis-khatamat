import 'package:anis_khatamat/features/formations/models/user_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserCourseProgress', () {
    test('progressPercent returns 0 for zero total lessons', () {
      const progress = UserCourseProgress(
        userId: 'user1',
        courseId: 'course1',
        completedLessonIds: {'lesson1'},
      );

      expect(progress.progressPercent(0), 0.0);
    });

    test('progressPercent calculates correctly', () {
      const progress = UserCourseProgress(
        userId: 'user1',
        courseId: 'course1',
        completedLessonIds: {'lesson1', 'lesson2'},
      );

      expect(progress.progressPercent(10), 0.2);
      expect(progress.progressPercent(4), 0.5);
      expect(progress.progressPercent(2), 1.0);
    });

    test('progressPercent clamps to 1.0', () {
      const progress = UserCourseProgress(
        userId: 'user1',
        courseId: 'course1',
        completedLessonIds: {'lesson1', 'lesson2', 'lesson3'},
      );

      expect(progress.progressPercent(2), 1.0);
    });

    test('isCompleted returns true when all lessons completed', () {
      const progress = UserCourseProgress(
        userId: 'user1',
        courseId: 'course1',
        completedLessonIds: {'lesson1', 'lesson2'},
      );

      expect(progress.isCompleted(2), true);
      expect(progress.isCompleted(3), false);
    });

    test('isCompleted returns false for zero total lessons', () {
      const progress = UserCourseProgress(
        userId: 'user1',
        courseId: 'course1',
        completedLessonIds: {'lesson1'},
      );

      expect(progress.isCompleted(0), false);
    });

    test('isLessonCompleted checks correctly', () {
      const progress = UserCourseProgress(
        userId: 'user1',
        courseId: 'course1',
        completedLessonIds: {'lesson1', 'lesson3'},
      );

      expect(progress.isLessonCompleted('lesson1'), true);
      expect(progress.isLessonCompleted('lesson2'), false);
      expect(progress.isLessonCompleted('lesson3'), true);
    });

    test('copyWithCompletedLesson adds lesson correctly', () {
      const progress = UserCourseProgress(
        userId: 'user1',
        courseId: 'course1',
        completedLessonIds: {'lesson1'},
        currentLessonId: 'lesson2',
      );

      final updated = progress.copyWithCompletedLesson('lesson2');

      expect(updated.completedLessonIds, {'lesson1', 'lesson2'});
      expect(updated.currentLessonId, 'lesson2');
      expect(updated.userId, 'user1');
      expect(updated.courseId, 'course1');
    });

    test('copyWithCompletedLesson is idempotent', () {
      const progress = UserCourseProgress(
        userId: 'user1',
        courseId: 'course1',
        completedLessonIds: {'lesson1'},
      );

      final updated1 = progress.copyWithCompletedLesson('lesson1');
      final updated2 = updated1.copyWithCompletedLesson('lesson1');

      expect(updated2.completedLessonIds, {'lesson1'});
      expect(updated2.completedLessonIds.length, 1);
    });
  });
}
