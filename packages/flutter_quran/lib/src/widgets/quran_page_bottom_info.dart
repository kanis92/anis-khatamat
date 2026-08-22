part of '../flutter_quran_screen.dart';

class QuranPageBottomInfoWidget extends StatefulWidget {
  const QuranPageBottomInfoWidget(
      {required this.surahName,
      required this.page,
      required this.hizb,
      this.useLatinNumbers = false,
      super.key});

  final String surahName;
  final int page;
  final int? hizb;
  final bool useLatinNumbers;

  @override
  State<QuranPageBottomInfoWidget> createState() =>
      _QuranPageBottomInfoWidgetState();
}

class _QuranPageBottomInfoWidgetState extends State<QuranPageBottomInfoWidget> {
  String hizbText = '';

  @override
  void didChangeDependencies() {
    if (widget.hizb != null) {
      hizbText =
          '${mapNumberToHizbPart(widget.hizb!)} الحزب ${QuranConstants.quranHizbs[(widget.hizb! / 4).floor()]}';
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 100,
          height: 32,
          child: widget.hizb != null
              ? FittedBox(
                  child: Text(
                    hizbText,
                    style: FlutterQuran()
                        .hafsStyle
                        .copyWith(color: const Color(0xFF798FAB), fontSize: 12),
                  ),
                )
              : null,
        ),
        Text(widget.useLatinNumbers
                ? widget.page.toString()
                : widget.page.toString().toArabic(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            )),
        SizedBox(
          width: 100,
          height: 32,
          child: FittedBox(
            child: Text('سورة ${widget.surahName}',
                style: FlutterQuran()
                    .hafsStyle
                    .copyWith(color: const Color(0xFF798FAB), fontSize: 12)),
          ),
        ),
      ],
    );
  }

  String mapNumberToHizbPart(int number) {
    final reminder = (number / 4) % 1;
    if (number / 4 == 0) {
      return '';
    } else if (reminder == 0.25) {
      return 'ربع';
    } else if (reminder == 0.5) {
      return 'نصف';
    } else if (reminder == 0.75) {
      return 'ثلاثة أرباع';
    } else {
      return '';
    }
  }
}
