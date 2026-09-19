import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anis_khatamat/app/router.dart';
import 'package:anis_khatamat/core/providers/auth_provider.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';

void main() {
  testWidgets('demo mode does not bypass auth gate', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = container.read(goRouterProvider);

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

    expect(router.state.uri.path, '/auth');

    container.read(demoModeProvider.notifier).state = true;
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/auth');
  });
}
