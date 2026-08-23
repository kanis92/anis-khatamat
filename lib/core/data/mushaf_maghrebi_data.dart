/// Données exactes du Mushaf Marocain (خط مغربي — ورش عن نافع)
/// Source : mushaf.ma — 623 pages
/// Mapping complet : Hizb → Page + Incipit (premiers mots du Hizb)
class MushafMaghrebiData {
  MushafMaghrebiData._();

  static const int totalPages = 623;

  /// Données complètes de chaque Hizb
  static const List<MaghrebiHizb> ahzab = [
    MaghrebiHizb(1,  1,   'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ'),
    MaghrebiHizb(2,  13,  'وَإِذَا لَقُوا ٱلَّذِينَ ءَامَنُوا'),
    MaghrebiHizb(3,  22,  'سَيَقُولُ ٱلسُّفَهَاءُ مِنَ ٱلنَّاسِ'),
    MaghrebiHizb(4,  32,  'وَٱذْكُرُوا ٱللَّهَ فِىٓ أَيَّامٍ'),
    MaghrebiHizb(5,  41,  'تِلْكَ ٱلرُّسُلُ فَضَّلْنَا بَعْضَهُمْ'),
    MaghrebiHizb(6,  51,  'قُلْ أُؤُنَبِّئُكُم بِخَيْرٍ مِّن'),
    MaghrebiHizb(7,  61,  'لَن تَنَالُوا ٱلْبِرَّ حَتَّىٰ'),
    MaghrebiHizb(8,  71,  'يَسْتَبْشِرُونَ بِنِعْمَةٍ مِّنَ ٱللَّهِ'),
    MaghrebiHizb(9,  80,  'وَٱلْمُحْصَنَٰتُ مِنَ ٱلنِّسَآءِ إِلَّا'),
    MaghrebiHizb(10, 90,  'ٱللَّهُ لَآ إِلَٰهَ إِلَّا'),
    MaghrebiHizb(11, 100, 'لَّا يُحِبُّ ٱللَّهُ ٱلْجَهْرَ'),
    MaghrebiHizb(12, 110, 'قَالَ رَجُلَانِ مِنَ ٱلَّذِينَ'),
    MaghrebiHizb(13, 120, 'لَتَجِدَنَّ أَشَدَّ ٱلنَّاسِ عَدَٰوَةً'),
    MaghrebiHizb(14, 131, 'إِنَّمَا يَسْتَجِيبُ ٱلَّذِينَ يَسْمَعُونَ'),
    MaghrebiHizb(15, 142, 'وَلَوْ أَنَّنَا نَزَّلْنَآ إِلَيْهِمْ'),
    MaghrebiHizb(16, 151, 'فَمَا كَانَ دَعْوَىٰهُمْ إِذْ'),
    MaghrebiHizb(17, 162, 'قَالَ ٱلْمَلَأُ ٱلَّذِينَ ٱسْتَكْبَرُوا'),
    MaghrebiHizb(18, 173, 'وَإِلَىٰ ثَمُودَ أَخَاهُمْ صَٰلِحًا'),
    MaghrebiHizb(19, 182, 'وَٱعْلَمُوٓا أَنَّمَا غَنِمْتُم مِّن'),
    MaghrebiHizb(20, 193, 'يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓا إِنْ'),
    MaghrebiHizb(21, 202, 'إِنَّمَا ٱلسَّبِيلُ عَلَى ٱلَّذِينَ'),
    MaghrebiHizb(22, 212, 'لِّلَّذِينَ أَحْسَنُوا ٱلْحُسْنَىٰ وَزِيَادَةٌ'),
    MaghrebiHizb(23, 223, 'وَمَا مِن دَآبَّةٍ فِى'),
    MaghrebiHizb(24, 232, 'وَٱلَّذِينَ ءَامَنُوا لَمْ يُهَاجِرُوا شَيْـًٔا'),
    MaghrebiHizb(25, 243, 'وَمَآ أُبَرِّئُ نَفْسِىٓ إِنَّ'),
    MaghrebiHizb(26, 254, 'أَفَمَن يَعْلَمُ أَنَّمَآ أُنزِلَ'),
    MaghrebiHizb(27, 264, 'أَفَمِنْ هَٰذَا ٱلْحَدِيثِ تَعْجَبُونَ'),
    MaghrebiHizb(28, 275, 'وَقَالَ ٱللَّهُ لَا تَتَّخِذُوا'),
    MaghrebiHizb(29, 285, 'سَيَجْعَلُ لَهُمُ ٱلرَّحْمَٰنُ وُدًّا'),
    MaghrebiHizb(30, 296, 'أَلَمْ تَرَوْا أَنَّ ٱللَّهَ'),
    MaghrebiHizb(31, 306, 'قَالَ أَلَمْ أَقُل لَّكَ'),
    MaghrebiHizb(32, 318, 'طه مَآ أَنزَلْنَا عَلَيْكَ'),
    MaghrebiHizb(33, 328, 'ٱقْتَرَبَ لِلنَّاسِ حِسَابُهُمْ وَهُمْ'),
    MaghrebiHizb(34, 338, 'يَٰٓأَيُّهَا ٱلنَّاسُ ٱتَّقُوا رَبَّكُمْ'),
    MaghrebiHizb(35, 348, 'قَدْ أَفْلَحَ ٱلْمُؤْمِنُونَ'),
    MaghrebiHizb(36, 359, 'يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوا لَا'),
    MaghrebiHizb(37, 370, 'وَقَالَ ٱلَّذِينَ لَا يَرْجُونَ'),
    MaghrebiHizb(38, 380, 'قَالُوٓا أُوذِينَا مِن قَبْلِ أَن'),
    MaghrebiHizb(39, 391, 'فَمَا كَانَ جَوَابَ قَوْمِهِ'),
    MaghrebiHizb(40, 401, 'وَلَقَدْ وَصَّلْنَا لَهُمُ ٱلْقَوْلَ'),
    MaghrebiHizb(41, 411, 'وَلَا تُجَادِلُوٓا أَهْلَ ٱلْكِتَٰبِ'),
    MaghrebiHizb(42, 423, 'وَمَن يُسْلِمْ وَجْهَهُۥٓ إِلَى ٱللَّهِ'),
    MaghrebiHizb(43, 433, 'وَمَن يَقْنُتْ مِنكُنَّ لِلَّهِ'),
    MaghrebiHizb(44, 442, 'قُلْ مَن يَرْزُقُكُم مِّنَ'),
    MaghrebiHizb(45, 454, 'وَمَآ أَنزَلْنَا عَلَىٰ قَوْمِهِ'),
    MaghrebiHizb(46, 464, 'فَتَعَٰلَى ٱللَّهُ ٱلْمَلِكُ ٱلْحَقُّ'),
    MaghrebiHizb(47, 476, 'فَمِنْهُم مَّن رَّكِبَ'),
    MaghrebiHizb(48, 486, 'وَيَقُولُونَ مَا لِهَٰذَا ٱلرَّسُولِ'),
    MaghrebiHizb(49, 496, 'إِلَيْهِ يُرَدُّ عِلْمُ ٱلْسَّاعَةِ'),
    MaghrebiHizb(50, 506, 'قُلْ أَوَلَوْ جِئْتُكُم بِأَهْدَىٰ'),
    MaghrebiHizb(51, 518, 'حم تَنزِيلُ ٱلْكِتَٰبِ مِن'),
    MaghrebiHizb(52, 530, 'لَقَدْ رَضِىَ ٱللَّهُ عَن'),
    MaghrebiHizb(53, 540, 'قَالَ فَمَا خَطْبُكُمْ أَيُّهَا'),
    MaghrebiHizb(54, 551, 'ٱلرَّحْمَٰنُ عَلَّمَ ٱلْقُرْءَانَ خَلَقَ'),
    MaghrebiHizb(55, 563, 'قَدْ سَمِعَ ٱللَّهُ قَوْلَ'),
    MaghrebiHizb(56, 575, 'يَسْمَعُ ٱللَّهُ مَا فِى'),
    MaghrebiHizb(57, 585, 'تَبَارَكَ ٱلَّذِى بِيَدِهِ ٱلْمُلْكُ'),
    MaghrebiHizb(58, 598, 'قُلْ أُوحِىَ إِلَىَّ أَنَّهُ'),
    MaghrebiHizb(59, 610, 'عَمَّ يَتَسَآءَلُونَ عَنِ ٱلنَّبَإِ'),
    MaghrebiHizb(60, 623, 'سَبِّحِ ٱسْمَ رَبِّكَ ٱلْأَعْلَىٰ'),
  ];

