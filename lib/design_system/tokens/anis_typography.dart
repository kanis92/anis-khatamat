import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/font_provider.dart';
import 'anis_colors.dart';

/// Résolveur de police : produit un style pour une taille et une graisse.
///
/// Unique point d'injection de la police dans le design system. Il existe pour
/// deux raisons : permettre de changer de fournisseur de police sans toucher à
/// l'échelle typographique, et rendre l'échelle testable sans accès réseau —
/// `google_fonts` télécharge ses fichiers au premier usage.
typedef AnisFontResolver = TextStyle Function({
  required double fontSize,
  required FontWeight fontWeight,
  required Color color,
  required double height,
});

/// Hiérarchie typographique ANIS — Latin et arabe d'interface.
///
/// Trois règles non négociables portées par ce token :
///
/// 1. **Aucun `letterSpacing` non nul.** L'arabe est une écriture liée : le
///    moindre espacement additionnel désolidarise les glyphes. Toutes les
///    valeurs sont forcées à 0 pour neutraliser les valeurs par défaut de
///    Material (`labelSmall` porte 0.5, par exemple).
/// 2. **Interlignes généreux.** L'arabe monte et descend plus que le latin ;
///    un `height` serré tronque les diacritiques.
/// 3. **Ne s'applique jamais au texte coranique.** Le Mushaf conserve la
///    police `hafs` du package `flutter_quran`, sa taille et ses métriques
///    propres. Aucun style de ce fichier ne doit atteindre un `QuranLine`.
@immutable
class AnisTypography extends ThemeExtension<AnisTypography> {
  const AnisTypography({
    required this.display,
    required this.titleLarge,
    required this.title,
    required this.sectionTitle,
    required this.body,
    required this.bodySecondary,
    required this.label,
    required this.caption,
    required this.numberLarge,
    required this.number,
  });

  /// 30 / w700 — accroche d'écran, un seul par vue.
  final TextStyle display;

  /// 24 / w700 — titre de page.
  final TextStyle titleLarge;

  /// 20 / w600 — titre de carte principale.
  final TextStyle title;

  /// 16 / w600 — titre de section.
  final TextStyle sectionTitle;

  /// 15 / w400 — texte courant.
  final TextStyle body;

  /// 14 / w400 — texte courant secondaire.
  final TextStyle bodySecondary;

  /// 13 / w600 — libellé d'action, de badge, de champ.
  final TextStyle label;

  /// 12 / w400 — mention, métadonnée, horodatage.
  final TextStyle caption;

  /// 28 / w700, chiffres tabulaires — valeur de progression dominante.
  final TextStyle numberLarge;

  /// 18 / w700, chiffres tabulaires — valeur de métrique.
  final TextStyle number;

  /// Construit l'échelle depuis la police choisie par l'utilisateur.
  ///
  /// Chaque style est demandé à `google_fonts` avec sa graisse cible plutôt que
  /// dérivé par `copyWith(fontWeight:)`. La distinction est importante :
  /// `google_fonts` enregistre chaque graisse comme une famille distincte, donc
  /// changer la graisse après coup produit un faux gras synthétique au lieu de
  /// charger le vrai fichier de police.
  factory AnisTypography.fromFont(AppFont font, AnisColors colors) =>
      AnisTypography.fromResolver(googleFontResolver(font), colors);

