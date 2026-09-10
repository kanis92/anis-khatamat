import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/course.dart';
import '../models/course_module.dart';
import '../models/lesson.dart';
import '../models/user_progress.dart';
import '../services/formations_api_service.dart';

/// Schéma Firestore:
/// courses/{courseId}
///   modules/{moduleId}
///   lessons/{lessonId}
/// users/{userId}/formationProgress/{pathId}
///
/// Progress writes are server-authoritative via API.
/// Progress reads use Firestore streams for real-time updates.
class FormationsRepository {
  final FirebaseFirestore _db;
  final FormationsApiService _apiService;

  FormationsRepository({
    required FirebaseFirestore db,
    required FormationsApiService apiService,
  }) : _db = db,
       _apiService = apiService;

  // ─── Collections ──────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _courses =>
      _db.collection('courses');

  CollectionReference<Map<String, dynamic>> _modules(String courseId) =>
      _courses.doc(courseId).collection('modules');

  CollectionReference<Map<String, dynamic>> _lessons(String courseId) =>
      _courses.doc(courseId).collection('lessons');

  // ─── Courses ──────────────────────────────────────────────────────────────

  /// Catalogue publié — une seule égalité Firestore (`isPublished`).
  ///
  /// Pas de `orderBy('createdAt')` : ce champ manque sur d'anciens documents
  /// et l'index composite n'est pas garanti. Le tri est local.
  Stream<List<Course>> watchPublishedCourses() {
    return _courses
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map(_coursesFromSnapshot);
  }

  Stream<List<Course>> watchCoursesByCategory(CourseCategory category) {
    return watchPublishedCourses().map(
      (courses) =>
          courses.where((course) => course.category == category).toList(),
    );
  }

  /// Filtre local du catalogue publié. Évite l'index composite
  /// `isPublished + pillarId` dont l'absence produit un échec (ou un
  /// résultat vide selon l'environnement) alors que les documents existent.
  Stream<List<Course>> watchCoursesByPillar(String pillarId) {
    return watchPublishedCourses().map(
      (courses) =>
          courses.where((course) => course.pillarId == pillarId).toList(),
    );
  }

  List<Course> _coursesFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final courses =
        snapshot.docs
            .map((doc) => Course.fromFirestore(doc.id, doc.data()))
            .toList();
    courses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return courses;
  }

  Future<Course?> getCourse(String courseId) async {
    final doc = await _courses.doc(courseId).get();
    if (!doc.exists) return null;
    return Course.fromFirestore(doc.id, doc.data()!);
  }

  // ─── Modules ──────────────────────────────────────────────────────────────

  Future<List<CourseModule>> getModules(String courseId) async {
    final snap = await _modules(courseId).get();
    final modules =
        snap.docs
            .map((d) => CourseModule.fromFirestore(d.id, d.data()))
            .toList();
    modules.sort((a, b) => a.order.compareTo(b.order));
    return modules;
  }

  // ─── Lessons ──────────────────────────────────────────────────────────────

  Future<List<Lesson>> getLessons(String courseId) async {
    final snap = await _lessons(courseId).get();
    final lessons =
        snap.docs.map((d) => Lesson.fromFirestore(d.id, d.data())).toList();
    lessons.sort((a, b) => a.order.compareTo(b.order));
    return lessons;
  }

  Future<List<Lesson>> getLessonsForModule(
    String courseId,
    String moduleId,
  ) async {
    final lessons = await getLessons(courseId);
    return lessons.where((lesson) => lesson.moduleId == moduleId).toList();
  }

  Future<Lesson?> getLesson(String courseId, String lessonId) async {
    final doc = await _lessons(courseId).doc(lessonId).get();
    if (!doc.exists) return null;
    return Lesson.fromFirestore(doc.id, doc.data()!);
  }

  // ─── Progress ─────────────────────────────────────────────────────────────
  // Personal Formation progress is server-authoritative via REST API only.
  // No direct Firestore reads or writes.

  /// Get user's progress for a specific course (via API)
  Future<UserCourseProgress?> getProgress(String courseId) async {
    final apiProgress = await _apiService.getProgress(courseId);
    if (apiProgress == null) return null;

    return UserCourseProgress(
      userId: apiProgress.pathId, // Note: API uses pathId as courseId
      courseId: apiProgress.pathId,
      currentLessonId: apiProgress.lastLessonId,
      completedLessonIds: apiProgress.completedLessonIds.toSet(),
      lastAccessedAt: apiProgress.lastAccessedAt,
    );
  }

  /// Mark lesson as completed (server-authoritative)
  Future<void> markLessonCompleted({
    required String courseId,
    required String lessonId,
  }) async {
    await _apiService.completeLesson(courseId, lessonId);
  }

  /// Update current lesson (server-authoritative)
  Future<void> updateCurrentLesson({
    required String courseId,
    required String lessonId,
  }) async {
    await _apiService.openLesson(courseId, lessonId);
  }

  /// Quiz scores: REMOVED — server-authoritative progress contract.
  /// If quiz scoring is needed, route through REST API.
  /// Direct Firestore writes violate the ONE AUTHORITY invariant.

  /// Get all formation progress records for the user (via API)
  /// Server-authoritative - no direct Firestore read
  Future<List<UserCourseProgress>> getAllProgress(String userId) async {
    final apiProgressList = await _apiService.getAllProgress();

    return apiProgressList.map((apiProgress) {
      return UserCourseProgress(
        userId: userId,
        courseId: apiProgress.pathId,
        currentLessonId: apiProgress.lastLessonId,
        completedLessonIds: apiProgress.completedLessonIds.toSet(),
        lastAccessedAt: apiProgress.lastAccessedAt,
      );
    }).toList();
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
