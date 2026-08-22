import 'package:flutter/material.dart';
import 'package:flutter_quran/flutter_quran.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/extensions/l10n_extensions.dart';
import '../core/constants/hizb_definitions.dart';
import '../core/models/bookmark.dart' as app_models;
import '../core/providers/auth_provider.dart';
import '../core/providers/bookmark_provider.dart';
import '../core/services/hizb_navigation_service.dart';
import '../core/widgets/mushaf_hizb_indicator.dart';
import '../core/widgets/mushaf_navigation_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';
import 'quran_search_screen.dart';

/// Écran Mushaf Warsh - Lecture par pages (même layout que Hafs, version Afrique du Nord)
/// Indicateur Hizb + signets pour pause/reprise
class MushafWarshScreen extends ConsumerStatefulWidget {
  const MushafWarshScreen({
    super.key,
    this.initialSurah,
    this.initialVerse,
    this.initialPage,
    this.initialHizb,
    this.hizbDefinitionId,
    this.resumePage,
  }) : assert(
          initialHizb == null || hizbDefinitionId != null,
          'Une ouverture par Hizb exige hizbDefinitionId',
        );

  final int? initialSurah;
  final int? initialVerse;
  final int? initialPage;
  final int? initialHizb;
  final String? hizbDefinitionId;

  /// Position enregistrée pour « Continuer ». Ignorée si elle ne tombe pas
  /// dans [initialHizb] : on ouvre alors le début canonique du Hizb.
  final int? resumePage;

  @override
  ConsumerState<MushafWarshScreen> createState() => _MushafWarshScreenState();
}

class _MushafWarshScreenState extends ConsumerState<MushafWarshScreen> {
  int _currentPage = 1;

  String get _effectiveDefinitionId =>
      widget.hizbDefinitionId ?? HizbDefinitions.quranFoundationHafsV1;

  int _getHeaderHizb() => widget.initialHizb == null
      ? HizbNavigationService.displayedHizb(_currentPage)
      : HizbNavigationService.displayedHizbForDefinition(
          _currentPage,
          definitionId: widget.hizbDefinitionId,
          reservedHizb: widget.initialHizb,
        );

  /// Vrai tant que la lecture n'a pas quitté le Hizb ouvert depuis la Khatma.
  bool get _insideReservedHizb =>
      widget.initialHizb == null ||
      HizbNavigationService.pageBelongsToHizbForDefinition(
        widget.initialHizb!,
        _currentPage,
        definitionId: widget.hizbDefinitionId,
      );

  void _returnToReservedHizb() {
    final hizb = widget.initialHizb;
    if (hizb == null) return;
    setState(
      () => _currentPage = HizbNavigationService.openStartForDefinition(
        hizb,
        definitionId: widget.hizbDefinitionId,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    FlutterQuran().init().catchError((Object e, StackTrace s) {
      debugPrint('[MushafWarsh] FlutterQuran().init() a échoué : $e');
    }).whenComplete(() {
      if (!mounted) return;
      final actualPage = FlutterQuran().getCurrentPageNumber();
      if (actualPage >= 1 && actualPage <= HizbNavigationService.totalPages) {
        setState(() => _currentPage = actualPage);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToInitial());
    });
  }

  void _navigateToInitial() {
    if (!mounted) return;
    final actualPage = FlutterQuran().getCurrentPageNumber();
    if (actualPage >= 1 && actualPage <= HizbNavigationService.totalPages) {
      setState(() => _currentPage = actualPage);
    }
    if (widget.initialHizb != null) {
      final hizb = widget.initialHizb!;
      final page = widget.resumePage != null
          ? HizbNavigationService.openResumeForDefinition(
              hizb,
              widget.resumePage,
              definitionId: widget.hizbDefinitionId,
            )
          : HizbNavigationService.openStartForDefinition(
              hizb,
              definitionId: widget.hizbDefinitionId,
            );
      setState(() => _currentPage = page);
    } else if (widget.initialPage != null) {
      FlutterQuran().navigateToPage(widget.initialPage!);
      setState(() => _currentPage = widget.initialPage!);
    } else if (widget.initialSurah != null) {
      FlutterQuran().navigateToSurah(widget.initialSurah!);
      if (widget.initialVerse != null) {
        try {
          final ayah = FlutterQuran().search('').firstWhere(
                (a) =>
                    a.surahNumber == widget.initialSurah &&
                    a.ayahNumber == widget.initialVerse,
              );
          FlutterQuran().navigateToAyah(ayah);
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hizb = _getHeaderHizb();
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final isPageBookmarked = bookmarksAsync.valueOrNull?.any(
          (b) => b.pageNumber == _currentPage,
        ) ??
        false;

    return Scaffold(
      body: FlutterQuranScreen(
        verseEndColor: Colors.blue,
        useLatinNumbers: true,
        useLatinNumbersForPage: true,
        rubElHizbColor: Colors.red,
        hizbFilterLayer: true,
        appBar: AppBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${l10n.mushafWarsh} - مصحف ورش',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              MushafHizbBadge(
                hizb: hizb,
                page: _currentPage,
                onTap: () => _showHizbPicker(context),
                reservedHizb: widget.initialHizb,
                insideReservedHizb: _insideReservedHizb,
                onReturnToHizb: _returnToReservedHizb,
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(
                isPageBookmarked ? Icons.bookmark : Icons.bookmark_add_outlined,
                color: isPageBookmarked ? AppTheme.accentGold : null,
              ),
              onPressed: () => _showBookmarkSheet(context),
              tooltip: l10n.mushafBookmarkHere,
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuranSearchScreen(),
                ),
              ),
              tooltip: 'Rechercher',
            ),
          ],
        ),
        onPageChanged: (index) {
          setState(() => _currentPage = index + 1);
        },
      ),
    );
  }

