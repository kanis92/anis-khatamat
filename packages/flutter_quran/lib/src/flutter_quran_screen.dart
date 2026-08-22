import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quran/flutter_quran.dart';
import 'package:flutter_quran/src/utils/string_extensions.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'app_bloc.dart';
import 'controllers/bookmarks_controller.dart';
import 'controllers/quran_controller.dart';
import 'models/quran_constants.dart';
import 'models/quran_page.dart';
part 'utils/images.dart';
part 'utils/toast_utils.dart';
part 'widgets/bsmallah_widget.dart';
part 'widgets/quran_line.dart';
part 'widgets/quran_page_bottom_info.dart';
part 'widgets/surah_header_widget.dart';
part 'widgets/default_drawer.dart';
part 'widgets/ayah_long_click_dialog.dart';

class FlutterQuranScreen extends StatelessWidget {
  const FlutterQuranScreen(
      {this.showBottomWidget = true,
      this.useDefaultAppBar = true,
      this.bottomWidget,
      this.appBar,
      this.onPageChanged,
      this.verseEndColor,
      this.useLatinNumbers = false,
      this.useLatinNumbersForPage = false,
      this.rubElHizbColor,
      this.hizbFilterLayer = false,
      super.key});

  ///[showBottomWidget] is a bool to disable or enable the default bottom widget
  final bool showBottomWidget;

  ///[showBottomWidget] is a bool to disable or enable the default bottom widget
  final bool useDefaultAppBar;

  ///[bottomWidget] if if provided it will replace the default bottom widget
  final Widget? bottomWidget;

  ///[appBar] if if provided it will replace the default app bar
  final PreferredSizeWidget? appBar;

  ///[onPageChanged] if provided it will be called when a quran page changed
  final Function(int)? onPageChanged;

  /// Couleur du symbole de fin de verset (rosette/numéro). Par défaut rouge.
  final Color? verseEndColor;

  /// Afficher les numéros de verset en chiffres latins (0-9) au lieu des arabes (٠-٩)
  final bool useLatinNumbers;

  /// Afficher les numéros de page en chiffres latins
  final bool useLatinNumbersForPage;

  /// Couleur du symbole Rub El Hizb (۞) à la transition des hizb. Par défaut orange vif.
  final Color? rubElHizbColor;

