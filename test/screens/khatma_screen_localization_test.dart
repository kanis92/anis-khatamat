import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/screens/khatma_screen.dart';
import 'package:anis_khatamat/core/models/khatma.dart';
import 'package:anis_khatamat/core/providers/reading_provider.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';

void main() {
  group('KhatmaScreen Localization Tests', () {
    // Helper function to wrap the screen with necessary providers and localization
    Widget makeTestableKhatmaScreen({
      required Locale locale,
      List<Khatma> khatmat = const [],
    }) {
      return ProviderScope(
        overrides: [
          khatmatProvider.overrideWith((ref) async => khatmat),
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
          home: const KhatmaScreen(),
        ),
      );
    }

    testWidgets('French localization renders correctly', (tester) async {
      await tester.pumpWidget(makeTestableKhatmaScreen(locale: const Locale('fr')));
      await tester.pumpAndSettle();

      // Verify French strings are present
      expect(find.text('Khatma'), findsOneWidget);
      expect(find.text('Créer une nouvelle Khatma'), findsOneWidget);
      expect(find.text('Invitez votre famille et vos amis'), findsOneWidget);
      expect(find.text('Vos Khatmat en cours'), findsOneWidget);
      expect(find.text('Aucune Khatma en cours'), findsOneWidget);
      expect(find.text('Créer une Khatma'), findsOneWidget);
      expect(find.text('Options de lecture'), findsOneWidget);
      expect(find.text('Mushaf Hafs'), findsOneWidget);
      expect(find.text('Version la plus répandue'), findsOneWidget);
      expect(find.text('Mushaf Warsh'), findsOneWidget);
      expect(find.text('Version d\'Afrique du Nord'), findsOneWidget);
    });

    testWidgets('English localization renders correctly', (tester) async {
      await tester.pumpWidget(makeTestableKhatmaScreen(locale: const Locale('en')));
      await tester.pumpAndSettle();

      // Verify English strings are present
      expect(find.text('Khatma'), findsOneWidget);
      expect(find.text('Create a new Khatma'), findsOneWidget);
      expect(find.text('Invite your family and friends'), findsOneWidget);
      expect(find.text('Your Khatmat in progress'), findsOneWidget);
      expect(find.text('No Khatma in progress'), findsOneWidget);
      expect(find.text('Create Khatma'), findsOneWidget);
      expect(find.text('Reading options'), findsOneWidget);
      expect(find.text('Mushaf Hafs'), findsOneWidget);
      expect(find.text('Most widespread version'), findsOneWidget);
      expect(find.text('Mushaf Warsh'), findsOneWidget);
      expect(find.text('North African version'), findsOneWidget);

      // Verify no French strings remain
      expect(find.text('Créer une nouvelle Khatma'), findsNothing);
      expect(find.text('Vos Khatmat en cours'), findsNothing);
    });

    testWidgets('Arabic localization renders correctly', (tester) async {
      await tester.pumpWidget(makeTestableKhatmaScreen(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Verify Arabic strings are present
      expect(find.text('الختمة'), findsOneWidget);
      expect(find.text('إنشاء ختمة جديدة'), findsOneWidget);
      expect(find.text('ادع عائلتك وأصدقاءك'), findsOneWidget);
      expect(find.text('ختماتك قيد التنفيذ'), findsOneWidget);
      expect(find.text('لا توجد ختمة قيد التنفيذ'), findsOneWidget);
      expect(find.text('إنشاء ختمة'), findsOneWidget);
      expect(find.text('خيارات القراءة'), findsOneWidget);
      expect(find.text('مصحف حفص'), findsOneWidget);
      expect(find.text('النسخة الأكثر انتشاراً'), findsOneWidget);
      expect(find.text('مصحف ورش'), findsOneWidget);
      expect(find.text('نسخة شمال أفريقيا'), findsOneWidget);

      // Verify no French strings remain
      expect(find.text('Créer une nouvelle Khatma'), findsNothing);
      expect(find.text('Vos Khatmat en cours'), findsNothing);
      expect(find.text('Options de lecture'), findsNothing);

      // Verify RTL directionality
      final BuildContext context = tester.element(find.byType(Scaffold));
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets('Individual option is not present', (tester) async {
      await tester.pumpWidget(makeTestableKhatmaScreen(locale: const Locale('fr')));
      await tester.pumpAndSettle();

      // Verify obsolete Individual/Group choice strings are NOT present
      expect(find.text('Choisissez le type de Khatma'), findsNothing);
      expect(find.text('Individuelle'), findsNothing);
      expect(find.text('Groupe'), findsNothing);
    });

    testWidgets('Empty state has single primary CTA', (tester) async {
      await tester.pumpWidget(makeTestableKhatmaScreen(locale: const Locale('fr')));
      await tester.pumpAndSettle();

      // Verify empty state message
      expect(find.text('Aucune Khatma en cours'), findsOneWidget);
      expect(
        find.text('Créez une Khatma de groupe, invitez vos proches et répartissez les Hizb.'),
        findsOneWidget,
      );

      // Verify single primary CTA
      expect(find.widgetWithText(FilledButton, 'Créer une Khatma'), findsOneWidget);
    });

    testWidgets('Creation CTA directly targets collaborative Khatma', (tester) async {
      await tester.pumpWidget(makeTestableKhatmaScreen(locale: const Locale('fr')));
      await tester.pumpAndSettle();

      // Tap the creation CTA
      await tester.tap(find.widgetWithText(FilledButton, 'Créer une Khatma'));
      await tester.pumpAndSettle();

      // Verify the creation modal shows collaborative Khatma title
      expect(find.text('Créer une Khatma collaborative'), findsOneWidget);

      // Verify invite members field is visible (only for group Khatma)
      expect(find.text('Inviter des membres'), findsOneWidget);
    });

    testWidgets('No overflow at 375x667 (iPhone SE)', (tester) async {
      // Set the screen size to iPhone SE
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(makeTestableKhatmaScreen(locale: const Locale('fr')));
      await tester.pumpAndSettle();

      // Verify no RenderFlex overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Arabic RTL layout at 375x667 has no overflow', (tester) async {
      // Set the screen size to iPhone SE
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(makeTestableKhatmaScreen(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Verify no overflow
      expect(tester.takeException(), isNull);

      // Verify RTL
      final BuildContext context = tester.element(find.byType(Scaffold));
      expect(Directionality.of(context), TextDirection.rtl);
    });
  });
}
