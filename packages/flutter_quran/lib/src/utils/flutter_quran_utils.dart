import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quran/src/app_bloc.dart';
import 'package:flutter_quran/src/models/ayah.dart';
import 'package:flutter_quran/src/models/bookmark.dart';
import 'package:flutter_quran/src/models/surah.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quran_constants.dart';
import 'preferences/preferences_utils.dart';

class FlutterQuran {
  /// [init] initializes the FlutterQuran, and must be called before starting using the package
  Future<void> init(
      {List<Bookmark>? userBookmarks, bool overwriteBookmarks = false}) async {
    PreferencesUtils().preferences = await SharedPreferences.getInstance();
    final quran = AppBloc.ensureQuranCubit();
    final bookmarks = AppBloc.ensureBookmarksCubit();
    await quran.loadQuran();
    bookmarks.initBookmarks(
        userBookmarks: userBookmarks, overwrite: overwriteBookmarks);
  }

  /// [getCurrentPageNumber] Returns the page number of the page that the user is currently on.
  /// Page numbers start at 1, so the first page of the Quran is page 1.
  int getCurrentPageNumber() => AppBloc.quranCubit.lastPage;

  /// [search] Searches the Quran for the given text.
  ///
  /// Returns a list of all Ayahs whose text contains the given text.
  List<Ayah> search(String text) => AppBloc.quranCubit.search(text);

  /// [navigateToAyah] let's you navigate to any ayah..
  /// It's better to call this method while Quran screen is displayed
  /// and if it's called and the Quran screen is not displayed, the next time you
  /// open quran screen it will start from this ayah's page
  void navigateToAyah(Ayah ayah) {
    final quran = AppBloc.ensureQuranCubit();
    final bookmarks = AppBloc.ensureBookmarksCubit();
    quran.animateToPage(ayah.page - 1);
    bookmarks.highlightSearchResult(ayahId: ayah.id, page: ayah.page);
  }

  /// [navigateToPage] let's you navigate to any quran page with page number
  /// Note it receives page number not page index
  /// It's better to call this method while Quran screen is displayed
  /// and if it's called and the Quran screen is not displayed, the next time you
  /// open quran screen it will start from this page
  void navigateToPage(int page) => AppBloc.quranCubit.animateToPage(page - 1);

  /// [navigateToJozz] let's you navigate to any quran jozz with jozz number
  /// Note it receives jozz number not jozz index
  void navigateToJozz(int jozz) => navigateToPage(
      jozz == 1 ? 0 : (AppBloc.quranCubit.quranStops[(jozz - 1) * 8 - 1]));

  /// Retourne l'Ayah pour une sourate et un verset donnés. null si non trouvé.
  Ayah? getAyahBySurahAndVerse(int surah, int verse) =>
      AppBloc.quranCubit.getAyahBySurahAndVerse(surah, verse);

  /// Retourne la première ayah de la page (pour calcul du Hizb via QuranHizbData).
  /// Utilise la liste globale ayahs (ordre Coran) pour cohérence pagination.
  /// Fallback sur staticPages si ayahs vide (évite Hizb 1 erroné à l'ouverture).
  Ayah? getFirstAyahOnPage(int page) {
    if (page < 1 || page > 604) return null;
    final allAyahs = AppBloc.quranCubit.ayahs;
    if (allAyahs.isNotEmpty) {
      try {
        return allAyahs.firstWhere((a) => a.page == page);
      } catch (_) {}
    }
    // Fallback : staticPages (peut être prêt avant ayahs dans certains cas)
    final pages = AppBloc.quranCubit.staticPages;
    if (pages.isNotEmpty && page <= pages.length) {
      final pageAyahs = pages[page - 1].ayahs;
      if (pageAyahs.isNotEmpty) return pageAyahs.first;
    }
    return null;
  }

  /// [navigateToHizb] navigue vers le premier verset du Hizb décrit par
  /// [startRange] (format 'surah:ayah - surah:ayah').
  /// Retourne le numéro de page atteint, ou null si la cible est introuvable.
  ///
  /// Aucun repli vers le début de la sourate : le premier verset d'un Hizb est
  /// rarement le verset 1, et un tel repli fait atterrir dans le Hizb précédent.
  /// L'appelant doit décider quoi faire d'un null (côté app :
  /// `HizbNavigationService` utilise sa table de pages canonique).
  int? navigateToHizb(int hizb, {String? startRange}) {
    if (startRange == null || startRange.isEmpty) return null;

    final parts = startRange.split(' - ').first.trim().split(':');
    if (parts.length < 2) return null;
    final surah = int.tryParse(parts[0].trim());
    final verse = int.tryParse(parts[1].trim());
    if (surah == null || verse == null) return null;

    final ayah = getAyahBySurahAndVerse(surah, verse);
    if (ayah != null) {
      if (kDebugMode) {
        debugPrint('[FlutterQuran] navigateToHizb: hizb=$hizb → '
            '$surah:$verse page=${ayah.page}');
      }
      navigateToAyah(ayah);
      return ayah.page;
    }

    // Le Mushaf n'est pas encore chargé : surahsStart reste exploitable pour un
    // début de sourate, qui est alors exactement le début du Hizb.
    final starts = AppBloc.quranCubit.surahsStart;
    if (verse == 1 && surah >= 1 && surah <= starts.length) {
      final page = starts[surah - 1] + 1;
      navigateToPage(page);
      return page;
    }

    if (kDebugMode) {
      debugPrint('[FlutterQuran] navigateToHizb: $surah:$verse introuvable '
          '(ayahs=${AppBloc.quranCubit.ayahs.length})');
    }
    return null;
  }

