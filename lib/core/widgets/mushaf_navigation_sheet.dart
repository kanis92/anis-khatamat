import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/mushaf_maghrebi_data.dart';
import '../data/quran_subdivision_data.dart';
import '../repositories/hizb_index_repository.dart';
import '../services/hizb_navigation_service.dart';
import '../theme/app_theme.dart';

/// Bottom sheet de navigation Mushaf avec onglets :
/// الأحزاب (Ahzab) | السور (Surahs) | الصفحات (Pages) | بحث (Search)
///
/// Inspiré du المصحف المحمدي avec subdivisions حزب / نصف / ربع / ثمن
class MushafNavigationSheet extends StatefulWidget {
  final int currentPage;
  final int currentHizb;
  final bool isWarsh;
  final void Function(int page) onNavigateToPage;
  final void Function(int hizb) onNavigateToHizb;
  final void Function(int surah) onNavigateToSurah;
  /// Si fourni, remplace les pages de QuranSubdivisionData (ex: Mushaf Marocain 623p)
  final Map<int, int>? hizbPageMap;
  final int? totalPages;

  const MushafNavigationSheet({
    super.key,
    required this.currentPage,
    required this.currentHizb,
    this.isWarsh = false,
    required this.onNavigateToPage,
    required this.onNavigateToHizb,
    required this.onNavigateToSurah,
    this.hizbPageMap,
    this.totalPages,
  });

  static void show(
    BuildContext context, {
    required int currentPage,
    required int currentHizb,
    bool isWarsh = false,
    required void Function(int page) onNavigateToPage,
    required void Function(int hizb) onNavigateToHizb,
    required void Function(int surah) onNavigateToSurah,
    Map<int, int>? hizbPageMap,
    int? totalPages,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: MushafNavigationSheet(
            currentPage: currentPage,
            currentHizb: currentHizb,
            isWarsh: isWarsh,
            onNavigateToPage: onNavigateToPage,
            onNavigateToHizb: onNavigateToHizb,
            onNavigateToSurah: onNavigateToSurah,
            hizbPageMap: hizbPageMap,
            totalPages: totalPages,
          ),
        ),
      ),
    );
  }

  @override
  State<MushafNavigationSheet> createState() => _MushafNavigationSheetState();
}

