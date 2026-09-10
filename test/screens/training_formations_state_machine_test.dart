import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:anis_khatamat/core/providers/auth_provider.dart';
import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/models/course_module.dart';
import 'package:anis_khatamat/features/formations/models/lesson.dart';
import 'package:anis_khatamat/features/formations/models/pedagogical_pillar.dart';
import 'package:anis_khatamat/features/formations/presentation/formation_resume_resolver.dart';
import 'package:anis_khatamat/features/formations/providers/formation_learning_providers.dart';
import 'package:anis_khatamat/features/formations/providers/formations_providers.dart';
import 'package:anis_khatamat/features/formations/repositories/formations_repository.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';
import 'package:anis_khatamat/screens/training_screen.dart';

/// Contrat produit : les six états Formation ne se confondent jamais.
/// Seul « authentifié + lecture réussie + zéro module » affiche
/// « Modules à venir ».
void main() {
  const pillar = PedagogicalPillar.foundationsPractice;
  const comingSoon = 'Modules à venir';

  final course = Course(
    id: 'course-foundations_practice',
    title: 'Bases & pratique',
    description: 'Preview',
    instructor: 'ANIS',
    pillarId: pillar.id,
    createdAt: DateTime(2024, 1, 1),
  );

  const moduleTitles = [
    'Bien démarrer',
    'Comprendre les fondamentaux',
    'La prière au quotidien',
    'Les ablutions et la préparation',
    'Organiser sa pratique avec constance',
  ];

  List<CourseModule> canonicalModules() => [
        for (var i = 0; i < moduleTitles.length; i++)
          CourseModule(
            id: 'module-$i',
            courseId: course.id,
            title: moduleTitles[i],
            order: i,
          ),
      ];

  Future<void> pumpTraining(
    WidgetTester tester, {
    required List<Override> overrides,
  }) async {
    final container = ProviderContainer(
      overrides: [
        // Toute construction du repository serait une lecture Firestore
        // prématurée : ce fake échoue bruyamment si le gate fuit.
        formationsRepositoryProvider.overrideWith(
          (ref) => throw StateError('Firestore read attempted before auth'),
        ),
        allProgressProvider.overrideWith((ref) async => []),
        myLearningStateProvider.overrideWith(
          (ref) async =>
              const MyLearningState(display: MyLearningDisplayState.empty),
        ),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    container.read(selectedPillarProvider.notifier).state = pillar;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TrainingScreen(),
        ),
      ),
    );
  }

  testWidgets('auth initializing shows a loader, never Modules à venir',
      (tester) async {
    final auth = StreamController<User?>();
    addTearDown(auth.close);

    await pumpTraining(
      tester,
      overrides: [authStateProvider.overrideWith((ref) => auth.stream)],
    );
    await tester.pump();

    expect(find.text(comingSoon), findsNothing);
    expect(find.text('Connexion requise'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('signed out shows the sign-in state, never Modules à venir',
      (tester) async {
    await pumpTraining(
      tester,
      overrides: [authStateProvider.overrideWith((ref) => Stream.value(null))],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(comingSoon), findsNothing);
    expect(find.text('Connexion requise'), findsOneWidget);
    expect(
      find.text('Connectez-vous pour accéder aux formations.'),
      findsOneWidget,
    );
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('authenticated + permission-denied shows an error with retry',
      (tester) async {
    await pumpTraining(
      tester,
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(_FakeUser())),
        publishedCoursesProvider.overrideWith((ref) => Stream.value([course])),
        coursesByPillarProvider(pillar.id)
            .overrideWith((ref) => Stream.value([course])),
        courseModulesProvider(course.id).overrideWith(
          (ref) async => throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'Denied',
          ),
        ),
        courseLessonsProvider(course.id).overrideWith((ref) async => []),
      ],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(comingSoon), findsNothing);
    expect(find.text('Connexion requise'), findsNothing);
    expect(
      find.text('Accès refusé aux contenus de formation.'),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('authenticated + no course for the pillar shows Modules à venir',
      (tester) async {
    await pumpTraining(
      tester,
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(_FakeUser())),
        publishedCoursesProvider.overrideWith((ref) => Stream.value([])),
        coursesByPillarProvider(pillar.id)
            .overrideWith((ref) => Stream.value([])),
      ],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(comingSoon), findsOneWidget);
  });

  testWidgets('authenticated + real modules renders the five real modules',
      (tester) async {
    await pumpTraining(
      tester,
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(_FakeUser())),
        publishedCoursesProvider.overrideWith((ref) => Stream.value([course])),
        coursesByPillarProvider(pillar.id)
            .overrideWith((ref) => Stream.value([course])),
        courseModulesProvider(course.id)
            .overrideWith((ref) async => canonicalModules()),
        courseLessonsProvider(course.id).overrideWith((ref) async => []),
      ],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(comingSoon), findsNothing);
    for (final title in moduleTitles) {
      expect(find.text(title), findsOneWidget, reason: 'missing "$title"');
    }
  });

  testWidgets(
      'signing in rebuilds the real provider graph without manual refresh',
      (tester) async {
    final auth = StreamController<User?>();
    addTearDown(auth.close);

    // Aucun provider Formation n'est stubbé ici : seul le repository l'est,
    // pour que le gate de readiness soit réellement exercé.
    await pumpTraining(
      tester,
      overrides: [
        authStateProvider.overrideWith((ref) => auth.stream),
        formationsRepositoryProvider.overrideWithValue(
          _FakeRepository(course: course, modules: canonicalModules()),
        ),
      ],
    );

    auth.add(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Connexion requise'), findsOneWidget);
    expect(find.text(comingSoon), findsNothing);

    auth.add(_FakeUser());
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Connexion requise'), findsNothing);
    expect(find.text(comingSoon), findsNothing);
    expect(find.text('Bien démarrer'), findsOneWidget);
  });
}

class _FakeUser extends Mock implements User {
  @override
  String get uid => 'preview-uid';
}

class _FakeRepository extends Mock implements FormationsRepository {
  _FakeRepository({required this.course, required this.modules});

  final Course course;
  final List<CourseModule> modules;

  @override
  Stream<List<Course>> watchPublishedCourses() => Stream.value([course]);

  @override
  Stream<List<Course>> watchCoursesByPillar(String pillarId) =>
      Stream.value(course.pillarId == pillarId ? [course] : const []);

  @override
  Future<List<CourseModule>> getModules(String courseId) async => modules;

  @override
  Future<List<Lesson>> getLessons(String courseId) async => const [];
}
