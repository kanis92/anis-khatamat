/// Type de marqueur dans le Mushaf
enum HizbMarkerType {
  hizb, // حزب — début du Hizb
  thumun, // ثمن — 1/8 du Hizb
  rub, // ربع — 1/4 du Hizb
  nisf, // نصف — 1/2 du Hizb
}

/// Un marqueur de subdivision dans le Mushaf
class HizbMarker {
  final int hizbNumber; // 1-60
  final HizbMarkerType type;
  final int
  subdivisionIndex; // 0=حزب, 1=ثمن, 2=ربع, 3=ثمن, 4=نصف, 5=ثمن, 6=ربع, 7=ثمن
  final int surah;
  final int ayah;
  final int pageHafs; // Page Mushaf Madina (Hafs)
  final int pageWarsh; // Alias de compatibilité égal à pageHafs

  const HizbMarker({
    required this.hizbNumber,
    required this.type,
    required this.subdivisionIndex,
    required this.surah,
    required this.ayah,
    required this.pageHafs,
    required this.pageWarsh,
  });

  String get arabicLabel {
    switch (type) {
      case HizbMarkerType.hizb:
        return 'حزب $hizbNumber';
      case HizbMarkerType.nisf:
        return 'نصف الحزب $hizbNumber';
      case HizbMarkerType.rub:
        final q = subdivisionIndex == 2 ? 'ربع' : 'ثلاثة أرباع';
        return '$q الحزب $hizbNumber';
      case HizbMarkerType.thumun:
        return 'ثمن الحزب $hizbNumber';
    }
  }

  String get frenchLabel {
    switch (type) {
      case HizbMarkerType.hizb:
        return 'Hizb $hizbNumber';
      case HizbMarkerType.nisf:
        return '½ Hizb $hizbNumber';
      case HizbMarkerType.rub:
        final q = subdivisionIndex == 2 ? '¼' : '¾';
        return '$q Hizb $hizbNumber';
      case HizbMarkerType.thumun:
        final idx = subdivisionIndex;
        final frac =
            idx == 1
                ? '⅛'
                : idx == 3
                ? '⅜'
                : idx == 5
                ? '⅝'
                : '⅞';
        return '$frac Hizb $hizbNumber';
    }
  }

  /// Identifiant global unique (0-479) pour tri et indexation
  int get globalIndex => (hizbNumber - 1) * 8 + subdivisionIndex;
}

/// Données complètes des 60 Hizb et leurs subdivisions (4 Rub' par Hizb)
/// Référence : Mushaf Al-Madina (Hafs), Mushaf Al-Mohammadi (Warsh)
/// Chaque Hizb est divisé en 4 أرباع (quarters) = حزب, ربع, نصف, ثلاثة أرباع
class QuranSubdivisionData {
  QuranSubdivisionData._();

