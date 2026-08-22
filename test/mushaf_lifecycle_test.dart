import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quran/src/app_bloc.dart';
import 'package:flutter_quran/src/controllers/bookmarks_controller.dart';
import 'package:flutter_quran/src/controllers/quran_controller.dart';
import 'package:flutter_quran/src/repository/quran_repository.dart';
import 'package:flutter_quran/src/utils/flutter_quran_utils.dart';
import 'package:flutter_quran/src/utils/preferences/preferences_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anis_khatamat/core/services/hizb_navigation_service.dart';

/// Reproduit la séquence runtime : ouverture Mushaf → navigation → fermeture → réouverture.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PreferencesUtils().preferences = await SharedPreferences.getInstance();
    await AppBloc.resetForTesting();
  });

  tearDown(() => AppBloc.resetForTesting());

  test('les Cubits appartiennent à la session et survivent aux écrans', () {
    final bookmarks = AppBloc.ensureBookmarksCubit();
    final quran = AppBloc.ensureQuranCubit();
    expect(bookmarks.isClosed, isFalse);
    expect(quran.isClosed, isFalse);
    expect(AppBloc.providers, hasLength(2));
    expect(identical(AppBloc.ensureBookmarksCubit(), bookmarks), isTrue);
    expect(identical(AppBloc.ensureQuranCubit(), quran), isTrue);
  });

  test(
    'le timer de surbrillance est annulé par le propriétaire avant close',
    () async {
      final bookmarks = BookmarksCubit();
      bookmarks.initBookmarks();
      bookmarks.highlightSearchResult(
        ayahId: 1,
        page: 1,
        duration: const Duration(milliseconds: 10),
      );

      await bookmarks.close();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(bookmarks.isClosed, isTrue);
    },
  );

  test('QuranCubit attend son chargement avant de fermer son flux', () async {
    final quran = QuranCubit(quranRepository: _DelayedQuranRepository());
    final loading = quran.loadQuran();
    final closing = quran.close();

    await Future.wait([loading, closing]);

    expect(quran.isClosed, isTrue);
  });

  test(
    'navigateToAyah puis réouverture conserve les Cubits de session',
    () async {
      final flutterQuran = FlutterQuran();
      await flutterQuran.init();
      final quran = AppBloc.ensureQuranCubit();
      final bookmarks = AppBloc.ensureBookmarksCubit();
      final ayah = AppBloc.ensureQuranCubit().getAyahBySurahAndVerse(30, 31);
      expect(ayah, isNotNull);

      flutterQuran.navigateToAyah(ayah!);
      await flutterQuran.init();
      final h44 = AppBloc.ensureQuranCubit().getAyahBySurahAndVerse(30, 31);
      expect(() => flutterQuran.navigateToAyah(h44!), returnsNormally);

      await Future<void>.delayed(const Duration(seconds: 3));
      expect(identical(AppBloc.ensureQuranCubit(), quran), isTrue);
      expect(identical(AppBloc.ensureBookmarksCubit(), bookmarks), isTrue);
      expect(quran.isClosed, isFalse);
      expect(bookmarks.isClosed, isFalse);
    },
  );

  test(
    'stress Hafs → Warsh → Women → Khatma/Hizb 44 → retour → réouverture',
    () async {
      await FlutterQuran().init();
      final quran = AppBloc.ensureQuranCubit();
      final bookmarks = AppBloc.ensureBookmarksCubit();

      for (var cycle = 0; cycle < 6; cycle++) {
        // Hafs → retour → Hafs → navigation Hizb.
        expect(AppBloc.providers, hasLength(2));
        FlutterQuran().navigateToPage(10 + cycle);
        final intermediateHizb = 10 + cycle;
        HizbNavigationService.openStart(intermediateHizb);

        // Warsh → retour.
        expect(AppBloc.providers, hasLength(2));
        FlutterQuran().navigateToPage(200 + cycle);

        // Women → retour.
        expect(AppBloc.providers, hasLength(2));
        FlutterQuran().navigateToPage(300 + cycle);

        // Khatma → Hizb 44 → Lire.
        expect(AppBloc.providers, hasLength(2));
        expect(HizbNavigationService.openStart(44), 431);
        expect(HizbNavigationService.displayedHizb(431, reservedHizb: 44), 44);

        // Retour puis réouverture de la même réservation.
        expect(AppBloc.providers, hasLength(2));
        expect(HizbNavigationService.openResume(44, 431), 431);
        await Future<void>.delayed(Duration.zero);
      }

      // Laisse expirer la dernière surbrillance après fermeture de l'écran.
      await Future<void>.delayed(const Duration(seconds: 4));

      expect(identical(AppBloc.ensureQuranCubit(), quran), isTrue);
      expect(identical(AppBloc.ensureBookmarksCubit(), bookmarks), isTrue);
      expect(quran.isClosed, isFalse);
      expect(bookmarks.isClosed, isFalse);
    },
  );
}

class _DelayedQuranRepository extends QuranRepository {
  @override
  Future<List<dynamic>> getQuran() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return super.getQuran();
  }
}
