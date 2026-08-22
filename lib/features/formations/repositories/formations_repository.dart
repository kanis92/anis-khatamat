import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/course.dart';
import '../models/course_module.dart';
import '../models/lesson.dart';
import '../models/user_progress.dart';

/// Schéma Firestore:
/// courses/{courseId}
///   modules/{moduleId}
///   lessons/{lessonId}
/// users/{userId}/courseProgress/{courseId}
class FormationsRepository {
  final FirebaseFirestore _db;

  FormationsRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  // ─── Collections ──────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _courses =>
      _db.collection('courses');

  CollectionReference<Map<String, dynamic>> _modules(String courseId) =>
      _courses.doc(courseId).collection('modules');

  CollectionReference<Map<String, dynamic>> _lessons(String courseId) =>
      _courses.doc(courseId).collection('lessons');

  CollectionReference<Map<String, dynamic>> _progress(String userId) =>
      _db.collection('users').doc(userId).collection('courseProgress');

  // ─── Courses ──────────────────────────────────────────────────────────────

  Stream<List<Course>> watchPublishedCourses() {
    return _courses
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => Course.fromFirestore(d.id, d.data())).toList(),
        );
  }

  Stream<List<Course>> watchCoursesByCategory(CourseCategory category) {
    return _courses
        .where('isPublished', isEqualTo: true)
        .where('category', isEqualTo: category.name)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => Course.fromFirestore(d.id, d.data())).toList(),
        );
  }

  Future<Course?> getCourse(String courseId) async {
    final doc = await _courses.doc(courseId).get();
    if (!doc.exists) return null;
    return Course.fromFirestore(doc.id, doc.data()!);
  }

  // ─── Modules ──────────────────────────────────────────────────────────────

  Future<List<CourseModule>> getModules(String courseId) async {
    final snap = await _modules(courseId).orderBy('order').get();
    return snap.docs
        .map((d) => CourseModule.fromFirestore(d.id, d.data()))
        .toList();
  }

  // ─── Lessons ──────────────────────────────────────────────────────────────

  Future<List<Lesson>> getLessons(String courseId) async {
    final snap = await _lessons(courseId).orderBy('order').get();
    return snap.docs.map((d) => Lesson.fromFirestore(d.id, d.data())).toList();
  }

  Future<List<Lesson>> getLessonsForModule(
    String courseId,
    String moduleId,
  ) async {
    final snap =
        await _lessons(
          courseId,
        ).where('moduleId', isEqualTo: moduleId).orderBy('order').get();
    return snap.docs.map((d) => Lesson.fromFirestore(d.id, d.data())).toList();
  }

  Future<Lesson?> getLesson(String courseId, String lessonId) async {
    final doc = await _lessons(courseId).doc(lessonId).get();
    if (!doc.exists) return null;
    return Lesson.fromFirestore(doc.id, doc.data()!);
  }

  // ─── Progress ─────────────────────────────────────────────────────────────

  Stream<UserCourseProgress?> watchProgress(String userId, String courseId) {
    return _progress(userId).doc(courseId).snapshots().map((d) {
      if (!d.exists) return null;
      return UserCourseProgress.fromFirestore(d.data()!);
    });
  }

  Future<UserCourseProgress?> getProgress(
    String userId,
    String courseId,
  ) async {
    final doc = await _progress(userId).doc(courseId).get();
    if (!doc.exists) return null;
    return UserCourseProgress.fromFirestore(doc.data()!);
  }

  Future<void> markLessonCompleted({
    required String userId,
    required String courseId,
    required String lessonId,
  }) async {
    final ref = _progress(userId).doc(courseId);
    await ref.set({
      'userId': userId,
      'courseId': courseId,
      'completedLessonIds': FieldValue.arrayUnion([lessonId]),
      'currentLessonId': lessonId,
      'lastAccessedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveQuizScore({
    required String userId,
    required String courseId,
    required String lessonId,
    required int score,
  }) async {
    final ref = _progress(userId).doc(courseId);
    await ref.set({
      'userId': userId,
      'courseId': courseId,
      'quizScores.$lessonId': score,
      'lastAccessedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateCurrentLesson({
    required String userId,
    required String courseId,
    required String lessonId,
  }) async {
    await _progress(userId).doc(courseId).set({
      'userId': userId,
      'courseId': courseId,
      'currentLessonId': lessonId,
      'lastAccessedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Progress de tous les cours d'un user
  Future<List<UserCourseProgress>> getAllProgress(String userId) async {
    final snap = await _progress(userId).get();
    return snap.docs
        .map((d) => UserCourseProgress.fromFirestore(d.data()))
        .toList();
  }

  // ─── Admin: seed data (debug only) ───────────────────────────────────────

  Future<void> seedSampleCourse() async {
    assert(kDebugMode, 'seedSampleCourse doit être appelé en debug uniquement');
    final courseRef = _courses.doc('tajweed-bases');
    await courseRef.set(
      Course(
        id: 'tajweed-bases',
        title: 'Bases du Tajweed',
        description:
            'Apprenez les règles fondamentales du Tajweed pour une récitation correcte du Coran.',
        level: CourseLevel.beginner,
        category: CourseCategory.tajweed,
        instructor: 'Sheikh Ahmad',
        totalLessons: 6,
        totalDurationMinutes: 90,
        tags: ['tajweed', 'récitation', 'débutant'],
        linkedFeatures: [
          const LinkedFeature(
            label: 'Pratiquer avec le Mushaf',
            route: '/mushaf',
          ),
          const LinkedFeature(label: 'Créer une Khatma', route: '/khatma'),
        ],
        createdAt: DateTime.now(),
      ).toFirestore(),
    );

    final moduleRef = _modules('tajweed-bases').doc('module-1');
    await moduleRef.set(
      CourseModule(
        id: 'module-1',
        courseId: 'tajweed-bases',
        title: 'Introduction et Makharij',
        order: 1,
        lessonIds: ['lesson-1', 'lesson-2', 'lesson-3'],
      ).toFirestore(),
    );

    final lessons = [
      Lesson(
        id: 'lesson-1',
        moduleId: 'module-1',
        courseId: 'tajweed-bases',
        title: 'Introduction au Tajweed',
        type: LessonType.text,
        contentText:
            '''## Qu\'est-ce que le Tajweed ?\n\nLe Tajweed (تجويد) est la science qui enseigne la bonne façon de réciter le Coran.\n\n### Pourquoi apprendre le Tajweed ?\n\n- Préserver le sens des versets\n- Honorer la parole d\'Allah\n- Suivre la Sunna du Prophète ﷺ\n\n### Les 4 niveaux de Tajweed\n\n1. Al-Tartil : Récitation lente et distincte\n2. Al-Tahqiq : Récitation très lente pour l\'apprentissage\n3. Al-Hadr : Récitation rapide\n4. Al-Tadwir : Rythme moyen''',
        durationMinutes: 10,
        order: 1,
      ),
      Lesson(
        id: 'lesson-2',
        moduleId: 'module-1',
        courseId: 'tajweed-bases',
        title: 'Les Makharij (points d\'articulation)',
        type: LessonType.text,
        contentText:
            '## Les Makharij\n\nChaque lettre arabe a un point d\'articulation précis...',
        durationMinutes: 15,
        order: 2,
        quiz: [
          const QuizQuestion(
            question: 'Combien y a-t-il de points d\'articulation principaux ?',
            options: ['3', '5', '7', '10'],
            correctIndex: 1,
            explanation:
                'Il y a 5 points d\'articulation principaux : la gorge, la langue, les lèvres, le nez et la cavité buccale.',
          ),
        ],
      ),
      Lesson(
        id: 'lesson-3',
        moduleId: 'module-1',
        courseId: 'tajweed-bases',
        title: 'La Madd (prolongation)',
        type: LessonType.text,
        contentText:
            '## La Madd\n\nLa Madd est la prolongation de la voyelle...',
        durationMinutes: 12,
        order: 3,
      ),
    ];

    for (final lesson in lessons) {
      await _lessons('tajweed-bases').doc(lesson.id).set(lesson.toFirestore());
    }
  }
}