  /// Les 240 marqueurs Rub' al-Hizb (أرباع الأحزاب)
  /// 4 par Hizb × 60 Hizb = 240 marqueurs principaux
  /// Index: [hizbNumber-1][0..3] = حزب, ربع, نصف, ثلاثة أرباع
  ///
  /// Bornes certifiées depuis Quran Foundation Content API v4
  /// (`rub_el_hizb_number` 1..240). `pageHafs` correspond au JSON du Mushaf
  /// effectivement rendu. Le quatrième entier est conservé pour compatibilité
  /// et reprend la même page Hafs ; aucune pagination Warsh n'est certifiée ici.
  static const List<List<List<int>>> _rubData = [
    // [surah, ayah, pageHafs, pageHafsCompatibility]
    [
      [1, 1, 1, 1],
      [2, 26, 5, 5],
      [2, 44, 7, 7],
      [2, 60, 9, 9],
    ],
    [
      [2, 75, 11, 11],
      [2, 92, 14, 14],
      [2, 106, 17, 17],
      [2, 124, 19, 19],
    ],
    [
      [2, 142, 22, 22],
      [2, 158, 24, 24],
      [2, 177, 27, 27],
      [2, 189, 29, 29],
    ],
    [
      [2, 203, 32, 32],
      [2, 219, 34, 34],
      [2, 233, 37, 37],
      [2, 243, 39, 39],
    ],
    [
      [2, 253, 42, 42],
      [2, 263, 44, 44],
      [2, 272, 46, 46],
      [2, 283, 49, 49],
    ],
    [
      [3, 15, 51, 51],
      [3, 33, 54, 54],
      [3, 52, 56, 56],
      [3, 75, 59, 59],
    ],
    [
      [3, 93, 62, 62],
      [3, 113, 64, 64],
      [3, 133, 67, 67],
      [3, 153, 69, 69],
    ],
    [
      [3, 171, 72, 72],
      [3, 186, 74, 74],
      [4, 1, 77, 77],
      [4, 12, 79, 79],
    ],
    [
      [4, 24, 82, 82],
      [4, 36, 84, 84],
      [4, 58, 87, 87],
      [4, 74, 89, 89],
    ],
    [
      [4, 88, 92, 92],
      [4, 100, 94, 94],
      [4, 114, 97, 97],
      [4, 135, 100, 100],
    ],
    [
      [4, 148, 102, 102],
      [4, 163, 104, 104],
      [5, 1, 106, 106],
      [5, 12, 109, 109],
    ],
    [
      [5, 27, 112, 112],
      [5, 41, 114, 114],
      [5, 51, 117, 117],
      [5, 67, 119, 119],
    ],
    [
      [5, 82, 121, 121],
      [5, 97, 124, 124],
      [5, 109, 126, 126],
      [6, 13, 129, 129],
    ],
    [
      [6, 36, 132, 132],
      [6, 59, 134, 134],
      [6, 74, 137, 137],
      [6, 95, 140, 140],
    ],
    [
      [6, 111, 142, 142],
      [6, 127, 144, 144],
      [6, 141, 146, 146],
      [6, 151, 148, 148],
    ],
    [
      [7, 1, 151, 151],
      [7, 31, 154, 154],
      [7, 47, 156, 156],
      [7, 65, 158, 158],
    ],
    [
      [7, 88, 162, 162],
      [7, 117, 164, 164],
      [7, 142, 167, 167],
      [7, 156, 170, 170],
    ],
    [
      [7, 171, 173, 173],
      [7, 189, 175, 175],
      [8, 1, 177, 177],
      [8, 22, 179, 179],
    ],
    [
      [8, 41, 182, 182],
      [8, 61, 184, 184],
      [9, 1, 187, 187],
      [9, 19, 189, 189],
    ],
    [
      [9, 34, 192, 192],
      [9, 46, 194, 194],
      [9, 60, 196, 196],
      [9, 75, 199, 199],
    ],
    [
      [9, 93, 201, 201],
      [9, 111, 204, 204],
      [9, 122, 206, 206],
      [10, 11, 209, 209],
    ],
    [
      [10, 26, 212, 212],
      [10, 53, 214, 214],
      [10, 71, 217, 217],
      [10, 90, 219, 219],
    ],
    [
      [11, 6, 222, 222],
      [11, 24, 224, 224],
      [11, 41, 226, 226],
      [11, 61, 228, 228],
    ],
    [
      [11, 84, 231, 231],
      [11, 108, 233, 233],
      [12, 7, 236, 236],
      [12, 30, 238, 238],
    ],
    [
      [12, 53, 242, 242],
      [12, 77, 244, 244],
      [12, 101, 247, 247],
      [13, 5, 249, 249],
    ],
    [
      [13, 19, 252, 252],
      [13, 35, 254, 254],
      [14, 10, 256, 256],
      [14, 28, 259, 259],
    ],
    [
      [15, 1, 262, 262],
      [15, 49, 264, 264],
      [16, 1, 267, 267],
      [16, 30, 270, 270],
    ],
    [
      [16, 51, 272, 272],
      [16, 75, 275, 275],
      [16, 90, 277, 277],
      [16, 111, 280, 280],
    ],
    [
      [17, 1, 282, 282],
      [17, 23, 284, 284],
      [17, 50, 287, 287],
      [17, 70, 289, 289],
    ],
    [
      [17, 99, 292, 292],
      [18, 17, 295, 295],
      [18, 32, 297, 297],
      [18, 51, 299, 299],
    ],
    [
      [18, 75, 302, 302],
      [18, 99, 304, 304],
      [19, 22, 306, 306],
      [19, 59, 309, 309],
    ],
    [
      [20, 1, 312, 312],
      [20, 55, 315, 315],
      [20, 83, 317, 317],
      [20, 111, 319, 319],
    ],
    [
      [21, 1, 322, 322],
      [21, 29, 324, 324],
      [21, 51, 326, 326],
      [21, 83, 329, 329],
    ],
    [
      [22, 1, 332, 332],
      [22, 19, 334, 334],
      [22, 38, 336, 336],
      [22, 60, 339, 339],
    ],
    [
      [23, 1, 342, 342],
      [23, 36, 344, 344],
      [23, 75, 347, 347],
      [24, 1, 350, 350],
    ],
    [
      [24, 21, 352, 352],
      [24, 35, 354, 354],
      [24, 53, 356, 356],
      [25, 1, 359, 359],
    ],
    [
      [25, 21, 362, 362],
      [25, 53, 364, 364],
      [26, 1, 367, 367],
      [26, 52, 369, 369],
    ],
    [
      [26, 111, 371, 371],
      [26, 181, 374, 374],
      [27, 1, 377, 377],
      [27, 27, 379, 379],
    ],
    [
      [27, 56, 382, 382],
      [27, 82, 384, 384],
      [28, 12, 386, 386],
      [28, 29, 389, 389],
    ],
    [
      [28, 51, 392, 392],
      [28, 76, 394, 394],
      [29, 1, 396, 396],
      [29, 26, 399, 399],
    ],
    [
      [29, 46, 402, 402],
      [30, 1, 404, 404],
      [30, 31, 407, 407],
      [30, 54, 410, 410],
    ],
    [
      [31, 22, 413, 413],
      [32, 11, 415, 415],
      [33, 1, 418, 418],
      [33, 18, 420, 420],
    ],
    [
      [33, 31, 422, 422],
      [33, 51, 425, 425],
      [33, 60, 426, 426],
      [34, 10, 429, 429],
    ],
    [
      [34, 24, 431, 431],
      [34, 46, 433, 433],
      [35, 15, 436, 436],
      [35, 41, 439, 439],
    ],
    [
      [36, 28, 442, 442],
      [36, 60, 444, 444],
      [37, 22, 446, 446],
      [37, 83, 449, 449],
    ],
    [
      [37, 145, 451, 451],
      [38, 21, 454, 454],
      [38, 52, 456, 456],
      [39, 8, 459, 459],
    ],
    [
      [39, 32, 462, 462],
      [39, 53, 464, 464],
      [40, 1, 467, 467],
      [40, 21, 469, 469],
    ],
    [
      [40, 41, 472, 472],
      [40, 66, 474, 474],
      [41, 9, 477, 477],
      [41, 25, 479, 479],
    ],
    [
      [41, 47, 482, 482],
      [42, 13, 484, 484],
      [42, 27, 486, 486],
      [42, 51, 488, 488],
    ],
    [
      [43, 24, 491, 491],
      [43, 57, 493, 493],
      [44, 17, 496, 496],
      [45, 12, 499, 499],
    ],
    [
      [46, 1, 502, 502],
      [46, 21, 505, 505],
      [47, 10, 507, 507],
      [47, 33, 510, 510],
    ],
    [
      [48, 18, 513, 513],
      [49, 1, 515, 515],
      [49, 14, 517, 517],
      [50, 27, 519, 519],
    ],
    [
      [51, 31, 522, 522],
      [52, 24, 524, 524],
      [53, 26, 526, 526],
      [54, 9, 529, 529],
    ],
    [
      [55, 1, 531, 531],
      [56, 1, 534, 534],
      [56, 75, 536, 536],
      [57, 16, 539, 539],
    ],
    [
      [58, 1, 542, 542],
      [58, 14, 544, 544],
      [59, 11, 547, 547],
      [60, 7, 550, 550],
    ],
    [
      [62, 1, 553, 553],
      [63, 4, 554, 554],
      [65, 1, 558, 558],
      [66, 1, 560, 560],
    ],
    [
      [67, 1, 562, 562],
      [68, 1, 564, 564],
      [69, 1, 566, 566],
      [70, 19, 569, 569],
    ],
    [
      [72, 1, 572, 572],
      [73, 20, 575, 575],
      [75, 1, 577, 577],
      [76, 19, 579, 579],
    ],
    [
      [78, 1, 582, 582],
      [80, 1, 585, 585],
      [82, 1, 587, 587],
      [84, 1, 589, 589],
    ],
    [
      [87, 1, 591, 591],
      [90, 1, 594, 594],
      [94, 1, 596, 596],
      [100, 9, 600, 600],
    ],
  ];

