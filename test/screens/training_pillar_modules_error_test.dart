import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:anis_khatamat/core/providers/auth_provider.dart';
import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/models/pedagogical_pillar.dart';
import 'package:anis_khatamat/features/formations/presentation/formation_resume_resolver.dart';
import 'package:anis_khatamat/features/formations/providers/formation_learning_providers.dart';
import 'package:anis_khatamat/features/formations/providers/formations_providers.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';
import 'package:anis_khatamat/screens/training_screen.dart';

void main() {
  testWidgets('module permission error shows retry UI, not Modules à venir',
      (tester) async {
    final course = Course(
      id: 'course-foundations_practice',
      title: 'Bases & pratique',
      description: 'Preview',
      instructor: 'ANIS',
      pillarId: 'foundations_practice',
      createdAt: DateTime(2024, 1, 1),
    );

    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream.value(_MockFirebaseUser()),
        ),
        publishedCoursesProvider.overrideWith((ref) => Stream.value([course])),
        coursesByPillarProvider(PedagogicalPillar.foundationsPractice.id)
            .overrideWith((ref) => Stream.value([course])),
        courseModulesProvider(course.id).overrideWith(
          (ref) async => throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'Denied',
          ),
        ),
        courseLessonsProvider(course.id).overrideWith((ref) async => []),
        allProgressProvider.overrideWith((ref) async => []),
        myLearningStateProvider.overrideWith(
          (ref) async => const MyLearningState(
            display: MyLearningDisplayState.empty,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(selectedPillarProvider.notifier).state =
        PedagogicalPillar.foundationsPractice;

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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Modules à venir'), findsNothing);
    expect(find.textContaining('Accès refusé'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });
}

class _MockFirebaseUser extends Mock implements User {
  @override
  String get uid => 'preview-uid';
}