  void _showHizbPicker(BuildContext context) {
    MushafNavigationSheet.show(
      context,
      currentPage: _currentPage,
      currentHizb: _getHeaderHizb(),
      isWarsh: true,
      onNavigateToPage: (page) {
        FlutterQuran().navigateToPage(page);
        setState(() => _currentPage = page);
      },
      onNavigateToHizb: (hizb) {
        setState(
          () => _currentPage = HizbNavigationService.openStartForDefinition(
            hizb,
            definitionId: _effectiveDefinitionId,
          ),
        );
      },
      onNavigateToSurah: (surah) {
        FlutterQuran().navigateToSurah(surah);
        final newPage = FlutterQuran().getCurrentPageNumber();
        setState(() => _currentPage = newPage);
      },
    );
  }

  void _showBookmarkSheet(BuildContext context) {
    final l10n = context.l10n;
    final bookmarksAsync = ref.read(bookmarksProvider);
    final list = bookmarksAsync.valueOrNull ?? [];
    app_models.Bookmark? pageBookmark;
    for (final b in list) {
      if (b.pageNumber == _currentPage) {
        pageBookmark = b;
        break;
      }
    }
    final isPageBookmarked = pageBookmark != null;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    isPageBookmarked ? Icons.bookmark : Icons.bookmark_add_outlined,
                    color: isPageBookmarked ? AppTheme.accentGold : AppTheme.primaryGreen,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPageBookmarked ? l10n.mushafUnbookmark : l10n.mushafBookmarkHere,
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          l10n.mushafBookmarkHereDesc,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${mushafHizbLabel(ctx, _getHeaderHizb())}  ·  ${mushafPageLabel(ctx, _currentPage)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              if (isPageBookmarked && pageBookmark != null)
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final userId = ref.read(currentUserProvider)?.email ?? 'demo';
                    await ref
                        .read(bookmarkServiceProvider)
                        .removeBookmark(userId, pageBookmark!.id);
                    ref.invalidate(bookmarksProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${l10n.mushafUnbookmark} — ${l10n.mushafPage} $_currentPage'),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.bookmark_remove),
                  label: Text(l10n.mushafUnbookmark),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade700),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final userId = ref.read(currentUserProvider)?.email ?? 'demo';
                    await ref
                        .read(bookmarkServiceProvider)
                        .addPageBookmark(userId, _currentPage);
                    ref.invalidate(bookmarksProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${l10n.mushafBookmarkHere} — ${l10n.mushafPage} $_currentPage'),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.bookmark_add),
                  label: Text(l10n.mushafBookmarkHere),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
