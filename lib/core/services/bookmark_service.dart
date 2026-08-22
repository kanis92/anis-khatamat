import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/bookmark.dart';
import '../repositories/hizb_index_repository.dart';

/// Service de gestion des signets
class BookmarkService {
  static const _key = 'anis_bookmarks';

  Future<List<Bookmark>> getBookmarks(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_key$userId');
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => Bookmark.fromMap(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addBookmark(String userId, int surahNumber, int verseNumber,
      {int? pageNumber, String? note}) async {
    final list = await getBookmarks(userId);
    if (pageNumber != null) {
      if (list.any((b) => b.pageNumber == pageNumber)) return;
    } else if (list.any((b) =>
        b.surahNumber == surahNumber && b.verseNumber == verseNumber)) {
      return;
    }
    list.add(Bookmark(
      id: const Uuid().v4(),
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      pageNumber: pageNumber,
      note: note,
      createdAt: DateTime.now(),
    ));
    await _save(userId, list);
  }

  /// Ajoute un signet pour une page Mushaf (pause/reprise)
  Future<void> addPageBookmark(String userId, int pageNumber, {String? note}) async {
    final (surah, verse) = _pageToFirstVerse(pageNumber);
    await addBookmark(userId, surah, verse, pageNumber: pageNumber, note: note);
  }

  /// Sourate/verset de repère pour une page : début du Hizb auquel la page
  /// appartient. Le Hizb vient de la table canonique, jamais d'une règle de
  /// trois sur les 604 pages (les Hizb sont de longueurs inégales).
  static (int, int) _pageToFirstVerse(int page) {
    if (page < 1 || page > 604) return (1, 1);
    final ref = HizbIndexRepository.getByPageHafs(page);
    return (ref.surah, ref.ayah);
  }

  Future<void> removeBookmark(String userId, String bookmarkId) async {
    final list = await getBookmarks(userId);
    list.removeWhere((b) => b.id == bookmarkId);
    await _save(userId, list);
  }

  Future<void> updateNote(String userId, String bookmarkId, String? note) async {
    final list = await getBookmarks(userId);
    final idx = list.indexWhere((b) => b.id == bookmarkId);
    if (idx >= 0) {
      list[idx] = Bookmark(
        id: list[idx].id,
        surahNumber: list[idx].surahNumber,
        verseNumber: list[idx].verseNumber,
        note: note,
        createdAt: list[idx].createdAt,
      );
      await _save(userId, list);
    }
  }

  Future<bool> isBookmarked(
      String userId, int surahNumber, int verseNumber) async {
    final list = await getBookmarks(userId);
    return list.any((b) =>
        b.surahNumber == surahNumber && b.verseNumber == verseNumber);
  }

  Future<void> _save(String userId, List<Bookmark> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_key$userId',
      jsonEncode(list.map((b) => b.toMap()).toList()),
    );
  }
}
