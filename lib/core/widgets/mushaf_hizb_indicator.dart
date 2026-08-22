import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../extensions/l10n_extensions.dart';
import '../theme/app_theme.dart';

/// Symbole traditionnel du rub' el hizb (۞), utilisé comme signe discret du
/// repère de Hizb. Purement décoratif : jamais mêlé au texte coranique rendu.
const String kRubElHizbGlyph = '۞';

/// Le lecteur Mushaf est rendu en RTL forcé par `FlutterQuranScreen`.
/// L'indicateur, lui, doit suivre la langue de l'interface pour rester lisible.
TextDirection _uiDirection(BuildContext context) =>
    _isArabic(context) ? TextDirection.rtl : TextDirection.ltr;

bool _isArabic(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar';

const String _arabicIndicDigits = '٠١٢٣٤٥٦٧٨٩';

/// Formate un nombre pour l'affichage Mushaf.
///
/// En arabe on écrit ٤٤ et non 44 : c'est ce que porte le Mushaf lui-même.
/// `intl` ne suffit pas, la locale `ar` moderne du CLDR utilise les chiffres
/// latins ; seuls des sous-tags comme `ar_EG` gardent les chiffres indiens.
String mushafNumber(BuildContext context, int value) {
  final digits = value.toString();
  if (!_isArabic(context)) return digits;
  return digits
      .split('')
      .map((c) {
        final d = int.tryParse(c);
        return d == null ? c : _arabicIndicDigits[d];
      })
      .join();
}

/// « Hizb 44 » / « الحزب ٤٤ » / « Hizb 44 ».
String mushafHizbLabel(BuildContext context, int hizb) =>
    context.l10n.mushafHizbNumber(mushafNumber(context, hizb));

/// « Page 407 » / « صفحة ٤٠٧ ».
String mushafPageLabel(BuildContext context, int page) =>
    context.l10n.mushafPageNumber(mushafNumber(context, page));

/// Pastille du header : « ۞ Hizb 44 · Page 431 ».
///
/// Le numéro de Hizb est l'information principale — c'est ce que l'utilisateur
/// vient vérifier en arrivant depuis une Khatma ; la page reste secondaire.
class MushafHizbBadge extends StatelessWidget {
  const MushafHizbBadge({
    super.key,
    required this.hizb,
    required this.page,
    this.onTap,
    this.reservedHizb,
    this.insideReservedHizb = true,
    this.onReturnToHizb,
    this.background = AppTheme.cream,
    this.foreground = AppTheme.primaryGreen,
    this.glyphColor = AppTheme.accentGold,
  });

  final int hizb;
  final int page;
  final VoidCallback? onTap;

  /// Hizb ouvert depuis une Khatma. N'ajoute aucune hauteur au header :
  /// le contexte tient dans la pastille existante.
  final int? reservedHizb;
  final bool insideReservedHizb;
  final VoidCallback? onReturnToHizb;

  final Color background;
  final Color foreground;
  final Color glyphColor;

  @override
  Widget build(BuildContext context) {
    final hizbLabel = mushafHizbLabel(context, hizb);
    final pageLabel = mushafPageLabel(context, page);
    final l10n = context.l10n;
    final fromKhatma = reservedHizb != null;
    final leftReserved = fromKhatma && !insideReservedHizb;
    final semantics = fromKhatma
        ? (insideReservedHizb
            ? '${l10n.mushafKhatmaHizbContext(mushafNumber(context, reservedHizb!))}, $pageLabel'
            : l10n.mushafKhatmaHizbLeft(mushafNumber(context, reservedHizb!)))
        : '$hizbLabel, $pageLabel';
    final textColor = leftReserved ? AppTheme.accentGold : foreground;
    final tap = leftReserved ? onReturnToHizb : onTap;

    return Semantics(
      button: tap != null,
      label: semantics,
      child: GestureDetector(
        onTap: tap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Directionality(
            textDirection: _uiDirection(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leftReserved) ...[
                  Icon(
                    Icons.undo_rounded,
                    size: 13,
                    color: textColor,
                  ),
                  const SizedBox(width: 4),
                ] else if (fromKhatma) ...[
                  Icon(
                    Icons.menu_book_rounded,
                    size: 13,
                    color: glyphColor,
                  ),
                  const SizedBox(width: 4),
                ] else
                  Text(
                    kRubElHizbGlyph,
                    style: TextStyle(fontSize: 12, color: glyphColor),
                  ),
                if (!fromKhatma) const SizedBox(width: 6),
                Text(
                  hizbLabel,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '  ·  ',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.45),
                  ),
                ),
                Text(
                  pageLabel,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    color: textColor.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
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

/// Bandeau fin sous le header, affiché uniquement quand le Mushaf est ouvert
/// depuis un Hizb réservé. Il maintient le contexte de la Khatma et signale la
/// sortie du Hizb, cas où la pastille suit la page et non plus la réservation.
class MushafHizbContextBar extends StatelessWidget
    implements PreferredSizeWidget {
  const MushafHizbContextBar({
    super.key,
    required this.reservedHizb,
    required this.insideReservedHizb,
    this.onReturnToHizb,
    this.foreground = AppTheme.cream,
    this.alertColor = AppTheme.accentGold,
  });

  final int reservedHizb;

  /// Faux quand la page courante est sortie du Hizb réservé.
  final bool insideReservedHizb;

  final VoidCallback? onReturnToHizb;
  final Color foreground;
  final Color alertColor;

  static const double _height = 28;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final number = mushafNumber(context, reservedHizb);
    final color = insideReservedHizb ? foreground : alertColor;
    final label = insideReservedHizb
        ? l10n.mushafKhatmaHizbContext(number)
        : l10n.mushafKhatmaHizbLeft(number);

    return GestureDetector(
      onTap: insideReservedHizb ? null : onReturnToHizb,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: _height,
        width: double.infinity,
        color: Colors.black.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: Directionality(
          textDirection: _uiDirection(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                insideReservedHizb
                    ? Icons.menu_book_rounded
                    : Icons.undo_rounded,
                size: 13,
                color: color.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    height: 1.1,
                    color: color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
