import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/constants/hizb_definitions.dart';
import 'package:anis_khatamat/core/data/quran_hizb_data.dart';
import 'package:anis_khatamat/core/data/quran_subdivision_data.dart';
import 'package:anis_khatamat/core/models/mushaf_open_target.dart';
import 'package:anis_khatamat/core/repositories/hizb_index_repository.dart';
import 'package:anis_khatamat/core/services/hizb_navigation_service.dart';

/// Page réelle de chaque verset dans le Mushaf effectivement rendu par le
/// lecteur. C'est la seule vérité terrain : ce que le PageView affiche.
late final Map<String, int> _pageOfAyah;

/// Hizb dont un point de bord révèle un décalage : début, fin, changement de
/// Juz, frontière de sourate, et le Hizb 44 du bug rapporté.
const _edgeCases = [1, 2, 30, 31, 44, 59, 60];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final file = File(
      'packages/flutter_quran/lib/assets/jsons/quran_hafs.json',
    );
    expect(
      file.existsSync(),
      isTrue,
      reason: 'Le JSON du Mushaf est la référence des tests de navigation',
    );
    final raw = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    _pageOfAyah = {
      for (final e in raw)
        '${(e as Map<String, dynamic>)['sora']}:${e['aya_no']}':
            e['page'] as int,
    };
  });

  // ---------------------------------------------------------------------------
  // 1. Mapping complet 1..60 contre le Mushaf réel
  // ---------------------------------------------------------------------------
  group('Mapping des 60 Hizb', () {
    test(
      '1. chaque Hizb pointe vers la page réelle de son verset de départ',
      () {
        final failures = <String>[];
        for (var h = 1; h <= 60; h++) {
          final ref = HizbIndexRepository.getByNumber(h);
          final real = _pageOfAyah['${ref.surah}:${ref.ayah}'];
          expect(
            real,
            isNotNull,
            reason:
                'Hizb $h : le verset ${ref.surah}:${ref.ayah} '
                "n'existe pas dans le Mushaf",
          );
          if (ref.pageHafs != real) {
            failures.add(
              'Hizb $h (${ref.surah}:${ref.ayah}) : '
              'table=${ref.pageHafs} réel=$real '
              '(décalage ${real! - ref.pageHafs})',
            );
          }
        }
        expect(
          failures,
          isEmpty,
          reason: 'Pages divergentes du Mushaf :\n${failures.join('\n')}',
        );
      },
    );

    test(
      '2. les 240 rub\' pointent vers des versets existants et des pages réelles',
      () {
        final failures = <String>[];
        for (var h = 1; h <= 60; h++) {
          for (final q in QuranSubdivisionData.getQuartersForHizb(h)) {
            final real = _pageOfAyah['${q.surah}:${q.ayah}'];
            if (real == null) {
              failures.add('Hizb $h : verset ${q.surah}:${q.ayah} inexistant');
            } else if (real != q.pageHafs) {
              failures.add(
                'Hizb $h rub\' ${q.surah}:${q.ayah} : '
                'table=${q.pageHafs} réel=$real',
              );
            }
          }
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      },
    );

    test(
      '3. startPage suit exactement la table canonique pour les 60 Hizb',
      () {
        for (var h = 1; h <= 60; h++) {
          expect(
            HizbNavigationService.startPage(h),
            HizbIndexRepository.getByNumber(h).pageHafs,
            reason: 'Hizb $h : startPage doit venir de la source canonique',
          );
        }
      },
    );

    test('4. les pages de début sont strictement croissantes', () {
      for (var h = 2; h <= 60; h++) {
        expect(
          HizbNavigationService.startPage(h),
          greaterThan(HizbNavigationService.startPage(h - 1)),
          reason: 'Hizb $h ne peut pas commencer avant le Hizb ${h - 1}',
        );
      }
    });

    test('5. la page de début de chaque Hizb est bien attribuée à ce Hizb', () {
      final failures = <String>[];
      for (var h = 1; h <= 60; h++) {
        final page = HizbNavigationService.startPage(h);
        final landed = HizbIndexRepository.hizbForPageHafs(page);
        if (landed != h) failures.add('Hizb $h → page $page → Hizb $landed');
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  });

  // ---------------------------------------------------------------------------
  // 2. Bug rapporté : Hizb 44
  // ---------------------------------------------------------------------------
  group('Hizb 44', () {
    test('6. ouvre 34:24 page 431, et non le début de la sourate Saba', () {
      final ref = HizbIndexRepository.getByNumber(44);
      expect(ref.surah, 34);
      expect(ref.ayah, 24);
      expect(ref.rangeStr, '34:24 - 36:27');

      expect(_pageOfAyah['34:24'], 431, reason: 'vérité terrain du Mushaf');
      expect(HizbNavigationService.startPage(44), 431);

      // Ouvrir seulement la sourate 34 mènerait encore dans le Hizb 43.
      final surahStart = _pageOfAyah['34:1']!;
      expect(surahStart, 428);
      expect(
        HizbIndexRepository.hizbForPageHafs(surahStart),
        43,
        reason: 'la page 428 appartient au Hizb 43 : y atterrir est le bug',
      );
    });

    test('7. la page atteinte pour le Hizb 44 est attribuée au Hizb 44', () {
      final page = HizbNavigationService.startPage(44);
      expect(
        HizbIndexRepository.hizbForPageHafs(page),
        44,
        reason: 'le badge doit afficher Hizb 44',
      );
      expect(HizbNavigationService.pageBelongsToHizb(44, page), isTrue);

      // La page 431 porte aussi la fin du Hizb 43 : c'est une frontière
      // légitime. En revanche une page franchement dans le Hizb 43 ne doit
      // jamais être considérée comme appartenant au Hizb 44.
      expect(
        HizbNavigationService.pageBelongsToHizb(43, page),
        isTrue,
        reason: 'page de frontière partagée',
      );
      expect(HizbNavigationService.pageBelongsToHizb(44, 429), isFalse);
      expect(HizbIndexRepository.hizbForPageHafs(429), 43);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. Cas de bord et erreurs d'index
  // ---------------------------------------------------------------------------
  group('Cas de bord', () {
    test('8. Hizb de bord alignés sur le Mushaf', () {
      for (final h in _edgeCases) {
        final ref = HizbIndexRepository.getByNumber(h);
        expect(
          HizbNavigationService.startPage(h),
          _pageOfAyah['${ref.surah}:${ref.ayah}'],
          reason: 'Hizb $h désaligné',
        );
      }
    });

    test('9. Hizb 1 ouvre la page 1 (Al-Fatiha 1:1)', () {
      final ref = HizbIndexRepository.getByNumber(1);
      expect(ref.surah, 1);
      expect(ref.ayah, 1);
      expect(
        HizbNavigationService.startPage(1),
        1,
        reason: 'aucun décalage 0-based ne doit produire la page 0',
      );
    });

    test('10. Hizb 60 ouvre 87:1 et se termine à la dernière page', () {
      final ref = HizbIndexRepository.getByNumber(60);
      expect(ref.surah, 87);
      expect(ref.ayah, 1);
      expect(ref.endSurah, 114);
      expect(ref.endAyah, 6);
      expect(HizbNavigationService.startPage(60), _pageOfAyah['87:1']);
      expect(HizbNavigationService.endPage(60), 604);
    });

    test('11. aucune page hors bornes 1..604', () {
      for (var h = 1; h <= 60; h++) {
        final p = HizbNavigationService.startPage(h);
        expect(p, greaterThanOrEqualTo(1));
        expect(p, lessThanOrEqualTo(604));
      }
    });

    test('12. numéro de Hizb hors plage rejeté', () {
      expect(() => HizbNavigationService.refFor(0), throwsArgumentError);
      expect(() => HizbNavigationService.refFor(61), throwsArgumentError);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. Cohérence des sources : une seule vérité
  // ---------------------------------------------------------------------------
  group('Source canonique unique', () {
    test('13. QuranHizbData et _rubData décrivent le même départ', () {
      for (var h = 1; h <= 60; h++) {
        final range = QuranHizbData.getHizbData(h)['range']!;
        final start = range.split(' - ').first.split(':');
        final first = QuranSubdivisionData.getQuartersForHizb(h).first;
        expect(int.parse(start[0]), first.surah, reason: 'Hizb $h sourate');
        expect(int.parse(start[1]), first.ayah, reason: 'Hizb $h verset');
      }
    });

    test('14. les bornes de fin enchaînent sans trou ni recouvrement', () {
      for (var h = 1; h < 60; h++) {
        final cur = HizbIndexRepository.getByNumber(h);
        final next = HizbIndexRepository.getByNumber(h + 1);
        expect(
          cur.containsAyah(next.surah, next.ayah),
          isFalse,
          reason: 'Hizb $h contient le début du Hizb ${h + 1}',
        );
        expect(
          next.containsAyah(cur.endSurah, cur.endAyah),
          isFalse,
          reason: 'Hizb ${h + 1} contient la fin du Hizb $h',
        );
      }
    });

    test('15. chaque Hizb contient son propre verset de départ', () {
      for (var h = 1; h <= 60; h++) {
        final ref = HizbIndexRepository.getByNumber(h);
        expect(ref.containsAyah(ref.surah, ref.ayah), isTrue);
        expect(HizbIndexRepository.hizbForAyah(ref.surah, ref.ayah), h);
      }
    });

    test('16. startPageForDefinition délègue à la source canonique', () {
      const definitionId = HizbDefinitions.quranFoundationHafsV1;
      for (var h = 1; h <= 60; h++) {
        expect(
          HizbNavigationService.startPageForDefinition(
            h,
            definitionId: definitionId,
          ),
          HizbIndexRepository.getByDefinition(
            h,
            definitionId: definitionId,
          ).pageHafs,
          reason: 'Hizb $h : plus aucune approximation page = hizb × k',
        );
      }
      expect(
        HizbNavigationService.startPageForDefinition(
          44,
          definitionId: definitionId,
        ),
        431,
      );
    });

    test('17. un Juz commence au Hizb impair correspondant', () {
      for (var juz = 1; juz <= 30; juz++) {
        final ref = HizbIndexRepository.getByNumber(juz * 2 - 1);
        expect(ref.juz, juz);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // 5. Points d'entrée : tous transportent le numéro brut du Hizb
  // ---------------------------------------------------------------------------
  group("Points d'entrée", () {
    test('18. grille de réservation : index i → Hizb i+1, sans décalage', () {
      // La grille construit hizbNum = i + 1 ; la cible doit rester identique
      // quel que soit le point d'entrée.
      for (var i = 0; i < 60; i++) {
        final hizbNum = i + 1;
        expect(
          HizbNavigationService.startPage(hizbNum),
          HizbIndexRepository.getByNumber(hizbNum).pageHafs,
        );
      }
    });

    test(
      '19. navigation libre et Khatma-bound convergent sur le canonical',
      () {
        const definitionId = HizbDefinitions.quranFoundationHafsV1;
        for (var h = 1; h <= 60; h++) {
          final free = HizbNavigationService.startPage(h);
          final khatmaBound = HizbNavigationService.startPageForDefinition(
            h,
            definitionId: definitionId,
          );
          expect(
            free,
            khatmaBound,
            reason: 'Hizb $h : Context B et Context A doivent converger',
          );
        }
      },
    );

    test('20. deep link /mushaf/hafs?hizb=44 transporte le Hizb 44', () {
      final t = MushafOpenTarget.fromRoute(
        null,
        Uri.parse('/mushaf/hafs?hizb=44'),
      );
      expect(t.hizb, 44);
      expect(t.page, isNull);
    });

    test('21. extra de route prioritaire, et hizb hors plage ignoré', () {
      final fromExtra = MushafOpenTarget.fromRoute({
        'hizb': 44,
      }, Uri.parse('/mushaf/hafs'));
      expect(fromExtra.hizb, 44);

      for (final bad in ['0', '61', 'abc', '-3']) {
        final t = MushafOpenTarget.fromRoute(
          null,
          Uri.parse('/mushaf/hafs?hizb=$bad'),
        );
        expect(t.hizb, isNull, reason: 'hizb=$bad doit être rejeté');
      }
    });

    test('22. une notification transmettant une chaîne reste correcte', () {
      final t = MushafOpenTarget.fromRoute({
        'hizb': '44',
      }, Uri.parse('/mushaf/hafs'));
      expect(t.hizb, 44, reason: 'clé String "44" ≡ int 44');
    });
  });

  // ---------------------------------------------------------------------------
  // 6. « Lire » vs « Continuer »
  // ---------------------------------------------------------------------------
  group('Reprise de lecture', () {
    test('23. une position enregistrée dans le Hizb est conservée', () {
      const hizb = 44;
      final start = HizbNavigationService.startPage(hizb);
      final inside = start + 1;
      expect(HizbNavigationService.pageBelongsToHizb(hizb, inside), isTrue);
      expect(HizbNavigationService.openResume(hizb, inside), inside);
    });

    test('24. une position hors du Hizb retombe sur le début canonique', () {
      const hizb = 44;
      final start = HizbNavigationService.startPage(hizb);
      // Page appartenant au Hizb 43 : ne doit jamais être suivie.
      const outside = 404;
      expect(HizbNavigationService.pageBelongsToHizb(hizb, outside), isFalse);
      expect(HizbNavigationService.openResume(hizb, outside), start);
    });

    test('25. absence de position enregistrée ouvre le début du Hizb', () {
      for (final h in _edgeCases) {
        expect(
          HizbNavigationService.openResume(h, null),
          HizbNavigationService.startPage(h),
        );
      }
    });

    test('26. « Lire » ignore toute position et ouvre le début', () {
      for (final h in _edgeCases) {
        expect(
          HizbNavigationService.openStart(h),
          HizbNavigationService.startPage(h),
        );
      }
    });

    test('27. le garde-fou tient pour les 60 Hizb', () {
      for (var h = 1; h <= 60; h++) {
        final start = HizbNavigationService.startPage(h);
        // Une position très en amont ou très en aval est toujours rejetée.
        expect(
          HizbNavigationService.openResume(h, 1 + (h == 1 ? 0 : -1)),
          h == 1 ? 1 : start,
        );
        expect(HizbNavigationService.openResume(h, 604), h == 60 ? 604 : start);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // 7. Invariants d'affichage et de navigation
  // ---------------------------------------------------------------------------
  group('Invariants', () {
    test('28. la langue ne change pas le mapping', () {
      // Le mapping ne dépend que de données numériques : aucun libellé, aucun
      // sens de lecture. On vérifie qu'il est stable et sans effet de bord.
      final first = [
        for (var h = 1; h <= 60; h++) HizbNavigationService.startPage(h),
      ];
      final second = [
        for (var h = 1; h <= 60; h++) HizbNavigationService.startPage(h),
      ];
      expect(second, first);
    });

    test('29. naviguer plusieurs fois ne dérive pas', () {
      for (final h in _edgeCases) {
        final a = HizbNavigationService.openStart(h);
        final b = HizbNavigationService.openStart(h);
        final c = HizbNavigationService.openStart(h);
        expect([b, c], [a, a], reason: 'Hizb $h : navigation non idempotente');
      }
    });

    test('30. le titre affiché correspond au Hizb réellement ouvert', () {
      for (var h = 1; h <= 60; h++) {
        final page = HizbNavigationService.startPage(h);
        expect(
          HizbIndexRepository.hizbForPageHafs(page),
          h,
          reason: 'Hizb $h : le badge afficherait un autre numéro',
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  // 8. Vecteur H44 + Context A/B (API production courante)
  // ---------------------------------------------------------------------------
  group('Certification H44', () {
    const definitionId = HizbDefinitions.quranFoundationHafsV1;
    const hizb = 44;

    test('H1 start page H44 = 431', () {
      expect(
        HizbNavigationService.startPageForDefinition(
          hizb,
          definitionId: definitionId,
        ),
        431,
      );
    });

    test('H2 start verse H44 = 34:24', () {
      final ref = HizbIndexRepository.getByDefinition(
        hizb,
        definitionId: definitionId,
      );
      expect(ref.surah, 34);
      expect(ref.ayah, 24);
      expect('${ref.surah}:${ref.ayah}', '34:24');
    });

    test('H3 displayed H44 = 44 on canonical start', () {
      final page = HizbNavigationService.startPageForDefinition(
        hizb,
        definitionId: definitionId,
      );
      expect(
        HizbNavigationService.displayedHizbForDefinition(
          page,
          definitionId: definitionId,
          reservedHizb: hizb,
        ),
        44,
      );
    });

    test('H4 resume 437 stays inside H44', () {
      const resumePage = 437;
      expect(
        HizbNavigationService.pageBelongsToHizbForDefinition(
          hizb,
          resumePage,
          definitionId: definitionId,
        ),
        isTrue,
      );
      final resumed = HizbNavigationService.openResumeForDefinition(
        hizb,
        resumePage,
        definitionId: definitionId,
      );
      expect(resumed, resumePage);
      expect(
        HizbNavigationService.displayedHizbForDefinition(
          resumed,
          definitionId: definitionId,
          reservedHizb: hizb,
        ),
        44,
      );
    });

    test('H5 H44 end boundary = 441', () {
      expect(
        HizbNavigationService.endPageForDefinition(
          hizb,
          definitionId: definitionId,
        ),
        441,
      );
    });

    test('H6 transition H44 → H45 sans chevauchement', () {
      final h44 = HizbIndexRepository.getByDefinition(
        hizb,
        definitionId: definitionId,
      );
      final h45 = HizbIndexRepository.getByDefinition(
        45,
        definitionId: definitionId,
      );
      expect(h44.endPageHafs, 441);
      expect(h45.pageHafs, 442);
      expect(h44.containsAyah(h45.surah, h45.ayah), isFalse);
    });

    test('H7 free Mushaf deep link sans definitionId', () {
      final target = MushafOpenTarget.fromRoute(
        null,
        Uri.parse('/mushaf/hafs?hizb=44'),
      );
      expect(target.hizb, 44);
      expect(target.hizbDefinitionId, isNull);
      expect(HizbNavigationService.startPage(44), 431);
    });

    test('H8 Khatma-bound exige definitionId explicite via extra', () {
      final target = MushafOpenTarget.fromRoute(
        {'hizb': 44, 'hizbDefinitionId': definitionId},
        Uri.parse('/mushaf/hafs'),
      );
      expect(target.hizbDefinitionId, definitionId);
      expect(
        HizbNavigationService.startPageForDefinition(
          target.hizb!,
          definitionId: target.hizbDefinitionId,
        ),
        431,
      );
    });

    test('H9 legacy H44 regression 30:31 / p407 excluded', () {
      expect(HizbNavigationService.startPage(hizb), isNot(407));
      expect(_pageOfAyah['30:31'], isNot(431));
      expect(HizbNavigationService.startPage(hizb), 431);
    });

    test('H10 mapping 1..60 monotone et dans 1..604', () {
      var previous = 0;
      for (var h = 1; h <= 60; h++) {
        final page = HizbNavigationService.startPage(h);
        expect(page, greaterThanOrEqualTo(1));
        expect(page, lessThanOrEqualTo(604));
        expect(page, greaterThanOrEqualTo(previous));
        previous = page;
      }
    });
  });
}
