import 'dart:convert';
import 'dart:io';

import 'package:anis_khatamat/core/data/hizb_canonical_data.dart';
import 'package:anis_khatamat/core/data/quran_subdivision_data.dart';
import 'package:anis_khatamat/core/models/hizb_display_metadata.dart';
import 'package:anis_khatamat/core/repositories/hizb_index_repository.dart';
import 'package:anis_khatamat/core/services/hizb_navigation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final external = _loadExternalReference();
  final surahByNumber = {
    for (final surah in QuranSubdivisionData.surahList)
      surah['number']! as int: surah,
  };
  final renderedAyahs = _loadRenderedAyahs();

  group('Quran Foundation → modèle canonique → Mushaf rendu', () {
    test('les 60 Hizb correspondent au dataset externe figé', () {
      expect(external, hasLength(60));
      expect(HizbCanonicalData.refs, hasLength(60));

      for (var index = 0; index < external.length; index++) {
        final expected = external[index];
        final canonical = HizbCanonicalData.refs[index];
        final ref = HizbIndexRepository.getByNumber(expected.hizb);

        expect(canonical.hizbNumber, expected.hizb);
        expect(canonical.juzNumber, expected.juz);
        expect(canonical.startRef, expected.start);
        expect(canonical.endRef, expected.end);
        expect(canonical.startPageHafs, expected.startPage);
        expect(canonical.endPageHafs, expected.endPage);

        expect(ref.rangeStr, '${expected.start} - ${expected.end}');
        expect(ref.pageHafs, expected.startPage);
        expect(ref.endPageHafs, expected.endPage);
        expect(ref.juz, expected.juz);
      }
    });

    test('chaque borne existe réellement dans le JSON Hafs rendu', () {
      for (final expected in external) {
        expect(
          renderedAyahs[expected.start],
          expected.startPage,
          reason: 'Hizb ${expected.hizb} start ${expected.start}',
        );
        expect(
          renderedAyahs[expected.end],
          expected.endPage,
          reason: 'Hizb ${expected.hizb} end ${expected.end}',
        );
      }
    });

    test('les 240 Rub el Hizb correspondent à quatre marqueurs par Hizb', () {
      final markers = QuranSubdivisionData.getAllQuarters();
      expect(markers, hasLength(240));

      for (final expected in external) {
        final quarters = QuranSubdivisionData.getQuartersForHizb(expected.hizb);
        expect(quarters, hasLength(4));
        expect((expected.hizb - 1) * 4 + 1, expected.startRub);
        expect(expected.hizb * 4, expected.endRub);
        for (final marker in quarters) {
          expect(
            renderedAyahs['${marker.surah}:${marker.ayah}'],
            marker.pageHafs,
          );
        }
      }
    });

    test('les ayat, sourates, ordres et listes traversées sont valides', () {
      for (var hizb = 1; hizb <= 60; hizb++) {
        final metadata = HizbDisplayMetadata.fromHizb(hizb, languageCode: 'fr');
        final startSurah = surahByNumber[metadata.startSurah]!;
        final endSurah = surahByNumber[metadata.endSurah]!;

        expect(
          metadata.startAyah,
          inInclusiveRange(1, startSurah['verses']! as int),
        );
        expect(
          metadata.endAyah,
          inInclusiveRange(1, endSurah['verses']! as int),
        );
        expect(metadata.juzNumber, ((hizb - 1) ~/ 2) + 1);
        expect(
          metadata.surahs.map((surah) => surah.number),
          List.generate(
            metadata.endSurah - metadata.startSurah + 1,
            (index) => metadata.startSurah + index,
          ),
        );
      }
    });

    test('cas explicites 1, 2, 29, 30, 44, 57, 58, 59, 60', () {
      const expected = {
        1: ('1:1', '2:74', 1, 11),
        2: ('2:75', '2:141', 11, 21),
        29: ('17:1', '17:98', 282, 292),
        30: ('17:99', '18:74', 292, 301),
        44: ('34:24', '36:27', 431, 441),
        57: ('67:1', '71:28', 562, 571),
        58: ('72:1', '77:50', 572, 581),
        59: ('78:1', '86:17', 582, 591),
        60: ('87:1', '114:6', 591, 604),
      };

      for (final entry in expected.entries) {
        final metadata = HizbDisplayMetadata.fromHizb(
          entry.key,
          languageCode: 'fr',
        );
        expect(metadata.startRef, entry.value.$1);
        expect(metadata.endRef, entry.value.$2);
        expect(metadata.startPageHafs, entry.value.$3);
        expect(metadata.endPageHafs, entry.value.$4);
      }

      expect(HizbNavigationService.startPage(44), 431);
      expect(HizbNavigationService.endPage(44), 441);
      expect(HizbNavigationService.displayedHizb(431), 44);
    });
  });

  group('HizbDisplayMetadata localisé', () {
    test('Hizb 58', () {
      final fr = HizbDisplayMetadata.fromHizb(58, languageCode: 'fr');
      final ar = HizbDisplayMetadata.fromHizb(58, languageCode: 'ar');
      expect(fr.localizedSurahLabel, 'Al-Jinn → Al-Mursalat');
      expect(ar.localizedSurahLabel, 'الجن ← المرسلات');
      expect(fr.rangeLabel, '72:1 – 77:50');
      expect(fr.localizedPagesLabel, 'Pages 572–581');
    });

    test('Hizb 59', () {
      final fr = HizbDisplayMetadata.fromHizb(59, languageCode: 'fr');
      expect(fr.localizedSurahLabel, 'An-Naba → At-Tariq');
      expect(fr.rangeLabel, '78:1 – 86:17');
      expect(fr.localizedJuzLabel, 'Juz 30');
      expect(fr.localizedPagesLabel, 'Pages 582–591');
    });

    test('Hizb 60', () {
      final fr = HizbDisplayMetadata.fromHizb(60, languageCode: 'fr');
      final ar = HizbDisplayMetadata.fromHizb(60, languageCode: 'ar');
      final en = HizbDisplayMetadata.fromHizb(60, languageCode: 'en');
      expect(fr.localizedSurahLabel, 'Al-A\'la → An-Nas');
      expect(ar.localizedSurahLabel, 'الأعلى ← الناس');
      expect(en.localizedSurahLabel, 'Al-A\'la → An-Nas');
      expect(fr.rangeLabel, '87:1 – 114:6');
      expect(fr.localizedPagesLabel, 'Pages 591–604');
      expect(fr.surahs, hasLength(28));
    });
  });

  // Distribution-screen widget integration for H58–60 belongs to the
  // collaborative UI checkpoint (HizbDisplayMetadata cards). Canonical
  // metadata for H58–60 is certified above via fixture, domain and metadata
  // unit tests against HEAD production APIs.
}

