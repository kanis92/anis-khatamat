part of '../flutter_quran_screen.dart';

// ---------------------------------------------------------------------------
// Badge Hizb décoratif : remplace le symbole ۞ au début de chaque Hizb
// ---------------------------------------------------------------------------

/// Dessine le badge ornementé style "حزب" (étoile à 8 branches islamique).
class _HizbBadgePainter extends CustomPainter {
  final Color color;
  _HizbBadgePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width * 0.42;
    final innerR = size.width * 0.26;
    final strokeW = size.width * 0.038;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Étoile à 8 branches (géométrie islamique classique)
    final starPath = Path();
    for (var i = 0; i < 8; i++) {
      final outerAngle = (i * math.pi / 4) - math.pi / 2;
      final innerAngle = outerAngle + math.pi / 8;
      final ox = cx + outerR * math.cos(outerAngle);
      final oy = cy + outerR * math.sin(outerAngle);
      final ix = cx + innerR * math.cos(innerAngle);
      final iy = cy + innerR * math.sin(innerAngle);
      if (i == 0) {
        starPath.moveTo(ox, oy);
      } else {
        starPath.lineTo(ox, oy);
      }
      starPath.lineTo(ix, iy);
    }
    starPath.close();
    canvas.drawPath(starPath, strokePaint);

    // Cercle extérieur fin
    canvas.drawCircle(
      Offset(cx, cy),
      outerR + strokeW * 0.3,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW * 0.5,
    );

    // Petits points décoratifs aux 8 pointes
    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      final dotR = outerR + strokeW * 1.1;
      canvas.drawCircle(
        Offset(cx + dotR * math.cos(angle), cy + dotR * math.sin(angle)),
        strokeW * 0.7,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_HizbBadgePainter old) => old.color != color;
}