  /// Map Hizb → Page (pour la navigation rapide)
  static final Map<int, int> hizbToPage = {
    for (final h in ahzab) h.hizb: h.page,
  };

  /// Retourne la page du Mushaf Marocain pour un Hizb donné
  static int pageForHizb(int hizb) => hizbToPage[hizb.clamp(1, 60)] ?? 1;

  /// Retourne le numéro de Hizb pour une page donnée
  static int hizbForPage(int page) {
    int result = 1;
    for (final h in ahzab) {
      if (h.page <= page) {
        result = h.hizb;
      } else {
        break;
      }
    }
    return result;
  }

  /// Retourne le numéro de Juz (1..30) pour un Hizb
  static int juzForHizb(int hizb) => ((hizb - 1) ~/ 2) + 1;

  /// Retourne le numéro de Juz pour une page
  static int juzForPage(int page) => juzForHizb(hizbForPage(page));

  /// Retourne les données complètes d'un Hizb
  static MaghrebiHizb? getHizb(int hizb) {
    if (hizb < 1 || hizb > 60) return null;
    return ahzab[hizb - 1];
  }
}

/// Données d'un Hizb du Mushaf Marocain
class MaghrebiHizb {
  final int hizb;
  final int page;
  final String incipitAr;

  const MaghrebiHizb(this.hizb, this.page, this.incipitAr);

  int get juz => MushafMaghrebiData.juzForHizb(hizb);
}
