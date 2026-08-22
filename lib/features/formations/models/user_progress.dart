import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserCourseProgress extends Equatable {
  final String userId;
  final String courseId;
  final Set<String> completedLessonIds;
  final String? currentLessonId;
  final DateTime? lastAccessedAt;
  final Map<String, int> quizScores; // lessonId -> score %

  const UserCourseProgress({
    required this.userId,
    required this.courseId,
    this.completedLessonIds = const {},
    this.currentLessonId,
    this.lastAccessedAt,
    this.quizScores = const {},
  });

  double progressPercent(int totalLessons) {
    if (totalLessons == 0) return 0;
    return (completedLessonIds.length / totalLessons).clamp(0.0, 1.0);
  }

  bool isCompleted(int totalLessons) =>
      totalLessons > 0 && completedLessonIds.length >= totalLessons;

  bool isLessonCompleted(String lessonId) =>
      completedLessonIds.contains(lessonId);

  UserCourseProgress copyWithCompletedLesson(String lessonId) =>
      UserCourseProgress(
        userId: userId,
        courseId: courseId,
        completedLessonIds: {...completedLessonIds, lessonId},
        currentLessonId: currentLessonId,
        lastAccessedAt: DateTime.now(),
        quizScores: quizScores,
      );

  UserCourseProgress copyWithQuizScore(String lessonId, int score) =>
      UserCourseProgress(
        userId: userId,
        courseId: courseId,
        completedLessonIds: completedLessonIds,
        currentLessonId: currentLessonId,
        lastAccessedAt: lastAccessedAt,
        quizScores: {...quizScores, lessonId: score},
      );

  factory UserCourseProgress.fromFirestore(Map<String, dynamic> d) =>
      UserCourseProgress(
        userId: d['userId'] as String,
        courseId: d['courseId'] as String,
        completedLessonIds: Set<String>.from(
          d['completedLessonIds'] as List? ?? [],
        ),
        currentLessonId: d['currentLessonId'] as String?,
        lastAccessedAt: (d['lastAccessedAt'] as Timestamp?)?.toDate(),
        quizScores: Map<String, int>.from(d['quizScores'] as Map? ?? {}),
      );

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'courseId': courseId,
    'completedLessonIds': completedLessonIds.toList(),
    'currentLessonId': currentLessonId,
    'lastAccessedAt':
        lastAccessedAt != null ? Timestamp.fromDate(lastAccessedAt!) : null,
    'quizScores': quizScores,
  };

  @override
  List<Object?> get props => [userId, courseId, completedLessonIds];
}
