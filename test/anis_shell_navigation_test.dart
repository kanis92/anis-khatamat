import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anis_khatamat/app/router.dart';
import 'package:anis_khatamat/core/providers/auth_provider.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';

void main() {
  testWidgets('shell side navigation selects destination at desktop width', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [demoModeProvider.overrideWith((ref) => true)],
    );
    addTearDown(container.dispose);

    final router = container.read(goRouterProvider);

    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/');

    await tester.tap(find.text('Khatma'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/khatma');
  });

  testWidgets('shell bottom navigation preserved at compact width', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [demoModeProvider.overrideWith((ref) => true)],
    );
    addTearDown(container.dispose);

    final router = container.read(goRouterProvider);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('Khatma'), findsWidgets);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/settings');
  });

  testWidgets('shell uses bottom navigation at medium width', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [demoModeProvider.overrideWith((ref) => true)],
    );
    addTearDown(container.dispose);

    final router = container.read(goRouterProvider);

    await tester.binding.setSurfaceSize(const Size(768, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Khatma'), findsWidgets);
    expect(router.state.uri.path, '/');
  });
}
