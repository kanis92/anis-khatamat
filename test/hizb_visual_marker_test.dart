import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:anis_khatamat/core/repositories/hizb_index_repository.dart';
import 'package:anis_khatamat/core/services/hizb_navigation_service.dart';
import 'package:anis_khatamat/core/widgets/mushaf_hizb_indicator.dart';
import 'package:anis_khatamat/l10n/gen_l10n/app_localizations.dart';

/// Premier verset rendu sur chaque page du Mushaf, extrait du JSON du lecteur.
/// Sert à prouver que l'indicateur ne doit PAS s'appuyer dessus.
late final Map<int, (int surah, int ayah)> _firstAyahOnPage;

Widget _host(Widget child, {Locale locale = const Locale('fr')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Les tests n'ont pas de réseau : on s'appuie sur les fontes embarquées.
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(() {
    final raw =
        jsonDecode(
              File(
                'packages/flutter_quran/lib/assets/jsons/quran_hafs.json',
              ).readAsStringSync(),
            )
            as List<dynamic>;
    final map = <int, (int, int)>{};
    for (final e in raw) {
      final m = e as Map<String, dynamic>;
      final page = m['page'] as int;
      map.putIfAbsent(page, () => (m['sora'] as int, m['aya_no'] as int));
    }
    _firstAyahOnPage = map;
  });

  // ---------------------------------------------------------------------------
  // 1. Le Hizb affiché correspond au Hizb ouvert
  // ---------------------------------------------------------------------------
  group('Hizb affiché sur la page d\'ouverture', () {
    test('1. les 60 Hizb affichent leur propre numéro dès l\'ouverture', () {
      final failures = <String>[];
      for (var h = 1; h <= 60; h++) {
        final page = HizbNavigationService.startPage(h);
        final shown = HizbNavigationService.hizbForPage(page);
        if (shown != h) failures.add('Hizb $h → p$page affiche Hizb $shown');
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('2. Hizb 44 ouvre page 431 et affiche « Hizb 44 »', () {
      expect(HizbNavigationService.startPage(44), 431);
      expect(HizbNavigationService.hizbForPage(431), 44);
    });

    test('3. régression : le premier verset de la page de frontière appartient '
        'au Hizb précédent', () {
      // p431 commence au verset 34:23, encore dans le Hizb 43, alors que le
      // Hizb 44 démarre plus bas sur la même page (34:24). Déduire le Hizb du
      // premier verset affichait donc « Hizb 43 » juste après avoir demandé 44.
      expect(_firstAyahOnPage[431], (34, 23));
      expect(HizbIndexRepository.hizbForAyah(34, 23), 43);
      expect(HizbNavigationService.hizbForPage(431), 44);
    });

    test('4. cas de bord 1, 30, 44, 60', () {
      for (final h in [1, 30, 44, 60]) {
        final page = HizbNavigationService.startPage(h);
        expect(
          HizbNavigationService.hizbForPage(page),
          h,
          reason: 'Hizb $h ouvert page $page',
        );
      }
    });

    test('5. aucun Hizb ne partage sa page de départ avec un autre', () {
      final pages = [
        for (var h = 1; h <= 60; h++) HizbNavigationService.startPage(h),
      ];
      expect(pages.toSet().length, 60);
      for (var i = 1; i < pages.length; i++) {
        expect(pages[i], greaterThan(pages[i - 1]));
      }
    });
  });

  // ---------------------------------------------------------------------------
  // 2. Tourner les pages
  // ---------------------------------------------------------------------------
  group('Changement de page', () {
    test('6. l\'indicateur reste stable à l\'intérieur d\'un Hizb', () {
      final start = HizbNavigationService.startPage(44);
      final end = HizbNavigationService.endPage(44);
      for (var p = start; p < end; p++) {
        expect(HizbNavigationService.hizbForPage(p), 44, reason: 'page $p');
      }
    });

    test('7. passage Hizb 44 → 45 exactement à la page de départ du 45', () {
      final start45 = HizbNavigationService.startPage(45);
      expect(HizbNavigationService.hizbForPage(start45 - 1), 44);
      expect(HizbNavigationService.hizbForPage(start45), 45);
    });

    test('8. l\'indicateur est monotone sur les 604 pages', () {
      var previous = 1;
      for (var p = 1; p <= HizbNavigationService.totalPages; p++) {
        final h = HizbNavigationService.hizbForPage(p);
        expect(h, greaterThanOrEqualTo(previous), reason: 'page $p');
        expect(h, inInclusiveRange(1, 60));
        previous = h;
      }
      expect(previous, 60);
    });

    test('9. les pages hors bornes ne cassent pas l\'indicateur', () {
      expect(HizbNavigationService.hizbForPage(0), 1);
      expect(HizbNavigationService.hizbForPage(-5), 1);
      expect(HizbNavigationService.hizbForPage(9999), 60);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. Contexte « Hizb réservé » venu d'une Khatma
  // ---------------------------------------------------------------------------
  group('Contexte de réservation', () {
    test('10. sans réservation, l\'indicateur suit la page', () {
      expect(HizbNavigationService.displayedHizb(431), 44);
      expect(HizbNavigationService.displayedHizb(430), 43);
    });

    test('11. sur une page de frontière, le Hizb réservé prime', () {
      // p431 est partagée : fin du Hizb 43 et début du 44.
      expect(HizbNavigationService.hizbForPage(431), 44);
      expect(HizbNavigationService.displayedHizb(431, reservedHizb: 43), 43);
      expect(HizbNavigationService.displayedHizb(431, reservedHizb: 44), 44);
    });

    test('12. chaque Hizb réservé s\'affiche sur sa page d\'ouverture', () {
      for (var h = 1; h <= 60; h++) {
        final page = HizbNavigationService.startPage(h);
        expect(HizbNavigationService.displayedHizb(page, reservedHizb: h), h);
      }
    });

    test('13. sortir du Hizb réservé rend la main à la page affichée', () {
      final outside = HizbNavigationService.endPage(43) + 1;
      expect(
        HizbNavigationService.displayedHizb(outside, reservedHizb: 43),
        44,
      );
    });

    test('14. une réservation hors bornes est ignorée', () {
      expect(HizbNavigationService.displayedHizb(431, reservedHizb: 0), 44);
      expect(HizbNavigationService.displayedHizb(431, reservedHizb: 61), 44);
    });

    test('15. reprise « Continuer » : le Hizb réservé reste affiché', () {
      const hizb = 44;
      final middle =
          (HizbNavigationService.startPage(hizb) +
              HizbNavigationService.endPage(hizb)) ~/
          2;
      final resumed = HizbNavigationService.openResume(hizb, middle);
      expect(
        HizbNavigationService.displayedHizb(resumed, reservedHizb: hizb),
        hizb,
      );

      // Position enregistrée hors du Hizb : repli sur le début, badge cohérent.
      final fallback = HizbNavigationService.openResume(hizb, 12);
      expect(fallback, HizbNavigationService.startPage(hizb));
      expect(
        HizbNavigationService.displayedHizb(fallback, reservedHizb: hizb),
        hizb,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 4. Rendu et i18n
  // ---------------------------------------------------------------------------
  group('Rendu de l\'indicateur', () {
    testWidgets('16. badge français : Hizb 44 · Page 431', (tester) async {
      await tester.pumpWidget(
        _host(const MushafHizbBadge(hizb: 44, page: 431)),
      );
      expect(find.text('Hizb 44'), findsOneWidget);
      expect(find.text('Page 431'), findsOneWidget);
      expect(find.text(kRubElHizbGlyph), findsOneWidget);
    });

    testWidgets('17. badge anglais', (tester) async {
      await tester.pumpWidget(
        _host(
          const MushafHizbBadge(hizb: 44, page: 431),
          locale: const Locale('en'),
        ),
      );
      expect(find.text('Hizb 44'), findsOneWidget);
      expect(find.text('Page 431'), findsOneWidget);
    });

    testWidgets('18. badge arabe : chiffres arabes-indiques et RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MushafHizbBadge(hizb: 44, page: 431),
          locale: const Locale('ar'),
        ),
      );
      expect(find.text('الحزب ٤٤'), findsOneWidget);
      expect(find.text('صفحة ٤٣١'), findsOneWidget);

      final direction =
          tester
              .widget<Directionality>(
                find
                    .descendant(
                      of: find.byType(MushafHizbBadge),
                      matching: find.byType(Directionality),
                    )
                    .first,
              )
              .textDirection;
      expect(direction, TextDirection.rtl);
    });

    testWidgets('19. le badge reste lisible en LTR même dans un lecteur RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: MushafHizbBadge(hizb: 44, page: 431),
          ),
        ),
      );
      final direction =
          tester
              .widget<Directionality>(
                find
                    .descendant(
                      of: find.byType(MushafHizbBadge),
                      matching: find.byType(Directionality),
                    )
                    .last,
              )
              .textDirection;
      expect(direction, TextDirection.ltr);
    });

    testWidgets('20. le badge ouvre le sélecteur au tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(MushafHizbBadge(hizb: 44, page: 431, onTap: () => taps++)),
      );
      await tester.tap(find.byType(MushafHizbBadge));
      expect(taps, 1);
    });

    testWidgets('21. contexte Khatma dans la pastille, sans bandeau', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MushafHizbBadge(
            hizb: 44,
            page: 431,
            reservedHizb: 44,
            insideReservedHizb: true,
          ),
        ),
      );
      expect(find.text('Hizb 44'), findsOneWidget);
      expect(find.text('Page 431'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
      expect(find.byType(MushafHizbContextBar), findsNothing);
    });

    testWidgets('22. sortie du Hizb réservé : undo dans la pastille', (
      tester,
    ) async {
      var returned = 0;
      var picker = 0;
      await tester.pumpWidget(
        _host(
          MushafHizbBadge(
            hizb: 45,
            page: 442,
            reservedHizb: 44,
            insideReservedHizb: false,
            onTap: () => picker++,
            onReturnToHizb: () => returned++,
          ),
        ),
      );
      expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
      await tester.tap(find.byType(MushafHizbBadge));
      expect(returned, 1);
      expect(picker, 0);
    });

    testWidgets('23. pastille arabe depuis une Khatma', (tester) async {
      await tester.pumpWidget(
        _host(
          const MushafHizbBadge(
            hizb: 44,
            page: 431,
            reservedHizb: 44,
            insideReservedHizb: true,
          ),
          locale: const Locale('ar'),
        ),
      );
      expect(find.text('الحزب ٤٤'), findsOneWidget);
    });

    testWidgets('24. la pastille ne réserve aucune hauteur extra', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const MushafHizbBadge(hizb: 44, page: 431, reservedHizb: 44)),
      );
      final withContext = tester.getSize(find.byType(MushafHizbBadge));
      await tester.pumpWidget(
        _host(const MushafHizbBadge(hizb: 44, page: 431)),
      );
      final without = tester.getSize(find.byType(MushafHizbBadge));
      expect(withContext.height, without.height);
      expect(tester.takeException(), isNull);
    });
  });
}