  /// Retourne les 4 marqueurs Rub' pour un Hizb donné (1-60)
  static List<HizbMarker> getQuartersForHizb(int hizbNumber) {
    if (hizbNumber < 1 || hizbNumber > 60) return [];
    final data = _rubData[hizbNumber - 1];
    const types = [
      HizbMarkerType.hizb,
      HizbMarkerType.rub,
      HizbMarkerType.nisf,
      HizbMarkerType.rub,
    ];
    const subIdx = [0, 2, 4, 6];
    return List.generate(4, (i) {
      final d = data[i];
      return HizbMarker(
        hizbNumber: hizbNumber,
        type: types[i],
        subdivisionIndex: subIdx[i],
        surah: d[0],
        ayah: d[1],
        pageHafs: d[2],
        pageWarsh: d[3],
      );
    });
  }

  /// Retourne tous les 240 marqueurs Rub' al-Hizb
  static List<HizbMarker> getAllQuarters() {
    final result = <HizbMarker>[];
    for (var h = 1; h <= 60; h++) {
      result.addAll(getQuartersForHizb(h));
    }
    return result;
  }

  /// Retourne le marqueur le plus proche pour une page donnée (Hafs)
  static HizbMarker? getMarkerForPageHafs(int page) {
    HizbMarker? best;
    for (var h = 1; h <= 60; h++) {
      for (final m in getQuartersForHizb(h)) {
        if (m.pageHafs <= page) {
          if (best == null || m.pageHafs > best.pageHafs) {
            best = m;
          }
        }
      }
    }
    return best;
  }

