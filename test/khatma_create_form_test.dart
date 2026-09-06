import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:anis_khatamat/core/models/khatma.dart';
import 'package:anis_khatamat/core/models/khatma_creation_failure.dart';
import 'package:anis_khatamat/core/models/khatma_creation_state.dart';
import 'package:anis_khatamat/core/providers/auth_provider.dart';
import 'package:anis_khatamat/core/providers/khatma_creation_provider.dart';
import 'package:anis_khatamat/core/providers/reading_provider.dart';
import 'package:anis_khatamat/core/services/khatma_creation_service.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';
import 'package:anis_khatamat/screens/khatma_screen.dart';

class _FakeCreator implements KhatmaCreator {
  _FakeCreator({this.shouldFail = false});

  final bool shouldFail;
  int createCount = 0;

  @override
  String allocateKhatmaId() => 'created-abc';

  @override
  Future<Khatma> createKhatma({
    required String title,
    required String createdBy,
    required bool isGroup,
    required bool isPublic,
    required String? hizbDefinitionId,
    String? resumeKhatmaId,
    String? objectives,
    List<String> members = const [],
  }) async {
    createCount++;
    if (shouldFail) {
      throw const NetworkError(khatmaId: 'created-abc');
    }
    return Khatma(
      id: resumeKhatmaId ?? 'created-abc',
      title: title,
      createdBy: createdBy,
      createdAt: DateTime(2026, 1, 1),
      isGroup: isGroup,
      reservationMode: true,
      creationState: KhatmaCreationState.ready,
    );
  }
}

GoRouter _router() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(
          body: CreateCollaborativeKhatmaForm(isGroup: true),
        ),
      ),
      GoRoute(
        path: '/khatma/:id',
        builder: (_, state) => Text('DETAIL:${state.pathParameters['id']}'),
      ),
    ],
  );
}

Widget _app(GoRouter router, _FakeCreator fake) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(
        AppUser(uid: 'u1', email: 'jaouad@test.com', displayName: 'Jaouad'),
      ),
      khatmaCreationServiceProvider.overrideWithValue(fake),
      khatmatProvider.overrideWith((ref) async => []),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
    ),
  );
}

void main() {
  testWidgets('create CTA is create, not distribution, and failure stays', (
    tester,
  ) async {
    final fake = _FakeCreator(shouldFail: true);
    final router = _router();

    await tester.pumpWidget(_app(router, fake));
    await tester.pumpAndSettle();

    expect(find.text('Suivant → Distribution des Hizb'), findsNothing);
    expect(find.text('Créer une Khatma'), findsOneWidget);

    await tester.ensureVisible(find.text('Créer une Khatma'));
    await tester.tap(find.text('Créer une Khatma'));
    await tester.pumpAndSettle();

    expect(fake.createCount, 1);
    expect(find.text('DETAIL:created-abc'), findsNothing);
    expect(find.textContaining('Erreur réseau'), findsWidgets);
    expect(router.state.uri.path, '/');
  });

  testWidgets('success navigates to same allocated Khatma id', (tester) async {
    final fake = _FakeCreator();
    final router = _router();

    await tester.pumpWidget(_app(router, fake));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Créer une Khatma'));
    await tester.tap(find.text('Créer une Khatma'));
    await tester.pumpAndSettle();

    expect(fake.createCount, 1);
    expect(router.state.uri.path, '/khatma/created-abc');
    expect(find.text('DETAIL:created-abc'), findsOneWidget);
  });
}
