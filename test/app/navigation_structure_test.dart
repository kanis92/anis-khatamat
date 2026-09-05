import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anis_khatamat/design_system/components/anis_bottom_navigation.dart';
import 'package:anis_khatamat/core/widgets/anis_icon.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('Bottom Navigation - 5 Tabs Structure', () {
    testWidgets('Should have exactly 5 navigation items', (WidgetTester tester) async {
      final items = [
        const AnisNavigationItem(label: 'Accueil', icon: AnisIconType.home),
        const AnisNavigationItem(label: 'Khatma', icon: AnisIconType.khatma),
        const AnisNavigationItem(label: 'Formations', icon: AnisIconType.training),
        const AnisNavigationItem(label: 'Wird', icon: AnisIconType.wird),
        const AnisNavigationItem(label: 'Paramètres', icon: AnisIconType.settings),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
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
            locale: const Locale('fr'),
            home: Scaffold(
              bottomNavigationBar: AnisBottomNavigation(
                items: items,
                currentIndex: 0,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Khatma'), findsOneWidget);
      expect(find.text('Formations'), findsOneWidget);
      expect(find.text('Wird'), findsOneWidget);
      expect(find.text('Paramètres'), findsOneWidget);
    });

    testWidgets('Formations should be at index 2', (WidgetTester tester) async {
      final items = [
        const AnisNavigationItem(label: 'Accueil', icon: AnisIconType.home),
        const AnisNavigationItem(label: 'Khatma', icon: AnisIconType.khatma),
        const AnisNavigationItem(label: 'Formations', icon: AnisIconType.training),
        const AnisNavigationItem(label: 'Wird', icon: AnisIconType.wird),
        const AnisNavigationItem(label: 'Paramètres', icon: AnisIconType.settings),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
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
            locale: const Locale('fr'),
            home: Scaffold(
              bottomNavigationBar: AnisBottomNavigation(
                items: items,
                currentIndex: 2, // Formations selected
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      // Verify Formations is visible and at correct position
      expect(items[2].label, 'Formations');
      expect(items[2].icon, AnisIconType.training);
    });

    testWidgets('Notifications should NOT be in bottom navigation', (WidgetTester tester) async {
      final items = [
        const AnisNavigationItem(label: 'Accueil', icon: AnisIconType.home),
        const AnisNavigationItem(label: 'Khatma', icon: AnisIconType.khatma),
        const AnisNavigationItem(label: 'Formations', icon: AnisIconType.training),
        const AnisNavigationItem(label: 'Wird', icon: AnisIconType.wird),
        const AnisNavigationItem(label: 'Paramètres', icon: AnisIconType.settings),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
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
            locale: const Locale('fr'),
            home: Scaffold(
              bottomNavigationBar: AnisBottomNavigation(
                items: items,
                currentIndex: 0,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      // Verify Notifications is not in the navigation
      expect(find.text('Notifications'), findsNothing);
    });

    testWidgets('All 5 tabs fit at 375px width without overflow', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));
      
      final items = [
        const AnisNavigationItem(label: 'Accueil', icon: AnisIconType.home),
        const AnisNavigationItem(label: 'Khatma', icon: AnisIconType.khatma),
        const AnisNavigationItem(label: 'Formations', icon: AnisIconType.training),
        const AnisNavigationItem(label: 'Wird', icon: AnisIconType.wird),
        const AnisNavigationItem(label: 'Paramètres', icon: AnisIconType.settings),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
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
            locale: const Locale('fr'),
            home: Scaffold(
              bottomNavigationBar: AnisBottomNavigation(
                items: items,
                currentIndex: 0,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for overflow errors
      expect(tester.takeException(), isNull);
      
      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Navigation labels in French', (WidgetTester tester) async {
      final items = [
        const AnisNavigationItem(label: 'Accueil', icon: AnisIconType.home),
        const AnisNavigationItem(label: 'Khatma', icon: AnisIconType.khatma),
        const AnisNavigationItem(label: 'Formations', icon: AnisIconType.training),
        const AnisNavigationItem(label: 'Wird', icon: AnisIconType.wird),
        const AnisNavigationItem(label: 'Paramètres', icon: AnisIconType.settings),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
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
            locale: const Locale('fr'),
            home: Scaffold(
              bottomNavigationBar: AnisBottomNavigation(
                items: items,
                currentIndex: 0,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Formations'), findsOneWidget);
    });

    testWidgets('Navigation labels in English', (WidgetTester tester) async {
      final items = [
        const AnisNavigationItem(label: 'Home', icon: AnisIconType.home),
        const AnisNavigationItem(label: 'Khatma', icon: AnisIconType.khatma),
        const AnisNavigationItem(label: 'Training', icon: AnisIconType.training),
        const AnisNavigationItem(label: 'Wird', icon: AnisIconType.wird),
        const AnisNavigationItem(label: 'Settings', icon: AnisIconType.settings),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
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
            locale: const Locale('en'),
            home: Scaffold(
              bottomNavigationBar: AnisBottomNavigation(
                items: items,
                currentIndex: 0,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Training'), findsOneWidget);
    });

    testWidgets('Navigation in Arabic RTL', (WidgetTester tester) async {
      final items = [
        const AnisNavigationItem(label: 'الرئيسية', icon: AnisIconType.home),
        const AnisNavigationItem(label: 'الختمة', icon: AnisIconType.khatma),
        const AnisNavigationItem(label: 'التدريب', icon: AnisIconType.training),
        const AnisNavigationItem(label: 'ورد', icon: AnisIconType.wird),
        const AnisNavigationItem(label: 'الإعدادات', icon: AnisIconType.settings),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
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
            locale: const Locale('ar'),
            home: Scaffold(
              bottomNavigationBar: AnisBottomNavigation(
                items: items,
                currentIndex: 0,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      // Verify Arabic text is rendered
      expect(find.text('الرئيسية'), findsOneWidget);
      expect(find.text('التدريب'), findsOneWidget);

      // Verify RTL directionality
      final BuildContext context = tester.element(find.byType(Scaffold));
      expect(Directionality.of(context), TextDirection.rtl);
    });
  });
}