  /// Retourne le marqueur le plus proche pour une page donnée (Warsh)
  static HizbMarker? getMarkerForPageWarsh(int page) {
    HizbMarker? best;
    for (var h = 1; h <= 60; h++) {
      for (final m in getQuartersForHizb(h)) {
        if (m.pageWarsh <= page) {
          if (best == null || m.pageWarsh > best.pageWarsh) {
            best = m;
          }
        }
      }
    }
    return best;
  }

  /// Retourne la page (Hafs) pour un Hizb + subdivision
  static int pageForSubdivision(int hizbNumber, int quarterIndex) {
    if (hizbNumber < 1 || hizbNumber > 60) return 1;
    final quarters = getQuartersForHizb(hizbNumber);
    if (quarterIndex < 0 || quarterIndex >= quarters.length)
      return quarters.first.pageHafs;
    return quarters[quarterIndex].pageHafs;
  }

  /// Noms des 114 Sourates pour la navigation
  static const List<Map<String, dynamic>> surahList = [
    {
      'number': 1,
      'name': 'الفاتحة',
      'nameFr': 'Al-Fatiha',
      'verses': 7,
      'pageHafs': 1,
    },
    {
      'number': 2,
      'name': 'البقرة',
      'nameFr': 'Al-Baqara',
      'verses': 286,
      'pageHafs': 2,
    },
    {
      'number': 3,
      'name': 'آل عمران',
      'nameFr': 'Ali Imran',
      'verses': 200,
      'pageHafs': 50,
    },
    {
      'number': 4,
      'name': 'النساء',
      'nameFr': 'An-Nisa',
      'verses': 176,
      'pageHafs': 77,
    },
    {
      'number': 5,
      'name': 'المائدة',
      'nameFr': 'Al-Ma\'ida',
      'verses': 120,
      'pageHafs': 106,
    },
    {
      'number': 6,
      'name': 'الأنعام',
      'nameFr': 'Al-An\'am',
      'verses': 165,
      'pageHafs': 128,
    },
    {
      'number': 7,
      'name': 'الأعراف',
      'nameFr': 'Al-A\'raf',
      'verses': 206,
      'pageHafs': 151,
    },
    {
      'number': 8,
      'name': 'الأنفال',
      'nameFr': 'Al-Anfal',
      'verses': 75,
      'pageHafs': 177,
    },
    {
      'number': 9,
      'name': 'التوبة',
      'nameFr': 'At-Tawba',
      'verses': 129,
      'pageHafs': 187,
    },
    {
      'number': 10,
      'name': 'يونس',
      'nameFr': 'Yunus',
      'verses': 109,
      'pageHafs': 208,
    },
    {
      'number': 11,
      'name': 'هود',
      'nameFr': 'Hud',
      'verses': 123,
      'pageHafs': 221,
    },
    {
      'number': 12,
      'name': 'يوسف',
      'nameFr': 'Yusuf',
      'verses': 111,
      'pageHafs': 235,
    },
    {
      'number': 13,
      'name': 'الرعد',
      'nameFr': 'Ar-Ra\'d',
      'verses': 43,
      'pageHafs': 249,
    },
    {
      'number': 14,
      'name': 'إبراهيم',
      'nameFr': 'Ibrahim',
      'verses': 52,
      'pageHafs': 255,
    },
    {
      'number': 15,
      'name': 'الحجر',
      'nameFr': 'Al-Hijr',
      'verses': 99,
      'pageHafs': 262,
    },
    {
      'number': 16,
      'name': 'النحل',
      'nameFr': 'An-Nahl',
      'verses': 128,
      'pageHafs': 267,
    },
    {
      'number': 17,
      'name': 'الإسراء',
      'nameFr': 'Al-Isra',
      'verses': 111,
      'pageHafs': 282,
    },
    {
      'number': 18,
      'name': 'الكهف',
      'nameFr': 'Al-Kahf',
      'verses': 110,
      'pageHafs': 293,
    },
    {
      'number': 19,
      'name': 'مريم',
      'nameFr': 'Maryam',
      'verses': 98,
      'pageHafs': 305,
    },
    {
      'number': 20,
      'name': 'طه',
      'nameFr': 'Ta-Ha',
      'verses': 135,
      'pageHafs': 312,
    },
    {
      'number': 21,
      'name': 'الأنبياء',
      'nameFr': 'Al-Anbiya',
      'verses': 112,
      'pageHafs': 322,
    },
    {
      'number': 22,
      'name': 'الحج',
      'nameFr': 'Al-Hajj',
      'verses': 78,
      'pageHafs': 332,
    },
    {
      'number': 23,
      'name': 'المؤمنون',
      'nameFr': 'Al-Mu\'minun',
      'verses': 118,
      'pageHafs': 342,
    },
    {
      'number': 24,
      'name': 'النور',
      'nameFr': 'An-Nur',
      'verses': 64,
      'pageHafs': 350,
    },
    {
      'number': 25,
      'name': 'الفرقان',
      'nameFr': 'Al-Furqan',
      'verses': 77,
      'pageHafs': 359,
    },
    {
      'number': 26,
      'name': 'الشعراء',
      'nameFr': 'Ash-Shu\'ara',
      'verses': 227,
      'pageHafs': 367,
    },
    {
      'number': 27,
      'name': 'النمل',
      'nameFr': 'An-Naml',
      'verses': 93,
      'pageHafs': 377,
    },
    {
      'number': 28,
      'name': 'القصص',
      'nameFr': 'Al-Qasas',
      'verses': 88,
      'pageHafs': 385,
    },
    {
      'number': 29,
      'name': 'العنكبوت',
      'nameFr': 'Al-Ankabut',
      'verses': 69,
      'pageHafs': 396,
    },
    {
      'number': 30,
      'name': 'الروم',
      'nameFr': 'Ar-Rum',
      'verses': 60,
      'pageHafs': 404,
    },
    {
      'number': 31,
      'name': 'لقمان',
      'nameFr': 'Luqman',
      'verses': 34,
      'pageHafs': 411,
    },
    {
      'number': 32,
      'name': 'السجدة',
      'nameFr': 'As-Sajda',
      'verses': 30,
      'pageHafs': 415,
    },
    {
      'number': 33,
      'name': 'الأحزاب',
      'nameFr': 'Al-Ahzab',
      'verses': 73,
      'pageHafs': 418,
    },
    {
      'number': 34,
      'name': 'سبأ',
      'nameFr': 'Saba',
      'verses': 54,
      'pageHafs': 428,
    },
    {
      'number': 35,
      'name': 'فاطر',
      'nameFr': 'Fatir',
      'verses': 45,
      'pageHafs': 434,
    },
    {
      'number': 36,
      'name': 'يس',
      'nameFr': 'Ya-Sin',
      'verses': 83,
      'pageHafs': 440,
    },
    {
      'number': 37,
      'name': 'الصافات',
      'nameFr': 'As-Saffat',
      'verses': 182,
      'pageHafs': 446,
    },
    {'number': 38, 'name': 'ص', 'nameFr': 'Sad', 'verses': 88, 'pageHafs': 453},
    {
      'number': 39,
      'name': 'الزمر',
      'nameFr': 'Az-Zumar',
      'verses': 75,
      'pageHafs': 458,
    },
    {
      'number': 40,
      'name': 'غافر',
      'nameFr': 'Ghafir',
      'verses': 85,
      'pageHafs': 467,
    },
    {
      'number': 41,
      'name': 'فصلت',
      'nameFr': 'Fussilat',
      'verses': 54,
      'pageHafs': 477,
    },
    {
      'number': 42,
      'name': 'الشورى',
      'nameFr': 'Ash-Shura',
      'verses': 53,
      'pageHafs': 483,
    },
    {
      'number': 43,
      'name': 'الزخرف',
      'nameFr': 'Az-Zukhruf',
      'verses': 89,
      'pageHafs': 489,
    },
    {
      'number': 44,
      'name': 'الدخان',
      'nameFr': 'Ad-Dukhan',
      'verses': 59,
      'pageHafs': 496,
    },
    {
      'number': 45,
      'name': 'الجاثية',
      'nameFr': 'Al-Jathiya',
      'verses': 37,
      'pageHafs': 499,
    },
    {
      'number': 46,
      'name': 'الأحقاف',
      'nameFr': 'Al-Ahqaf',
      'verses': 35,
      'pageHafs': 502,
    },
    {
      'number': 47,
      'name': 'محمد',
      'nameFr': 'Muhammad',
      'verses': 38,
      'pageHafs': 507,
    },
    {
      'number': 48,
      'name': 'الفتح',
      'nameFr': 'Al-Fath',
      'verses': 29,
      'pageHafs': 511,
    },
    {
      'number': 49,
      'name': 'الحجرات',
      'nameFr': 'Al-Hujurat',
      'verses': 18,
      'pageHafs': 515,
    },
    {'number': 50, 'name': 'ق', 'nameFr': 'Qaf', 'verses': 45, 'pageHafs': 518},
    {
      'number': 51,
      'name': 'الذاريات',
      'nameFr': 'Adh-Dhariyat',
      'verses': 60,
      'pageHafs': 520,
    },
    {
      'number': 52,
      'name': 'الطور',
      'nameFr': 'At-Tur',
      'verses': 49,
      'pageHafs': 523,
    },
    {
      'number': 53,
      'name': 'النجم',
      'nameFr': 'An-Najm',
      'verses': 62,
      'pageHafs': 526,
    },
    {
      'number': 54,
      'name': 'القمر',
      'nameFr': 'Al-Qamar',
      'verses': 55,
      'pageHafs': 528,
    },
    {
      'number': 55,
      'name': 'الرحمن',
      'nameFr': 'Ar-Rahman',
      'verses': 78,
      'pageHafs': 531,
    },
    {
      'number': 56,
      'name': 'الواقعة',
      'nameFr': 'Al-Waqi\'a',
      'verses': 96,
      'pageHafs': 534,
    },
    {
      'number': 57,
      'name': 'الحديد',
      'nameFr': 'Al-Hadid',
      'verses': 29,
      'pageHafs': 537,
    },
    {
      'number': 58,
      'name': 'المجادلة',
      'nameFr': 'Al-Mujadila',
      'verses': 22,
      'pageHafs': 542,
    },
    {
      'number': 59,
      'name': 'الحشر',
      'nameFr': 'Al-Hashr',
      'verses': 24,
      'pageHafs': 545,
    },
    {
      'number': 60,
      'name': 'الممتحنة',
      'nameFr': 'Al-Mumtahina',
      'verses': 13,
      'pageHafs': 549,
    },
    {
      'number': 61,
      'name': 'الصف',
      'nameFr': 'As-Saff',
      'verses': 14,
      'pageHafs': 551,
    },
    {
      'number': 62,
      'name': 'الجمعة',
      'nameFr': 'Al-Jumu\'a',
      'verses': 11,
      'pageHafs': 553,
    },
    {
      'number': 63,
      'name': 'المنافقون',
      'nameFr': 'Al-Munafiqun',
      'verses': 11,
      'pageHafs': 554,
    },
    {
      'number': 64,
      'name': 'التغابن',
      'nameFr': 'At-Taghabun',
      'verses': 18,
      'pageHafs': 556,
    },
    {
      'number': 65,
      'name': 'الطلاق',
      'nameFr': 'At-Talaq',
      'verses': 12,
      'pageHafs': 558,
    },
    {
      'number': 66,
      'name': 'التحريم',
      'nameFr': 'At-Tahrim',
      'verses': 12,
      'pageHafs': 560,
    },
    {
      'number': 67,
      'name': 'الملك',
      'nameFr': 'Al-Mulk',
      'verses': 30,
      'pageHafs': 562,
    },
    {
      'number': 68,
      'name': 'القلم',
      'nameFr': 'Al-Qalam',
      'verses': 52,
      'pageHafs': 564,
    },
    {
      'number': 69,
      'name': 'الحاقة',
      'nameFr': 'Al-Haqqa',
      'verses': 52,
      'pageHafs': 566,
    },
    {
      'number': 70,
      'name': 'المعارج',
      'nameFr': 'Al-Ma\'arij',
      'verses': 44,
      'pageHafs': 568,
    },
    {
      'number': 71,
      'name': 'نوح',
      'nameFr': 'Nuh',
      'verses': 28,
      'pageHafs': 570,
    },
    {
      'number': 72,
      'name': 'الجن',
      'nameFr': 'Al-Jinn',
      'verses': 28,
      'pageHafs': 572,
    },
    {
      'number': 73,
      'name': 'المزمل',
      'nameFr': 'Al-Muzzammil',
      'verses': 20,
      'pageHafs': 574,
    },
    {
      'number': 74,
      'name': 'المدثر',
      'nameFr': 'Al-Muddathir',
      'verses': 56,
      'pageHafs': 575,
    },
    {
      'number': 75,
      'name': 'القيامة',
      'nameFr': 'Al-Qiyama',
      'verses': 40,
      'pageHafs': 577,
    },
    {
      'number': 76,
      'name': 'الإنسان',
      'nameFr': 'Al-Insan',
      'verses': 31,
      'pageHafs': 578,
    },
    {
      'number': 77,
      'name': 'المرسلات',
      'nameFr': 'Al-Mursalat',
      'verses': 50,
      'pageHafs': 580,
    },
    {
      'number': 78,
      'name': 'النبأ',
      'nameFr': 'An-Naba',
      'verses': 40,
      'pageHafs': 582,
    },
    {
      'number': 79,
      'name': 'النازعات',
      'nameFr': 'An-Nazi\'at',
      'verses': 46,
      'pageHafs': 583,
    },
    {
      'number': 80,
      'name': 'عبس',
      'nameFr': 'Abasa',
      'verses': 42,
      'pageHafs': 585,
    },
    {
      'number': 81,
      'name': 'التكوير',
      'nameFr': 'At-Takwir',
      'verses': 29,
      'pageHafs': 586,
    },
    {
      'number': 82,
      'name': 'الانفطار',
      'nameFr': 'Al-Infitar',
      'verses': 19,
      'pageHafs': 587,
    },
    {
      'number': 83,
      'name': 'المطففين',
      'nameFr': 'Al-Mutaffifin',
      'verses': 36,
      'pageHafs': 587,
    },
    {
      'number': 84,
      'name': 'الانشقاق',
      'nameFr': 'Al-Inshiqaq',
      'verses': 25,
      'pageHafs': 589,
    },
    {
      'number': 85,
      'name': 'البروج',
      'nameFr': 'Al-Buruj',
      'verses': 22,
      'pageHafs': 590,
    },
    {
      'number': 86,
      'name': 'الطارق',
      'nameFr': 'At-Tariq',
      'verses': 17,
      'pageHafs': 591,
    },
    {
      'number': 87,
      'name': 'الأعلى',
      'nameFr': 'Al-A\'la',
      'verses': 19,
      'pageHafs': 591,
    },
    {
      'number': 88,
      'name': 'الغاشية',
      'nameFr': 'Al-Ghashiya',
      'verses': 26,
      'pageHafs': 592,
    },
    {
      'number': 89,
      'name': 'الفجر',
      'nameFr': 'Al-Fajr',
      'verses': 30,
      'pageHafs': 593,
    },
    {
      'number': 90,
      'name': 'البلد',
      'nameFr': 'Al-Balad',
      'verses': 20,
      'pageHafs': 594,
    },
    {
      'number': 91,
      'name': 'الشمس',
      'nameFr': 'Ash-Shams',
      'verses': 15,
      'pageHafs': 595,
    },
    {
      'number': 92,
      'name': 'الليل',
      'nameFr': 'Al-Layl',
      'verses': 21,
      'pageHafs': 595,
    },
    {
      'number': 93,
      'name': 'الضحى',
      'nameFr': 'Ad-Duha',
      'verses': 11,
      'pageHafs': 596,
    },
    {
      'number': 94,
      'name': 'الشرح',
      'nameFr': 'Ash-Sharh',
      'verses': 8,
      'pageHafs': 596,
    },
    {
      'number': 95,
      'name': 'التين',
      'nameFr': 'At-Tin',
      'verses': 8,
      'pageHafs': 597,
    },
    {
      'number': 96,
      'name': 'العلق',
      'nameFr': 'Al-Alaq',
      'verses': 19,
      'pageHafs': 597,
    },
    {
      'number': 97,
      'name': 'القدر',
      'nameFr': 'Al-Qadr',
      'verses': 5,
      'pageHafs': 598,
    },
    {
      'number': 98,
      'name': 'البينة',
      'nameFr': 'Al-Bayyina',
      'verses': 8,
      'pageHafs': 598,
    },
    {
      'number': 99,
      'name': 'الزلزلة',
      'nameFr': 'Az-Zalzala',
      'verses': 8,
      'pageHafs': 599,
    },
    {
      'number': 100,
      'name': 'العاديات',
      'nameFr': 'Al-Adiyat',
      'verses': 11,
      'pageHafs': 599,
    },
    {
      'number': 101,
      'name': 'القارعة',
      'nameFr': 'Al-Qari\'a',
      'verses': 11,
      'pageHafs': 600,
    },
    {
      'number': 102,
      'name': 'التكاثر',
      'nameFr': 'At-Takathur',
      'verses': 8,
      'pageHafs': 600,
    },
    {
      'number': 103,
      'name': 'العصر',
      'nameFr': 'Al-Asr',
      'verses': 3,
      'pageHafs': 601,
    },
    {
      'number': 104,
      'name': 'الهمزة',
      'nameFr': 'Al-Humaza',
      'verses': 9,
      'pageHafs': 601,
    },
    {
      'number': 105,
      'name': 'الفيل',
      'nameFr': 'Al-Fil',
      'verses': 5,
      'pageHafs': 601,
    },
    {
      'number': 106,
      'name': 'قريش',
      'nameFr': 'Quraysh',
      'verses': 4,
      'pageHafs': 602,
    },
    {
      'number': 107,
      'name': 'الماعون',
      'nameFr': 'Al-Ma\'un',
      'verses': 7,
      'pageHafs': 602,
    },
    {
      'number': 108,
      'name': 'الكوثر',
      'nameFr': 'Al-Kawthar',
      'verses': 3,
      'pageHafs': 602,
    },
    {
      'number': 109,
      'name': 'الكافرون',
      'nameFr': 'Al-Kafirun',
      'verses': 6,
      'pageHafs': 603,
    },
    {
      'number': 110,
      'name': 'النصر',
      'nameFr': 'An-Nasr',
      'verses': 3,
      'pageHafs': 603,
    },
    {
      'number': 111,
      'name': 'المسد',
      'nameFr': 'Al-Masad',
      'verses': 5,
      'pageHafs': 603,
    },
    {
      'number': 112,
      'name': 'الإخلاص',
      'nameFr': 'Al-Ikhlas',
      'verses': 4,
      'pageHafs': 604,
    },
    {
      'number': 113,
      'name': 'الفلق',
      'nameFr': 'Al-Falaq',
      'verses': 5,
      'pageHafs': 604,
    },
    {
      'number': 114,
      'name': 'الناس',
      'nameFr': 'An-Nas',
      'verses': 6,
      'pageHafs': 604,
    },
  ];
}
