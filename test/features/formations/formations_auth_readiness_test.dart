import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:anis_khatamat/core/providers/auth_provider.dart';
import 'package:anis_khatamat/features/formations/models/course.dart';
import 'package:anis_khatamat/features/formations/models/course_module.dart';
import 'package:anis_khatamat/features/formations/providers/formations_access.dart';
import 'package:anis_khatamat/features/formations/providers/formations_providers.dart';
import 'package:anis_khatamat/features/formations/repositories/formations_repository.dart';

/// Prouve le contrat de readiness Formations :
/// auth initializing / signed out / signed in sont trois états distincts,
/// et aucune lecture Firestore n'a lieu avant d'avoir des credentials.
void main() {
  late StreamController<User?> authController;
  late _RecordingRepository repository;

  setUp(() {
    authController = StreamController<User?>();
    repository = _RecordingRepository();
  });

  tearDown(() => authController.close());

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => authController.stream),
        formationsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('auth initializing keeps providers loading and queries nothing', () async {
    final container = buildContainer();

    expect(
      container.read(authReadinessProvider).status,
      AuthStatus.initializing,
    );

    final modules = container.read(courseModulesProvider('course-x'));
    final courses = container.read(publishedCoursesProvider);

    expect(modules, isA<AsyncLoading<List<CourseModule>>>());
    expect(courses, isA<AsyncLoading<List<Course>>>());
    expect(repository.moduleReads, isEmpty);
    expect(repository.catalogueSubscriptions, 0);
  });

  test('signed out surfaces a domain error and queries nothing', () async {
    final container = buildContainer();
    final subscription = container.listen(
      courseModulesProvider('course-x'),
      (_, __) {},
    );

    authController.add(null);
    await container.read(authStateProvider.future);
    await pumpEventQueue();

    expect(container.read(authReadinessProvider).status, AuthStatus.signedOut);

    final state = subscription.read();
    expect(state, isA<AsyncError<List<CourseModule>>>());
    expect(
      (state as AsyncError).error,
      isA<FormationsAuthRequiredException>(),
      reason: 'signed-out must be a domain state, not a fake Firestore error',
    );
    expect(repository.moduleReads, isEmpty);
  });

  test('signed out never collapses into an empty catalogue', () async {
    final container = buildContainer();
    final subscription = container.listen(publishedCoursesProvider, (_, __) {});

    authController.add(null);
    await pumpEventQueue();

    final state = subscription.read();
    expect(state.hasValue, isFalse);
    expect(state, isA<AsyncError<List<Course>>>());
    expect(repository.catalogueSubscriptions, 0);
  });

  test('signing in rebuilds Formation providers without manual refresh',
      () async {
    final container = buildContainer();
    final subscription = container.listen(
      courseModulesProvider('course-x'),
      (_, __) {},
    );

    authController.add(null);
    await pumpEventQueue();
    expect(subscription.read(), isA<AsyncError<List<CourseModule>>>());

    authController.add(_FakeUser('preview-uid'));
    await pumpEventQueue();

    expect(container.read(authReadinessProvider).status, AuthStatus.signedIn);
    expect(subscription.read().valueOrNull, hasLength(1));
    expect(repository.moduleReads, ['course-x']);
  });

  test('switching users re-runs the protected read', () async {
    final container = buildContainer();
    final subscription = container.listen(
      courseModulesProvider('course-x'),
      (_, __) {},
    );

    authController.add(_FakeUser('user-a'));
    await pumpEventQueue();
    expect(repository.moduleReads, ['course-x']);

    authController.add(_FakeUser('user-b'));
    await pumpEventQueue();

    expect(subscription.read().valueOrNull, hasLength(1));
    expect(repository.moduleReads, ['course-x', 'course-x']);
  });

  test('an auth stream failure is signed out, never authenticated', () async {
    final container = buildContainer();
    container.listen(authReadinessProvider, (_, __) {});

    authController.addError(StateError('auth backend unreachable'));
    await pumpEventQueue();

    expect(container.read(authReadinessProvider).status, AuthStatus.signedOut);
    expect(container.read(firebaseUidProvider), isNull);
  });
}

class _RecordingRepository extends Mock implements FormationsRepository {
  final List<String> moduleReads = [];
  int catalogueSubscriptions = 0;

  @override
  Future<List<CourseModule>> getModules(String courseId) async {
    moduleReads.add(courseId);
    return [
      CourseModule(
        id: 'module-1',
        courseId: courseId,
        title: 'Bien démarrer',
        order: 0,
      ),
    ];
  }

  @override
  Stream<List<Course>> watchPublishedCourses() {
    catalogueSubscriptions++;
    return Stream.value(const <Course>[]);
  }

  @override
  Stream<List<Course>> watchCoursesByPillar(String pillarId) {
    catalogueSubscriptions++;
    return Stream.value(const <Course>[]);
  }
}

class _FakeUser extends Mock implements User {
  _FakeUser(this._uid);

  final String _uid;

  @override
  String get uid => _uid;
}
