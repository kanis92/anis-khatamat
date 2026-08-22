import 'package:flutter_bloc/flutter_bloc.dart';

import 'controllers/bookmarks_controller.dart';
import 'controllers/quran_controller.dart';

/// Cubits partagés pour toute la session Mushaf.
///
/// Propriété : singleton applicatif — [BlocProvider.value] dans
/// [FlutterQuranScreen] ne doit jamais fermer ces instances.
class AppBloc {
  static QuranCubit _quranCubit = QuranCubit();
  static BookmarksCubit _bookmarksCubit = BookmarksCubit();

  /// Cubits de session, recréés uniquement après un reset explicite de test.
  static QuranCubit get quranCubit => ensureQuranCubit();
  static BookmarksCubit get bookmarksCubit => ensureBookmarksCubit();

  static QuranCubit ensureQuranCubit() {
    if (_quranCubit.isClosed) _quranCubit = QuranCubit();
    return _quranCubit;
  }

  static BookmarksCubit ensureBookmarksCubit() {
    if (_bookmarksCubit.isClosed) _bookmarksCubit = BookmarksCubit();
    return _bookmarksCubit;
  }

  static List<BlocProvider> get providers => [
        BlocProvider<QuranCubit>.value(value: ensureQuranCubit()),
        BlocProvider<BookmarksCubit>.value(value: ensureBookmarksCubit()),
      ];

  /// Réinitialisation réservée aux tests.
  ///
  /// Les Cubits appartiennent à la session applicative : aucun écran Mushaf ne
  /// les ferme. Le reset attend leur travail asynchrone avant de remplacer les
  /// instances, ce qui reproduit proprement une fin de session.
  static Future<void> resetForTesting() async {
    await Future.wait([
      if (!_quranCubit.isClosed) _quranCubit.close(),
      if (!_bookmarksCubit.isClosed) _bookmarksCubit.close(),
    ]);
    _quranCubit = QuranCubit();
    _bookmarksCubit = BookmarksCubit();
  }

  static final AppBloc _instance = AppBloc._internal();
  factory AppBloc() => _instance;
  AppBloc._internal();
}