  /// Couche filtre noir (opacité très légère) sur les versets avant et après le symbole ۞.
  /// true = activer la couche (noir ~3% opacité).
  final bool hizbFilterLayer;

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    Orientation currentOrientation = MediaQuery.of(context).orientation;
    return MultiBlocProvider(
      providers: AppBloc.providers,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: appBar ?? (useDefaultAppBar ? AppBar(elevation: 0) : null),
          drawer: appBar == null && useDefaultAppBar
              ? const _DefaultDrawer()
              : null,
          body: BlocBuilder<QuranCubit, List<QuranPage>>(
            builder: (ctx, pages) {
              return pages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : SafeArea(
                      child: PageView.builder(
                        itemCount: pages.length,
                        controller: AppBloc.quranCubit.pageController,
                        onPageChanged: (page) {
                          if (onPageChanged != null) onPageChanged!(page);
                          AppBloc.quranCubit.saveLastPage(page + 1);
                        },
                        pageSnapping: true,
                        itemBuilder: (ctx, index) {
                          List<String> newSurahs = [];
                          return Container(
                              height: deviceSize.height * 0.92,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 8.0),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: index == 0 || index == 1

                                        /// This is for first 2 pages of Quran: Al-Fatihah and Al-Baqarah
                                        ? Center(
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SurahHeaderWidget(pages[index]
                                                      .ayahs[0]
                                                      .surahNameAr),
                                                  if (index == 1)
                                                    const BasmallahWidget(),
                                                  ...pages[index]
                                                      .lines
                                                      .map((line) {
                                                    return BlocBuilder<
                                                        BookmarksCubit,
                                                        List<Bookmark>>(
                                                      builder:
                                                          (context, bookmarks) {
                                                        final bookmarksAyahs =
                                                            bookmarks
                                                                .map((bookmark) =>
                                                                    bookmark
                                                                        .ayahId)
                                                                .toList();
                                                        return Column(
                                                          children: [
                                                            SizedBox(
                                                                width: deviceSize
                                                                        .width -
                                                                    32,
                                                                child:
                                                                    QuranLine(
                                                                  line,
                                                                  bookmarksAyahs,
                                                                  bookmarks,
                                                                  boxFit: BoxFit
                                                                      .scaleDown,
                                                                  verseEndColor: verseEndColor,
                                                                  useLatinNumbers: useLatinNumbers,
                                                                  rubElHizbColor: rubElHizbColor,
                                                                  pageHizb: pages[index].hizb,
                                                                  hizbFilterLayer: hizbFilterLayer,
                                                                )),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  }),
                                                ],
                                              ),
                                            ),
                                          )

                                        /// Other Quran pages
                                        : LayoutBuilder(
                                            builder: (context, constraints) {
                                            return ListView(
                                                physics: currentOrientation ==
                                                        Orientation.portrait
                                                    ? const NeverScrollableScrollPhysics()
                                                    : null,
                                                children: [
                                                  ...pages[index]
                                                      .lines
                                                      .map((line) {
                                                    bool firstAyah = false;
                                                    if (line.ayahs[0]
                                                                .ayahNumber ==
                                                            1 &&
                                                        !newSurahs.contains(line
                                                            .ayahs[0]
                                                            .surahNameAr)) {
                                                      newSurahs.add(line
                                                          .ayahs[0]
                                                          .surahNameAr);
                                                      firstAyah = true;
                                                    }
                                                    return BlocBuilder<
                                                        BookmarksCubit,
                                                        List<Bookmark>>(
                                                      builder:
                                                          (context, bookmarks) {
                                                        final bookmarksAyahs =
                                                            bookmarks
                                                                .map((bookmark) =>
                                                                    bookmark
                                                                        .ayahId)
                                                                .toList();
                                                        return Column(
                                                          children: [
                                                            if (firstAyah)
                                                              SurahHeaderWidget(line
                                                                  .ayahs[0]
                                                                  .surahNameAr),
                                                            if (firstAyah &&
                                                                (line.ayahs[0]
                                                                        .surahNumber !=
                                                                    9))
                                                              const BasmallahWidget(),
                                                            SizedBox(
                                                              width: deviceSize
                                                                      .width -
                                                                  30,
                                                              height: ((currentOrientation ==
                                                                              Orientation
                                                                                  .portrait
                                                                          ? constraints
                                                                              .maxHeight
                                                                          : deviceSize
                                                                              .width) -
                                                                      (pages[index]
                                                                              .numberOfNewSurahs *
                                                                          (line.ayahs[0].surahNumber != 9
                                                                              ? 110
                                                                              : 80))) *
                                                                  0.95 /
                                                                  pages[index]
                                                                      .lines
                                                                      .length,
                                                              child: QuranLine(
                                                                line,
                                                                bookmarksAyahs,
                                                                bookmarks,
                                                                boxFit: BoxFit
                                                                    .scaleDown,
                                                                verseEndColor: verseEndColor,
                                                                useLatinNumbers: useLatinNumbers,
                                                                rubElHizbColor: rubElHizbColor,
                                                                pageHizb: pages[index].hizb,
                                                                hizbFilterLayer: hizbFilterLayer,
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  }),
                                                ]);
                                          }),
                                  ),
                                  bottomWidget ??
                                      (showBottomWidget
                                          ? QuranPageBottomInfoWidget(
                                              page: index + 1,
                                              hizb: pages[index].hizb,
                                              surahName: pages[index]
                                                  .ayahs
                                                  .last
                                                  .surahNameAr,
                                              useLatinNumbers: useLatinNumbersForPage)
                                          : Container()),
                                ],
                              ));
                        },
                      ),
                    );
            },
          ),
        ),
      ),
    );
  }
}

class _FlutterQuranSearchScreen extends StatefulWidget {
  const _FlutterQuranSearchScreen();

  @override
  State<_FlutterQuranSearchScreen> createState() =>
      _FlutterQuranSearchScreenState();
}

class _FlutterQuranSearchScreenState extends State<_FlutterQuranSearchScreen> {
  List<Ayah> ayahs = [];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بحث'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                TextField(
                  onChanged: (txt) {
                    final searchResult = FlutterQuran().search(txt);
                    setState(() {
                      ayahs = [...searchResult];
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    hintText: 'بحث',
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: ayahs
                        .map((ayah) => Column(
                              children: [
                                ListTile(
                                  title: Text(
                                    ayah.ayah.replaceAll('\n', ' '),
                                  ),
                                  subtitle: Text(ayah.surahNameAr),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    FlutterQuran().navigateToAyah(ayah);
                                  },
                                ),
                                const Divider(
                                  color: Colors.grey,
                                  thickness: 1,
                                ),
                              ],
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
