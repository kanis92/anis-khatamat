import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anis_khatamat/app/router.dart';
import 'package:anis_khatamat/core/providers/auth_provider.dart';
import 'package:anis_khatamat/core/services/khatma_link_service.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';
import 'package:anis_khatamat/screens/hizb_distribution_screen.dart';
import 'package:anis_khatamat/screens/khatma_route_screen.dart';

void main() {
  testWidgets(
    'collaborative create navigates to distribution, not /khatma/:id=distribute',
    (tester) async {
      final container = ProviderContainer(
        overrides: [demoModeProvider.overrideWith((ref) => true)],
      );
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

      router.push(
        KhatmaLinkService.distributePath,
        extra: {
          'title': 'Khatma famille',
          'isGroup': true,
          'members': <String>[],
        },
      );
      await tester.pumpAndSettle();

      expect(router.state.uri.path, KhatmaLinkService.distributePath);
      expect(find.byType(HizbDistributionScreen), findsOneWidget);
      expect(find.byType(KhatmaRouteScreen), findsNothing);
      expect(find.text('Khatma introuvable'), findsNothing);
      expect(find.text('Distribution des Hizb'), findsOneWidget);
    },
  );

  testWidgets(
    '/khatma/:id still loads the detail route for a real document id',
    (tester) async {
      final container = ProviderContainer(
        overrides: [demoModeProvider.overrideWith((ref) => true)],
      );
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

      router.push(KhatmaLinkService.detailPath('FsAutoCreatedKhatmaId'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/khatma/FsAutoCreatedKhatmaId');
      expect(find.byType(HizbDistributionScreen), findsNothing);
      expect(find.byType(KhatmaRouteScreen), findsOneWidget);
    },
  );
}
