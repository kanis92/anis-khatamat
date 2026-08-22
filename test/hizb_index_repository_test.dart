import 'package:flutter_test/flutter_test.dart';

import 'package:anis_khatamat/core/repositories/hizb_index_repository.dart';
import 'package:anis_khatamat/core/data/quran_hizb_data.dart';
import 'package:anis_khatamat/core/data/quran_subdivision_data.dart';

void main() {
  group('HizbIndexRepository', () {
    // ------------------------------------------------------------------
    // Test 1 : Exactement 60 entrées, numéros 1..60 dans l'ordre
    // ------------------------------------------------------------------
    test('getAllHizbRefs returns exactly 60 refs with hizbNumber 1..60', () {
      final refs = HizbIndexRepository.getAllHizbRefs();
      expect(refs.length, 60, reason: 'Must have exactly 60 Hizb refs');
      for (var i = 0; i < refs.length; i++) {
        expect(
          refs[i].hizbNumber,
          i + 1,
          reason: 'Index $i should be Hizb ${i + 1}',
        );
      }
    });

    // ------------------------------------------------------------------
    // Test 2 : getByNumber(n).hizbNumber == n pour tout n in 1..60
    // ------------------------------------------------------------------
    test('getByNumber returns correct hizbNumber for all 1..60', () {
      for (var n = 1; n <= 60; n++) {
        final ref = HizbIndexRepository.getByNumber(n);
        expect(
          ref.hizbNumber,
          n,
          reason: 'getByNumber($n).hizbNumber should be $n',
        );
      }
    });

    // ------------------------------------------------------------------
    // Test 3 : getByNumber hors plage lève ArgumentError
    // ------------------------------------------------------------------
    test('getByNumber throws ArgumentError for out-of-range values', () {
      expect(() => HizbIndexRepository.getByNumber(0), throwsArgumentError);
      expect(() => HizbIndexRepository.getByNumber(61), throwsArgumentError);
    });

    // ------------------------------------------------------------------
    // Test 4 : Chaque ref a des valeurs de page valides
    // ------------------------------------------------------------------
    test('all refs have valid page numbers', () {
      final refs = HizbIndexRepository.getAllHizbRefs();
      for (final ref in refs) {
        expect(
          ref.pageHafs,
          greaterThanOrEqualTo(1),
          reason: 'Hizb ${ref.hizbNumber}: pageHafs >= 1',
        );
        expect(
          ref.pageHafs,
          lessThanOrEqualTo(604),
          reason: 'Hizb ${ref.hizbNumber}: pageHafs <= 604',
        );
        expect(
          ref.pageWarsh,
          greaterThanOrEqualTo(1),
          reason: 'Hizb ${ref.hizbNumber}: pageWarsh >= 1',
        );
      }
    });

    // ------------------------------------------------------------------
    // Test 5 : Les pages Hafs sont monotones croissantes
    // ------------------------------------------------------------------
    test('pageHafs is non-decreasing across all Hizbs', () {
      final refs = HizbIndexRepository.getAllHizbRefs();
      for (var i = 1; i < refs.length; i++) {
        expect(
          refs[i].pageHafs,
          greaterThanOrEqualTo(refs[i - 1].pageHafs),
          reason:
              'Hizb ${refs[i].hizbNumber} pageHafs (${refs[i].pageHafs}) '
              'must be >= Hizb ${refs[i - 1].hizbNumber} (${refs[i - 1].pageHafs})',
        );
      }
    });

    // ------------------------------------------------------------------
    // Test 6 : Chaque incipit est non vide
    // ------------------------------------------------------------------
    test('all incipitAr are non-empty', () {
      final refs = HizbIndexRepository.getAllHizbRefs();
      for (final ref in refs) {
        expect(
          ref.incipitAr,
          isNotEmpty,
          reason: 'Hizb ${ref.hizbNumber}: incipitAr must not be empty',
        );
      }
    });

    // ------------------------------------------------------------------
    // Test 7 : rangeStr cohérent avec QuranHizbData.hizbList
    // ------------------------------------------------------------------
    test('rangeStr matches QuranHizbData for all Hizbs', () {
      final refs = HizbIndexRepository.getAllHizbRefs();
      for (final ref in refs) {
        final expected = QuranHizbData.getHizbData(ref.hizbNumber)['range'];
        expect(
          ref.rangeStr,
          expected,
          reason:
              'Hizb ${ref.hizbNumber}: rangeStr mismatch: '
              '"${ref.rangeStr}" vs "$expected"',
        );
      }
    });

    // ------------------------------------------------------------------
    // Test 8 : surah:ayah de la ref correspond au premier quarter de _rubData
    // ------------------------------------------------------------------
    test('surah:ayah matches QuranSubdivisionData first quarter', () {
      for (var n = 1; n <= 60; n++) {
        final ref = HizbIndexRepository.getByNumber(n);
        final quarters = QuranSubdivisionData.getQuartersForHizb(n);
        expect(
          quarters,
          isNotEmpty,
          reason: 'Hizb $n must have quarters in QuranSubdivisionData',
        );
        final first = quarters.first;
        expect(
          ref.surah,
          first.surah,
          reason: 'Hizb $n: surah mismatch (${ref.surah} vs ${first.surah})',
        );
        expect(
          ref.ayah,
          first.ayah,
          reason: 'Hizb $n: ayah mismatch (${ref.ayah} vs ${first.ayah})',
        );
        expect(
          ref.pageHafs,
          first.pageHafs,
          reason:
              'Hizb $n: pageHafs mismatch (${ref.pageHafs} vs ${first.pageHafs})',
        );
      }
    });

    // ------------------------------------------------------------------
    // Test 9 : juz dans [1, 30] et cohérent avec la formule ((n-1)÷2)+1
    // ------------------------------------------------------------------
    test('juz is correctly computed for all Hizbs', () {
      final refs = HizbIndexRepository.getAllHizbRefs();
      for (final ref in refs) {
        final expectedJuz = ((ref.hizbNumber - 1) ~/ 2) + 1;
        expect(
          ref.juz,
          expectedJuz,
          reason: 'Hizb ${ref.hizbNumber}: juz should be $expectedJuz',
        );
        expect(ref.juz, greaterThanOrEqualTo(1));
        expect(ref.juz, lessThanOrEqualTo(30));
      }
    });

    // ------------------------------------------------------------------
    // Test 10 : getByPageHafs retourne le bon Hizb pour des pages connues
    // ------------------------------------------------------------------
    test('getByPageHafs returns correct Hizb for known pages', () {
      // Hizb 1 commence à la page 1
      expect(HizbIndexRepository.getByPageHafs(1).hizbNumber, 1);
      // La page du premier Hizb doit donner le Hizb 1
      final h1Page = HizbIndexRepository.getByNumber(1).pageHafs;
      expect(HizbIndexRepository.getByPageHafs(h1Page).hizbNumber, 1);
      // Dernière page (604) → Hizb 60
      expect(HizbIndexRepository.getByPageHafs(604).hizbNumber, 60);
    });

    // ------------------------------------------------------------------
    // Test 11 : Hizb 60 a les valeurs Quran Foundation (Al-A'la 87:1)
    // ------------------------------------------------------------------
    test('Hizb 60 starts at surah 87, ayah 1 (Al-Ala)', () {
      final ref = HizbIndexRepository.getByNumber(60);
      expect(ref.surah, 87, reason: 'Hizb 60 must start at Al-Ala (87)');
      expect(ref.ayah, 1);
      expect(ref.pageHafs, 591, reason: 'Hizb 60 in Hafs starts at page 591');
      expect(ref.endPageHafs, 604);
      expect(ref.rangeStr, contains('87:1'));
    });

    // ------------------------------------------------------------------
    // Test 12 : Hizb 1 a les bonnes valeurs (Al-Fatiha 1:1, page 1)
    // ------------------------------------------------------------------
    test('Hizb 1 starts at surah 1, ayah 1, page 1', () {
      final ref = HizbIndexRepository.getByNumber(1);
      expect(ref.surah, 1);
      expect(ref.ayah, 1);
      expect(ref.pageHafs, 1);
    });

    // ------------------------------------------------------------------
    // Test 13 : QuranHizbData.getHizbForAyah cohérent avec la ref
    // ------------------------------------------------------------------
    test(
      'QuranHizbData.getHizbForAyah agrees with repository for start ayahs',
      () {
        // For each Hizb, getHizbForAyah(startSurah, startAyah) == hizbNumber
        for (var n = 1; n <= 60; n++) {
          final ref = HizbIndexRepository.getByNumber(n);
          final computed = QuranHizbData.getHizbForAyah(ref.surah, ref.ayah);
          expect(
            computed,
            n,
            reason:
                'QuranHizbData.getHizbForAyah(${ref.surah}, ${ref.ayah}) '
                'should return $n, got $computed',
          );
        }
      },
    );

    // ------------------------------------------------------------------
    // Test 14 : getAllHizbRefs() est stable (même référence à chaque appel)
    // ------------------------------------------------------------------
    test('getAllHizbRefs returns the same cached list', () {
      final refs1 = HizbIndexRepository.getAllHizbRefs();
      final refs2 = HizbIndexRepository.getAllHizbRefs();
      expect(
        identical(refs1, refs2),
        isTrue,
        reason: 'getAllHizbRefs must be cached and return identical reference',
      );
    });
  });
}