  /// Police de la plateforme, sans famille imposée.
  ///
  /// Sert de repli et de résolveur de test : l'échelle reste identique, seules
  /// les métriques de glyphes changent.
  static TextStyle systemFontResolver({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    required double height,
  }) =>
      TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );

  /// Résolveur adossé à `google_fonts` pour la police [font].
  static AnisFontResolver googleFontResolver(AppFont font) {
    return ({
      required double fontSize,
      required FontWeight fontWeight,
      required Color color,
      required double height,
    }) =>
        switch (font) {
          AppFont.cairo => GoogleFonts.cairo(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
              height: height,
            ),
          AppFont.tajawal => GoogleFonts.tajawal(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
              height: height,
            ),
          AppFont.readexPro => GoogleFonts.readexPro(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
              height: height,
            ),
          AppFont.almarai => GoogleFonts.almarai(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
              height: height,
            ),
        };
  }

  /// Applique l'échelle ANIS au-dessus d'un [AnisFontResolver].
  factory AnisTypography.fromResolver(
    AnisFontResolver resolver,
    AnisColors colors,
  ) {
    TextStyle style({
      required double size,
      required FontWeight weight,
      required double height,
      required Color color,
      bool tabular = false,
    }) {
      return resolver(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      ).copyWith(
        letterSpacing: 0,
        fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
      );
    }

    return AnisTypography(
      display: style(
        size: 30,
        weight: FontWeight.w700,
        height: 1.2,
        color: colors.textPrimary,
      ),
      titleLarge: style(
        size: 24,
        weight: FontWeight.w700,
        height: 1.25,
        color: colors.textPrimary,
      ),
      title: style(
        size: 20,
        weight: FontWeight.w600,
        height: 1.3,
        color: colors.textPrimary,
      ),
      sectionTitle: style(
        size: 16,
        weight: FontWeight.w600,
        height: 1.35,
        color: colors.textPrimary,
      ),
      body: style(
        size: 15,
        weight: FontWeight.w400,
        height: 1.5,
        color: colors.textPrimary,
      ),
      bodySecondary: style(
        size: 14,
        weight: FontWeight.w400,
        height: 1.5,
        color: colors.textSecondary,
      ),
      label: style(
        size: 13,
        weight: FontWeight.w600,
        height: 1.35,
        color: colors.textPrimary,
      ),
      caption: style(
        size: 12,
        weight: FontWeight.w400,
        height: 1.4,
        color: colors.textSecondary,
      ),
      numberLarge: style(
        size: 28,
        weight: FontWeight.w700,
        height: 1.1,
        color: colors.textPrimary,
        tabular: true,
      ),
      number: style(
        size: 18,
        weight: FontWeight.w700,
        height: 1.15,
        color: colors.textPrimary,
        tabular: true,
      ),
    );
  }

  /// Lecture depuis le thème, avec repli sur la police de la plateforme.
  ///
  /// Le repli n'utilise volontairement pas `google_fonts` : un composant rendu
  /// hors du thème de l'application ne doit pas déclencher de téléchargement.
  static AnisTypography of(BuildContext context) =>
      Theme.of(context).extension<AnisTypography>() ??
      AnisTypography.fromResolver(
        AnisTypography.systemFontResolver,
        AnisColors.of(context),
      );

  @override
  AnisTypography copyWith({
    TextStyle? display,
    TextStyle? titleLarge,
    TextStyle? title,
    TextStyle? sectionTitle,
    TextStyle? body,
    TextStyle? bodySecondary,
    TextStyle? label,
    TextStyle? caption,
    TextStyle? numberLarge,
    TextStyle? number,
  }) {
    return AnisTypography(
      display: display ?? this.display,
      titleLarge: titleLarge ?? this.titleLarge,
      title: title ?? this.title,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      body: body ?? this.body,
      bodySecondary: bodySecondary ?? this.bodySecondary,
      label: label ?? this.label,
      caption: caption ?? this.caption,
      numberLarge: numberLarge ?? this.numberLarge,
      number: number ?? this.number,
    );
  }

  @override
  AnisTypography lerp(ThemeExtension<AnisTypography>? other, double t) {
    if (other is! AnisTypography) return this;
    return AnisTypography(
      display: TextStyle.lerp(display, other.display, t)!,
      titleLarge: TextStyle.lerp(titleLarge, other.titleLarge, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      sectionTitle: TextStyle.lerp(sectionTitle, other.sectionTitle, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodySecondary: TextStyle.lerp(bodySecondary, other.bodySecondary, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      numberLarge: TextStyle.lerp(numberLarge, other.numberLarge, t)!,
      number: TextStyle.lerp(number, other.number, t)!,
    );
  }
}
