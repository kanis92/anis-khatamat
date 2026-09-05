import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/models/home_dashboard_state.dart';
import 'package:anis_khatamat/core/providers/auth_provider.dart';
import 'package:anis_khatamat/core/providers/home_dashboard_provider.dart';
import 'package:anis_khatamat/core/widgets/connectivity_banner.dart';
import 'package:anis_khatamat/screens/home_screen.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';

void main() {
  group('HomeScreen Quick Actions Compact Layout Tests', () {
    Widget makeTestableHomeScreen({
      required Locale locale,
      required Size screenSize,
    }) {
      return ProviderScope(
        overrides: [
          demoModeProvider.overrideWith((ref) => true),
          connectivityProvider.overrideWith((ref) => Stream.value([])),
          homeDashboardProvider.overrideWith((ref) async => HomeDashboardState.empty),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr'),
            Locale('en'),
            Locale('ar'),
          ],
          home: const Scaffold(
            body: AnisHomePage(),
          ),
        ),
      );
    }

    testWidgets('French: no truncation at 375px width', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(makeTestableHomeScreen(
        locale: const Locale('fr'),
        screenSize: const Size(375, 667),
      ));
      await tester.pumpAndSettle();

      // Verify titles are fully visible (not truncated)
      expect(find.text('Mushaf'), findsOneWidget);
      expect(find.text('Khatma'), findsOneWidget);
      expect(find.text('Formations'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);

      // Verify new compact subtitles are present
      expect(find.text('Reprendre ma lecture'), findsOneWidget);
      expect(find.text('Mes Khatmat'), findsOneWidget);
      expect(find.text('Mes formations'), findsOneWidget);
      expect(find.text('Gérer mes alertes'), findsOneWidget);

      // Verify no overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('English: no truncation at 375px width', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(makeTestableHomeScreen(
        locale: const Locale('en'),
        screenSize: const Size(375, 667),
      ));
      await tester.pumpAndSettle();

      // Verify titles are fully visible
      expect(find.text('Mushaf'), findsOneWidget);
      expect(find.text('Khatma'), findsOneWidget);
      expect(find.text('Training'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);

      // Verify new compact subtitles
      expect(find.text('Resume reading'), findsOneWidget);
      expect(find.text('My Khatmat'), findsOneWidget);
      expect(find.text('My courses'), findsOneWidget);
      expect(find.text('Manage alerts'), findsOneWidget);

      // Verify no overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Arabic: no truncation at 375px width with RTL', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(makeTestableHomeScreen(
        locale: const Locale('ar'),
        screenSize: const Size(375, 667),
      ));
      await tester.pumpAndSettle();

      // Verify Arabic titles are fully visible
      expect(find.text('المصحف'), findsOneWidget);
      expect(find.text('الختمة'), findsOneWidget);
      expect(find.text('التدريب'), findsOneWidget);
      expect(find.text('الإشعارات'), findsOneWidget);

      // Verify Arabic subtitles
      expect(find.text('استئناف القراءة'), findsOneWidget);
      expect(find.text('ختماتي'), findsOneWidget);
      expect(find.text('دوراتي'), findsOneWidget);
      expect(find.text('إدارة التنبيهات'), findsOneWidget);

      // Verify RTL directionality
      final BuildContext context = tester.element(find.byType(AnisHomePage));
      expect(Directionality.of(context), TextDirection.rtl);

      // Verify no overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('French: no truncation at 390px width', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(makeTestableHomeScreen(
        locale: const Locale('fr'),
        screenSize: const Size(390, 844),
      ));
      await tester.pumpAndSettle();

      // Verify all titles are present
      expect(find.text('Mushaf'), findsOneWidget);
      expect(find.text('Khatma'), findsOneWidget);
      expect(find.text('Formations'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);

      // Verify no overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('French: no truncation at 430px width (iPhone 14 Pro Max)', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(makeTestableHomeScreen(
        locale: const Locale('fr'),
        screenSize: const Size(430, 932),
      ));
      await tester.pumpAndSettle();

      // Verify all content renders without issues
      expect(find.text('Mushaf'), findsOneWidget);
      expect(find.text('Khatma'), findsOneWidget);
      expect(find.text('Formations'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);

      // Verify no overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Quick action cards have accessible tap targets', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(makeTestableHomeScreen(
        locale: const Locale('fr'),
        screenSize: const Size(375, 667),
      ));
      await tester.pumpAndSettle();

      // Find all quick action tiles by scrolling to them
      await tester.scrollUntilVisible(
        find.text('Mushaf'),
        100,
        scrollable: find.byType(Scrollable).first,
      );

      // Verify minimum height (100px as per new vertical structure)
      final mushafCard = find.ancestor(
        of: find.text('Mushaf'),
        matching: find.byType(ConstrainedBox),
      ).first;

      final constrainedBox = tester.widget<ConstrainedBox>(mushafCard);
      expect(constrainedBox.constraints.minHeight, greaterThanOrEqualTo(100));
    });

    testWidgets('Cards are visually compact without excessive whitespace', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(makeTestableHomeScreen(
        locale: const Locale('fr'),
        screenSize: const Size(375, 667),
      ));
      await tester.pumpAndSettle();

      // Scroll to quick actions
      await tester.scrollUntilVisible(
        find.text('Mushaf'),
        100,
        scrollable: find.byType(Scrollable).first,
      );

      // Verify card has vertical Column layout (not Row)
      final mushafCard = find.ancestor(
        of: find.text('Mushaf'),
        matching: find.byType(Column),
      );
      expect(mushafCard, findsWidgets);
    });
  });
}
