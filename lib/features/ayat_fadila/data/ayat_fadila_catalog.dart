import '../models/ayat_fadila_entry.dart';

/// Catalogue V1 — sélection éditoriale ANIS.
class AyatFadilaCatalog {
  AyatFadilaCatalog._();

  static const resumeEntryId = 'baqarah_end';

  static const entries = <AyatFadilaEntry>[
    AyatFadilaEntry(
      id: 'al_kursi',
      category: AyatFadilaCategory.protection,
      featured: true,
      openSurah: 2,
      openVerse: 255,
    ),
    AyatFadilaEntry(
      id: 'al_ikhlas',
      category: AyatFadilaCategory.praise,
      featured: true,
      openSurah: 112,
      openVerse: 1,
    ),
    AyatFadilaEntry(
      id: 'al_falaq_nas',
      category: AyatFadilaCategory.protection,
      featured: false,
      openSurah: 113,
      openVerse: 1,
    ),
    AyatFadilaEntry(
      id: 'baqarah_end',
      category: AyatFadilaCategory.daily,
      featured: true,
      openSurah: 2,
      openVerse: 285,
    ),
    AyatFadilaEntry(
      id: 'rabbana',
      category: AyatFadilaCategory.daily,
      featured: false,
      openSurah: 2,
      openVerse: 201,
    ),
    AyatFadilaEntry(
      id: 'mulk',
      category: AyatFadilaCategory.daily,
      featured: false,
      openSurah: 67,
      openVerse: 1,
    ),
    AyatFadilaEntry(
      id: 'hashr',
      category: AyatFadilaCategory.praise,
      featured: false,
      openSurah: 59,
      openVerse: 22,
    ),
    AyatFadilaEntry(
      id: 'salam',
      category: AyatFadilaCategory.daily,
      featured: false,
      openSurah: 36,
      openVerse: 58,
    ),
  ];

  static AyatFadilaEntry? byId(String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  static List<AyatFadilaEntry> get featuredEntries =>
      entries.where((e) => e.featured).toList(growable: false);

  static List<AyatFadilaEntry> forCategory(AyatFadilaCategory category) =>
      entries.where((e) => e.category == category).toList(growable: false);
}