/// Widget badge "حزب" — remplace ۞ au début d'un Hizb
Widget _hizbStartBadge(Color color, double baseFontSize) {
  final size = baseFontSize * 2.0;
  return SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _HizbBadgePainter(color),
      child: Center(
        child: Text(
          'حزب',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            color: color,
            fontSize: size * 0.26,
            fontWeight: FontWeight.w800,
            fontFamily: 'Amiri',
            height: 1.0,
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------

/// Symbole ۝ (rosette) de la police hafs avec le numéro latin au centre
Widget _verseNumberWithSymbol(String number, Color color, TextStyle baseStyle) {
  final fontSize = baseStyle.fontSize ?? 24;
  final size = fontSize * 1.5;
  return SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Symbole ۝ (rosette) de la police hafs
        Text(
          '\u06DD',
          style: baseStyle.copyWith(
            color: color,
            fontSize: fontSize * 1.1,
            height: 1,
          ),
        ),
        // Numéro latin parfaitement centré
        Positioned.fill(
          child: Center(
            child: Text(
              number,
              style: baseStyle.copyWith(
                color: color,
                fontSize: fontSize * 0.48,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Conversion chiffres arabes-indiques (٠-٩) vers latins (0-9)
String _arabicToLatin(String s) {
  const arabic = '\u0660\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669';
  const latin = '0123456789';
  final sb = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final idx = arabic.indexOf(s[i]);
    sb.write(idx >= 0 ? latin[idx] : s[i]);
  }
  return sb.toString();
}

/// Symbole Rub El Hizb (۞) - U+06DE
const String _rubElHizb = '\u06DE';

/// true = symbole au début d'un hizb (à colorer), false = symbole au rubu'a (noir)
bool _isHizbStartSymbol(int? pageHizb) {
  if (pageHizb == null) return false;
  return pageHizb == 1 || pageHizb % 4 == 0;
}

/// Construit les InlineSpan pour un texte pouvant contenir ۞.
/// - Début de Hizb (isHizbStart=true)  → badge décoratif "حزب" (WidgetSpan)
/// - Subdivision rubu'a (isHizbStart=false) → ۞ coloré (TextSpan standard)
List<InlineSpan> _buildTextWithRubElHizb(
  String text,
  TextStyle baseStyle,
  Color rubElHizbColor,
  bool isHizbStart,
) {
  if (text.isEmpty) return [];
  final rubStyle = baseStyle.copyWith(color: rubElHizbColor);
  final parts = text.split(_rubElHizb);
  if (parts.length == 1) {
    return [TextSpan(text: text, style: baseStyle)];
  }
  final fontSize = baseStyle.fontSize ?? 24;
  final spans = <InlineSpan>[];
  for (var i = 0; i < parts.length; i++) {
    if (parts[i].isNotEmpty) {
      spans.add(TextSpan(text: parts[i], style: baseStyle));
    }
    if (i < parts.length - 1) {
      if (isHizbStart) {
        // Badge ornementé "حزب" — remplace ۞ au début du Hizb
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: fontSize * 0.1),
            child: _hizbStartBadge(rubElHizbColor, fontSize),
          ),
        ));
      } else {
        // Rubu'a / subdivision : garder ۞ standard avec couleur
        spans.add(TextSpan(text: _rubElHizb, style: rubStyle));
      }
    }
  }
  return spans;
}

/// Sépare le texte du verset et le symbole/numéro de fin.
/// Retourne [textPart, verseEnd].
List<String> _splitAyahForVerseEnd(String ayahText) {
  final trimmed = ayahText.trim();
  if (trimmed.isEmpty) return [trimmed, ''];
  // Les chiffres arabes-indiques ٠١٢٣٤٥٦٧٨٩ et le symbole ۝ (U+06DD)
  final verseEndRegex = RegExp(r'[\s\u00A0]*([٠-٩۝]+)\s*$');
  final match = verseEndRegex.firstMatch(trimmed);
  if (match != null) {
    final verseEndPart = match.group(1) ?? '';
    final textPart = trimmed.substring(0, match.start).trim();
    return [textPart, verseEndPart];
  }
  return [trimmed, ''];
}

class QuranLine extends StatelessWidget {
  const QuranLine(this.line, this.bookmarksAyahs, this.bookmarks,
      {super.key,
      this.boxFit = BoxFit.fill,
      this.onLongPress,
      this.verseEndColor,
      this.useLatinNumbers = false,
      this.rubElHizbColor,
      this.pageHizb,
      this.hizbFilterLayer = false});

  final Line line;
  final List<int> bookmarksAyahs;
  final List<Bookmark> bookmarks;
  final BoxFit boxFit;
  final Function? onLongPress;
  final Color? verseEndColor;
  final bool useLatinNumbers;
  final Color? rubElHizbColor;
  /// Numéro du rubu'a/hizb de la page (1-240). 1,4,8,12... = début de hizb.
  final int? pageHizb;
  /// Couche noir (opacité très légère) avant et après le symbole ۞.
  final bool hizbFilterLayer;

  @override
  Widget build(BuildContext context) {
    final hafsStyle = FlutterQuran().hafsStyle;
    final color = verseEndColor ?? Colors.red;
    final verseEndStyle = hafsStyle.copyWith(color: color);
    final rubColor = rubElHizbColor ?? Colors.red;
    final isHizbStart = _isHizbStartSymbol(pageHizb);

    return FittedBox(
        fit: boxFit,
        child: RichText(
            text: TextSpan(
          children: line.ayahs.reversed.map<InlineSpan>((ayah) {
            final parts = _splitAyahForVerseEnd(ayah.ayah);
            final textPart = parts[0];
            var verseEnd = parts[1];
            String? latinNumber;
            if (useLatinNumbers && verseEnd.isNotEmpty) {
              final digitsOnly = verseEnd.replaceAll('\u06DD', '');
              latinNumber = _arabicToLatin(digitsOnly);
            }
            final hasVerseEnd = verseEnd.isNotEmpty;

            return WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onLongPress: () {
                  if (onLongPress != null) {
                    onLongPress!(ayah);
                  } else {
                    final bookmarkId = bookmarksAyahs.contains(ayah.id)
                        ? bookmarks[bookmarksAyahs.indexOf(ayah.id)].id
                        : null;
                    if (bookmarkId != null) {
                      AppBloc.bookmarksCubit.removeBookmark(bookmarkId);
                    } else {
                      showDialog(
                          context: context,
                          builder: (ctx) => AyahLongClickDialog(ayah));
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                    color: bookmarksAyahs.contains(ayah.id)
                        ? Color(bookmarks[bookmarksAyahs.indexOf(ayah.id)]
                                .colorCode)
                            .withOpacity(0.7)
                        : null,
                  ),
                  child: hasVerseEnd
                      ? (useLatinNumbers && latinNumber != null && latinNumber.isNotEmpty
                          ? RichText(
                              textDirection: TextDirection.rtl,
                              text: TextSpan(
                                style: hafsStyle,
                                children: <InlineSpan>[
                                  ..._buildTextWithRubElHizb(textPart, hafsStyle, rubColor, isHizbStart),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: _verseNumberWithSymbol(
                                        latinNumber,
                                        color,
                                        hafsStyle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RichText(
                              textDirection: TextDirection.rtl,
                              text: TextSpan(
                                style: hafsStyle,
                                children: <InlineSpan>[
                                  ..._buildTextWithRubElHizb(textPart, hafsStyle, rubColor, isHizbStart),
                                  TextSpan(text: ' $verseEnd', style: verseEndStyle),
                                ],
                              ),
                            ))
                      : ayah.ayah.contains(_rubElHizb)
                          ? RichText(
                              textDirection: TextDirection.rtl,
                              text: TextSpan(
                                style: hafsStyle,
                                children: _buildTextWithRubElHizb(ayah.ayah, hafsStyle, rubColor, isHizbStart),
                              ),
                            )
                          : Text(
                              ayah.ayah,
                              style: hafsStyle,
                            ),
                ),
              ),
            );
          }).toList(),
          style: hafsStyle,
        )));
  }
}