class _MushafNavigationSheetState extends State<MushafNavigationSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Directionality(
          textDirection: TextDirection.rtl,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: Colors.grey[500],
            indicatorColor: AppTheme.primaryGreen,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'الأحزاب'),
              Tab(text: 'السور'),
              Tab(text: 'الصفحات'),
              Tab(text: 'بحث'),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey[isDark ? 700 : 200]),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: TabBarView(
              controller: _tabController,
              children: [
                _AhzabTab(
                  currentHizb: widget.currentHizb,
                  isWarsh: widget.isWarsh,
                  onNavigateToPage: widget.onNavigateToPage,
                  onNavigateToHizb: widget.onNavigateToHizb,
                  hizbPageMap: widget.hizbPageMap,
                ),
                _SurahTab(
                  currentPage: widget.currentPage,
                  onNavigateToSurah: widget.onNavigateToSurah,
                ),
                _PagesTab(
                  currentPage: widget.currentPage,
                  onNavigateToPage: widget.onNavigateToPage,
                  totalPages: widget.totalPages,
                ),
                _SearchTab(
                  onNavigateToPage: widget.onNavigateToPage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Onglet الأحزاب — Navigation par Hizb avec subdivisions ربع / نصف
class _AhzabTab extends StatefulWidget {
  final int currentHizb;
  final bool isWarsh;
  final void Function(int page) onNavigateToPage;
  /// Callback principal : navigue vers le Hizb par son numéro (source unique).
  final void Function(int hizbNumber) onNavigateToHizb;
  final Map<int, int>? hizbPageMap;

  const _AhzabTab({
    required this.currentHizb,
    required this.isWarsh,
    required this.onNavigateToPage,
    required this.onNavigateToHizb,
    this.hizbPageMap,
  });

  @override
  State<_AhzabTab> createState() => _AhzabTabState();
}

class _AhzabTabState extends State<_AhzabTab> {
  final _searchController = TextEditingController();
  int? _filterHizb;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            textDirection: TextDirection.rtl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'رقم الحزب',
              hintStyle: GoogleFonts.cairo(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey[50],
            ),
            onChanged: (v) {
              final n = int.tryParse(v);
              setState(() => _filterHizb = (n != null && n >= 1 && n <= 60) ? n : null);
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _filterHizb != null ? 1 : 60,
            itemBuilder: (context, index) {
              final hizbNum = _filterHizb ?? (index + 1);

              // Si une map custom est fournie (ex: Mushaf Marocain), l'utiliser directement.
              // Dans ce cas on navigue par page (MushafMaghrebiData est cohérent en interne).
              if (widget.hizbPageMap != null) {
                final page = widget.hizbPageMap![hizbNum] ?? 1;
                final isCurrent = widget.currentHizb == hizbNum;
                return _HizbListItemSimple(
                  hizbNumber: hizbNum,
                  page: page,
                  isCurrent: isCurrent,
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onNavigateToPage(page);
                  },
                );
              }

              // Source unique : HizbIndexRepository
              // incipit + page + surah:ayah sont tous issus de la même source.
              final ref = HizbIndexRepository.getByNumber(hizbNum);
              // Hafs, Warsh et Femmes rendent le même Mushaf 604 pages :
              // afficher pageWarsh ici annoncerait une page que le lecteur
              // n'atteindra jamais.
              final page = HizbNavigationService.startPage(hizbNum);
              final isCurrent = widget.currentHizb == hizbNum;

              // Les subdivisions (ربع / نصف) restent dans QuranSubdivisionData
              // (données de pages uniquement, pas d'incipit).
              final quarters = QuranSubdivisionData.getQuartersForHizb(hizbNum);

              return _HizbListItem(
                hizbNumber: hizbNum,
                page: page,
                incipitAr: ref.incipitAr,
                isCurrent: isCurrent,
                quarters: quarters,
                onTapHizb: () {
                  Navigator.of(context).pop();
                  widget.onNavigateToHizb(hizbNum);
                },
                onTapSubdivision: (p) {
                  Navigator.of(context).pop();
                  widget.onNavigateToPage(p);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Un élément de la liste des Ahzab avec subdivisions expandables
/// Élément de liste Hizb avec incipit arabe (pour Mushaf Marocain)
class _HizbListItemSimple extends StatelessWidget {
  final int hizbNumber;
  final int page;
  final bool isCurrent;
  final VoidCallback onTap;

  const _HizbListItemSimple({
    required this.hizbNumber,
    required this.page,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = MushafMaghrebiData.getHizb(hizbNumber);
    final juz = data?.juz ?? ((hizbNumber - 1) ~/ 2) + 1;
    final incipit = data?.incipitAr ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      elevation: isCurrent ? 2 : 0.5,
      color: isCurrent
          ? AppTheme.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.06)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent
            ? BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.4), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Numéro du Hizb dans un cercle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppTheme.primaryGreen
                      : AppTheme.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$hizbNumber',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isCurrent ? Colors.white : AppTheme.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Incipit + métadonnées
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Incipit arabe — police Amiri pour le style Mushaf
                    if (incipit.isNotEmpty)
                      Text(
                        incipit,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isCurrent
                              ? AppTheme.primaryGreen
                              : (isDark ? Colors.white : Colors.black87),
                          height: 1.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    // Métadonnées : Juz + Page
                    Row(
                      children: [
                        Text(
                          'الحزب $hizbNumber',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isCurrent
                                ? AppTheme.primaryGreen.withValues(alpha: 0.8)
                                : Colors.grey[500],
                          ),
                        ),
                        Text(
                          '  •  ',
                          style: TextStyle(color: Colors.grey[400], fontSize: 11),
                        ),
                        Text(
                          'الجزء $juz',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          '  •  ',
                          style: TextStyle(color: Colors.grey[400], fontSize: 11),
                        ),
                        Text(
                          'ص $page',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Indicateur courant + flèche
              if (isCurrent)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                )
              else
                Icon(Icons.arrow_back_ios, size: 13, color: Colors.grey[350]),
            ],
          ),
        ),
      ),
    );
  }
}

class _HizbListItem extends StatelessWidget {
  final int hizbNumber;
  final int page;
  /// Incipit issu de HizbIndexRepository — cohérent avec la cible de navigation.
  final String incipitAr;
  final bool isCurrent;
  final List<HizbMarker> quarters;
  /// Navigue vers le Hizb complet (utilise onNavigateToHizb).
  final VoidCallback onTapHizb;
  /// Navigue vers une subdivision par numéro de page.
  final void Function(int page) onTapSubdivision;

  const _HizbListItem({
    required this.hizbNumber,
    required this.page,
    required this.incipitAr,
    required this.isCurrent,
    required this.quarters,
    required this.onTapHizb,
    required this.onTapSubdivision,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Fallback: si incipitAr est vide, utiliser le Mushaf Marocain (Hafs seulement).
    final incipit = incipitAr.isNotEmpty
        ? incipitAr
        : (MushafMaghrebiData.getHizb(hizbNumber)?.incipitAr ?? '');
    final juz = ((hizbNumber - 1) ~/ 2) + 1;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      elevation: isCurrent ? 2 : 0.5,
      color: isCurrent
          ? AppTheme.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.06)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent
            ? BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.4), width: 1.5)
            : BorderSide.none,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: _HizbBadge(number: hizbNumber, isCurrent: isCurrent),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (incipit.isNotEmpty)
                Text(
                  incipit,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.amiri(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isCurrent
                        ? AppTheme.primaryGreen
                        : (isDark ? Colors.white : Colors.black87),
                    height: 1.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'الحزب $hizbNumber',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isCurrent
                          ? AppTheme.primaryGreen.withValues(alpha: 0.8)
                          : Colors.grey[500],
                    ),
                  ),
                  Text('  •  ', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                  Text(
                    'الجزء $juz',
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[500]),
                  ),
                  Text('  •  ', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                  Text(
                    'ص $page',
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
          trailing: InkWell(
            onTap: onTapHizb,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ذهاب',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ),
          children: quarters.skip(1).map((q) {
            // Même pagination que le lecteur (Hafs 604 p.), y compris en Warsh.
            return _SubdivisionRow(
              marker: q,
              page: q.pageHafs,
              onTap: () => onTapSubdivision(q.pageHafs),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Badge décoratif du numéro de Hizb (style المصحف المحمدي)
class _HizbBadge extends StatelessWidget {
  final int number;
  final bool isCurrent;

  const _HizbBadge({required this.number, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent ? AppTheme.primaryGreen : AppTheme.accentGold,
          width: 2,
        ),
        color: isCurrent
            ? AppTheme.primaryGreen.withValues(alpha: 0.1)
            : AppTheme.accentGold.withValues(alpha: 0.08),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: GoogleFonts.cairo(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: isCurrent ? AppTheme.primaryGreen : AppTheme.accentGold,
        ),
      ),
    );
  }
}

/// Ligne de subdivision (ربع / نصف / ثلاثة أرباع)
class _SubdivisionRow extends StatelessWidget {
  final HizbMarker marker;
  final int page;
  final VoidCallback onTap;

  const _SubdivisionRow({
    required this.marker,
    required this.page,
    required this.onTap,
  });

  Color get _markerColor {
    switch (marker.type) {
      case HizbMarkerType.nisf:
        return Colors.red.shade700;
      case HizbMarkerType.rub:
        return Colors.blue.shade700;
      default:
        return AppTheme.primaryGreen;
    }
  }

  String get _markerIcon {
    switch (marker.type) {
      case HizbMarkerType.nisf:
        return 'نصف';
      case HizbMarkerType.rub:
        return marker.subdivisionIndex == 2 ? 'ربع' : '٣/٤';
      default:
        return 'حزب';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 24,
              decoration: BoxDecoration(
                color: _markerColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _markerColor.withValues(alpha: 0.3),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _markerIcon,
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _markerColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                marker.arabicLabel,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              'ص $page',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

/// Onglet السور — Navigation par Sourate
class _SurahTab extends StatelessWidget {
  final int currentPage;
  final void Function(int surah) onNavigateToSurah;

  const _SurahTab({
    required this.currentPage,
    required this.onNavigateToSurah,
  });

  @override
  Widget build(BuildContext context) {
    final surahs = QuranSubdivisionData.surahList;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: surahs.length,
      itemBuilder: (context, index) {
        final s = surahs[index];
        final number = s['number'] as int;
        final name = s['name'] as String;
        final nameFr = s['nameFr'] as String;
        final verses = s['verses'] as int;
        final page = s['pageHafs'] as int;
        final isCurrent = currentPage >= page &&
            (index == surahs.length - 1 ||
                currentPage < (surahs[index + 1]['pageHafs'] as int));

        return ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent
                  ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.08),
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isCurrent ? AppTheme.primaryGreen : Colors.grey[600],
              ),
            ),
          ),
          title: Text(
            name,
            style: GoogleFonts.amiri(
              fontSize: 20,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? AppTheme.primaryGreen : null,
            ),
          ),
          subtitle: Text(
            '$nameFr  •  $verses آيات  •  ص $page',
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
          trailing: isCurrent
              ? Icon(Icons.play_arrow, color: AppTheme.primaryGreen, size: 20)
              : null,
          onTap: () {
            Navigator.of(context).pop();
            onNavigateToSurah(number);
          },
        );
      },
    );
  }
}

/// Onglet الصفحات — Navigation par numéro de page
class _PagesTab extends StatefulWidget {
  final int currentPage;
  final void Function(int page) onNavigateToPage;
  final int? totalPages;

  const _PagesTab({
    required this.currentPage,
    required this.onNavigateToPage,
    this.totalPages,
  });

  @override
  State<_PagesTab> createState() => _PagesTabState();
}

class _PagesTabState extends State<_PagesTab> {
  late double _sliderValue;
  final _pageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.currentPage.toDouble();
    _pageController.text = '${widget.currentPage}';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'الصفحة ${_sliderValue.round()}',
            style: GoogleFonts.cairo(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'من ${widget.totalPages ?? 604} صفحة',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          Directionality(
            textDirection: TextDirection.ltr,
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.primaryGreen,
                thumbColor: AppTheme.primaryGreen,
                inactiveTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                overlayColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              ),
              child: Slider(
                value: _sliderValue.clamp(1, (widget.totalPages ?? 604).toDouble()),
                min: 1,
                max: (widget.totalPages ?? 604).toDouble(),
                divisions: (widget.totalPages ?? 604) - 1,
                label: '${_sliderValue.round()}',
                onChanged: (v) => setState(() {
                  _sliderValue = v;
                  _pageController.text = '${v.round()}';
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pageController,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'رقم الصفحة',
                    hintStyle: GoogleFonts.cairo(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (v) {
                    final page = int.tryParse(v);
                    final max = widget.totalPages ?? 604;
                    if (page != null && page >= 1 && page <= max) {
                      setState(() => _sliderValue = page.toDouble());
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onNavigateToPage(_sliderValue.round());
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: Text(
                  'ذهاب',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Builder(builder: (context) {
            final max = widget.totalPages ?? 604;
            final shortcuts = [1, 50, 100, 200, 300, 400, 500, max]
                .where((p) => p <= max)
                .toSet()
                .toList()
              ..sort();
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: shortcuts.map((p) {
                return ActionChip(
                  label: Text(
                    '$p',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _sliderValue = p.toDouble();
                      _pageController.text = '$p';
                    });
                  },
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

/// Onglet بحث — Recherche rapide par Juz
class _SearchTab extends StatelessWidget {
  final void Function(int page) onNavigateToPage;

  const _SearchTab({required this.onNavigateToPage});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'الأجزاء',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1.3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 30,
            itemBuilder: (context, index) {
              final juz = index + 1;
              // Un Juz commence au Hizb impair correspondant (Juz N = Hizb 2N-1),
              // pas à une fraction fixe des 604 pages : les Hizb sont inégaux.
              final page = HizbNavigationService.startPage(juz * 2 - 1);
              return InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  onNavigateToPage(page);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentGold.withValues(alpha: 0.3),
                    ),
                    color: AppTheme.accentGold.withValues(alpha: 0.05),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$juz',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentGold,
                        ),
                      ),
                      Text(
                        'جزء',
                        style: GoogleFonts.cairo(
                          fontSize: 9,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'أماكن مميزة',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _QuickLink(
            label: 'سورة الكهف',
            page: 293,
            icon: Icons.auto_stories,
            onTap: () {
              Navigator.of(context).pop();
              onNavigateToPage(293);
            },
          ),
          _QuickLink(
            label: 'سورة يس',
            page: 440,
            icon: Icons.favorite_outline,
            onTap: () {
              Navigator.of(context).pop();
              onNavigateToPage(440);
            },
          ),
          _QuickLink(
            label: 'سورة الرحمن',
            page: 531,
            icon: Icons.star_outline,
            onTap: () {
              Navigator.of(context).pop();
              onNavigateToPage(531);
            },
          ),
          _QuickLink(
            label: 'سورة الملك',
            page: 562,
            icon: Icons.shield_outlined,
            onTap: () {
              Navigator.of(context).pop();
              onNavigateToPage(562);
            },
          ),
          _QuickLink(
            label: 'جزء عمّ',
            page: 582,
            icon: Icons.bookmark_outline,
            onTap: () {
              Navigator.of(context).pop();
              onNavigateToPage(582);
            },
          ),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final String label;
  final int page;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickLink({
    required this.label,
    required this.page,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryGreen),
        title: Text(
          label,
          style: GoogleFonts.amiri(fontSize: 18),
        ),
        subtitle: Text(
          'ص $page',
          style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[500]),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}