Map<String, int> _loadRenderedAyahs() {
  final raw =
      jsonDecode(
            File(
              'packages/flutter_quran/lib/assets/jsons/quran_hafs.json',
            ).readAsStringSync(),
          )
          as List<dynamic>;
  return {
    for (final item in raw)
      '${item['sora']}:${item['aya_no']}': item['page']! as int,
  };
}

List<_ExternalHizb> _loadExternalReference() {
  final lines =
      File('test/fixtures/quran_foundation_hizb_v4.csv').readAsLinesSync();
  return lines
      .skip(1)
      .map((line) {
        final cells = line.split(',');
        return _ExternalHizb(
          hizb: int.parse(cells[0]),
          juz: int.parse(cells[1]),
          start: cells[2],
          end: cells[3],
          startPage: int.parse(cells[4]),
          endPage: int.parse(cells[5]),
          startRub: int.parse(cells[6]),
          endRub: int.parse(cells[7]),
        );
      })
      .toList(growable: false);
}

class _ExternalHizb {
  const _ExternalHizb({
    required this.hizb,
    required this.juz,
    required this.start,
    required this.end,
    required this.startPage,
    required this.endPage,
    required this.startRub,
    required this.endRub,
  });

  final int hizb;
  final int juz;
  final String start;
  final String end;
  final int startPage;
  final int endPage;
  final int startRub;
  final int endRub;
}