  /// Retourne la page du symbole ۞ d'index [hizb] dans le Mushaf.
  ///
  /// Les marqueurs ۞ du JSON ne suivent pas le découpage en 60 Hizb utilisé
  /// par l'application : ne pas s'en servir pour naviguer par Hizb.
  int? getPageForHizbMarker(int hizb) {
    final stops = AppBloc.quranCubit.quranStops;
    if (stops.isEmpty) return null;
    final idx = (hizb - 1) * 4;
    return idx < stops.length ? stops[idx] : stops.last;
  }

  /// [navigateToBookmark] let's you navigate to a certain bookmark
  /// Note that bookmark page number must be between 1 and 604
  void navigateToBookmark(Bookmark bookmark) {
    if (bookmark.page > 0 && bookmark.page <= 604) {
      navigateToPage(bookmark.page);
    } else {
      throw Exception("Page number must be between 1 and 604");
    }
  }

  /// [navigateToSurah] let's you navigate to any quran surah with surah number
  /// Note it receives surah number not surah index
  void navigateToSurah(int surah) =>
      navigateToPage(AppBloc.quranCubit.surahsStart[surah - 1] + 1);

  ///[getAllJozzs] returns list of all Quran jozzs' names
  List<String> getAllJozzs() => QuranConstants.quranHizbs
      .sublist(0, 30)
      .map((jozz) => "الجزء $jozz")
      .toList();

  ///[getAllHizbs] returns list of all Quran hizbs' names
  List<String> getAllHizbs() =>
      QuranConstants.quranHizbs.map((jozz) => "الحزب $jozz").toList();

  /// [getSurah] let's you get a Surah with all its data
  /// Note it receives surah number not surah index
  Surah getSurah(int surah) => AppBloc.quranCubit.surahs[surah - 1];

  ///[getAllSurahs] returns list of all Quran surahs' names
  List<String> getAllSurahs({bool isArabic = true}) => AppBloc.quranCubit.surahs
      .map((surah) => "سورة ${isArabic ? surah.nameAr : surah.nameEn}")
      .toList();

  ///[getAllBookmarks] returns list of all bookmarks
  List<Bookmark> getAllBookmarks() => AppBloc.bookmarksCubit.bookmarks
      .sublist(0, AppBloc.bookmarksCubit.bookmarks.length - 1);

  ///[getUsedBookmarks] returns list of all bookmarks used and set by the user in quran pages
  List<Bookmark> getUsedBookmarks() =>
      AppBloc.bookmarksCubit.bookmarks.where((b) => b.page != -1).toList();

  /// Sets a bookmark with the given [ayahId], [page] and [bookmarkId].
  ///
  /// [ayahId] is the id of the ayah to be saved.
  /// [page] is the page number of the ayah.
  /// [bookmarkId] is the id of the bookmark to be saved.
  ///
  /// You can't save a bookmark with a page number that is not between 1 and 604.
  void setBookmark(
          {required int ayahId, required int page, required int bookmarkId}) =>
      AppBloc.bookmarksCubit
          .saveBookmark(ayahId: ayahId, page: page, bookmarkId: bookmarkId);

  /// Removes a bookmark from the list of user's saved bookmarks.
  /// [bookmarkId] is the id of the bookmark to be removed.
  void removeBookmark({required int bookmarkId}) =>
      AppBloc.bookmarksCubit.removeBookmark(bookmarkId);

  /// [hafsStyle] is the default style for Quran so all special characters will be rendered correctly
  final hafsStyle = const TextStyle(
    color: Colors.black,
    fontSize: 23.55,
    fontFamily: "hafs",
    package: "flutter_quran",
  );

  ///Singleton factory
  static final FlutterQuran _instance = FlutterQuran._internal();

  factory FlutterQuran() {
    return _instance;
  }

  FlutterQuran._internal();
}
