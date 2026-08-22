import 'package:flutter/material.dart';

/// Rampes brutes — source unique des valeurs hexadécimales du produit.
///
/// Ces constantes ne doivent jamais être consommées directement par un écran :
/// elles n'existent que pour alimenter [AnisColors], qui porte le sens.
/// Un écran qui lit `_AnisPalette` court-circuite la sémantique et casse le
/// futur mode sombre.
class AnisPalette {
  AnisPalette._();

  // ── Neutres chauds (fond ivoire) ────────────────────────────────────────
  /// Reprend `AppTheme.creamLight` pour éviter toute rupture avec les écrans
  /// non encore migrés.
  static const Color ivory = Color(0xFFFAF8F5);
  static const Color ivoryDeep = Color(0xFFF3EFE9);
  static const Color white = Color(0xFFFFFFFF);

  // ── Menthe (profondeur, progression) ────────────────────────────────────
  static const Color mint50 = Color(0xFFF2F8F5);
  static const Color mint100 = Color(0xFFE6F1EB);
  static const Color mint200 = Color(0xFFD3E7DE);
  static const Color mint300 = Color(0xFFB5D6C8);

  // ── Vert ANIS ───────────────────────────────────────────────────────────
  static const Color green900 = Color(0xFF0A3327);
  static const Color green800 = Color(0xFF0B4535);

  /// Vert de la charte graphique ANIS.
  static const Color green700 = Color(0xFF0E5E46);
  static const Color green600 = Color(0xFF16745A);
  static const Color green100 = Color(0xFFDCEFE6);

  // ── Or / champagne ──────────────────────────────────────────────────────
  /// Or de la charte. Contraste 1,96:1 sur ivoire — décoratif uniquement,
  /// jamais pour du texte ou une icône porteuse de sens.
  static const Color gold500 = Color(0xFFD4AF37);
  static const Color gold700 = Color(0xFFA8842A);

  /// Or assombri pour texte et icônes : 6,49:1 sur ivoire (AA).
  static const Color gold900 = Color(0xFF6E5518);
  static const Color gold100 = Color(0xFFF6EDD6);
  static const Color gold50 = Color(0xFFFCF7EA);

  // ── Encres et traits ────────────────────────────────────────────────────
  /// 14,1:1 sur ivoire.
  static const Color ink900 = Color(0xFF16281F);

  /// 5,64:1 sur ivoire (AA texte courant).
  static const Color ink600 = Color(0xFF55665E);

  /// 3,28:1 sur ivoire — grand texte et éléments décoratifs uniquement.
  static const Color ink400 = Color(0xFF7C8C84);
  static const Color line200 = Color(0xFFE7EDE9);
  static const Color line300 = Color(0xFFD6E0DB);

  // ── Retours d'état ──────────────────────────────────────────────────────
  static const Color dangerText = Color(0xFF8A2E24);
  static const Color dangerSurface = Color(0xFFFBECE9);
  static const Color dangerBorder = Color(0xFFF0D2CC);

  // ── Neutres sombres (préparation dark mode, non validé DA) ──────────────
  static const Color darkBase = Color(0xFF0D1A15);
  static const Color darkElevated = Color(0xFF132520);
  static const Color darkSoft = Color(0xFF17302A);
  static const Color darkLine = Color(0xFF244038);
  static const Color darkInk50 = Color(0xFFE8F0EC);
  static const Color darkInk300 = Color(0xFFA9BBB2);
  static const Color darkInk500 = Color(0xFF7F958B);
  static const Color darkGreen = Color(0xFF2E9B77);
}

/// Tokens de couleur **sémantiques** du design system ANIS.
///
/// Un composant demande `actionPrimary`, jamais « le vert 700 ». C'est ce qui
/// rend le futur mode sombre possible sans réécrire les écrans : seule la
/// fabrique [AnisColors.dark] change.
@immutable
class AnisColors extends ThemeExtension<AnisColors> {
  const AnisColors({
    required this.brightness,
    required this.surfaceBase,
    required this.surfaceElevated,
    required this.surfaceSoft,
    required this.surfaceSunken,
    required this.surfaceInverse,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnAction,
    required this.textOnInverse,
    required this.actionPrimary,
    required this.actionPrimaryPressed,
    required this.actionSecondarySurface,
    required this.actionSecondaryText,
    required this.actionSecondaryBorder,
    required this.actionDisabledSurface,
    required this.actionDisabledText,
    required this.accentGold,
    required this.accentGoldStrong,
    required this.accentGoldText,
    required this.accentGoldSurface,
    required this.borderSubtle,
    required this.borderStrong,
    required this.borderFocus,
    required this.divider,
    required this.progressTrack,
    required this.progressActive,
    required this.progressCompleted,
    required this.progressTip,
    required this.hizbAvailableSurface,
    required this.hizbAvailableBorder,
    required this.hizbAvailableText,
    required this.hizbPendingSurface,
    required this.hizbPendingBorder,
    required this.hizbPendingText,
    required this.hizbReservedSurface,
    required this.hizbReservedBorder,
    required this.hizbReservedText,
    required this.hizbMineSurface,
    required this.hizbMineBorder,
    required this.hizbMineText,
    required this.hizbInProgressSurface,
    required this.hizbInProgressBorder,
    required this.hizbInProgressText,
    required this.hizbCompletedSurface,
    required this.hizbCompletedBorder,
    required this.hizbCompletedText,
    required this.noticeSurface,
    required this.noticeBorder,
    required this.noticeText,
    required this.dangerSurface,
    required this.dangerBorder,
    required this.dangerText,
    required this.shadow,
    required this.scrim,
  });

  final Brightness brightness;

  // ── Surfaces ────────────────────────────────────────────────────────────
  /// Fond d'écran : ivoire chaud.
  final Color surfaceBase;

  /// Cartes et blocs posés sur [surfaceBase].
  final Color surfaceElevated;

  /// Menthe très légère — profondeur, zones de progression, remplissages doux.
  final Color surfaceSoft;

  /// Creux : champs, pistes, séparations de zone.
  final Color surfaceSunken;

  /// Vert profond, pour les rares blocs pleins.
  final Color surfaceInverse;

  // ── Texte ───────────────────────────────────────────────────────────────
  final Color textPrimary;
  final Color textSecondary;

  /// Contraste ~3:1 : réservé au grand texte et au décoratif.
  final Color textTertiary;
  final Color textOnAction;
  final Color textOnInverse;

  // ── Actions ─────────────────────────────────────────────────────────────
  final Color actionPrimary;
  final Color actionPrimaryPressed;
  final Color actionSecondarySurface;
  final Color actionSecondaryText;
  final Color actionSecondaryBorder;
  final Color actionDisabledSurface;
  final Color actionDisabledText;

  // ── Or : accent précieux ────────────────────────────────────────────────
  /// Décoratif uniquement (traits, glyphes ornementaux, pointes de progression).
  final Color accentGold;
  final Color accentGoldStrong;

  /// Variante contrastée, seule autorisée pour du texte ou une icône signifiante.
  final Color accentGoldText;
  final Color accentGoldSurface;

  // ── Traits ──────────────────────────────────────────────────────────────
  final Color borderSubtle;
  final Color borderStrong;
  final Color borderFocus;
  final Color divider;

  // ── Progression ─────────────────────────────────────────────────────────
  final Color progressTrack;
  final Color progressActive;
  final Color progressCompleted;

  /// Pointe de l'arc : accent précieux au bout du parcours.
  final Color progressTip;

  // ── États Hizb ──────────────────────────────────────────────────────────
  //
  // Les six états sont distingués par la **valeur** (clair → plein) et non par
  // la seule teinte, afin qu'ils restent discernables. `mine` et `completed`
  // partagent la famille verte mais s'opposent en remplissage : menthe claire
  // bordée de vert contre vert plein. Ces tokens sont posés pour DS-02 et ne
  // sont encore appliqués nulle part.
  final Color hizbAvailableSurface;
  final Color hizbAvailableBorder;
  final Color hizbAvailableText;

  /// Verrou temporaire (soft lock).
  final Color hizbPendingSurface;
  final Color hizbPendingBorder;
  final Color hizbPendingText;

  /// Réservé par quelqu'un d'autre.
  final Color hizbReservedSurface;
  final Color hizbReservedBorder;
  final Color hizbReservedText;

  /// Réservé par moi.
  final Color hizbMineSurface;
  final Color hizbMineBorder;
  final Color hizbMineText;

  /// Lecture en cours.
  final Color hizbInProgressSurface;
  final Color hizbInProgressBorder;
  final Color hizbInProgressText;

  /// Terminé.
  final Color hizbCompletedSurface;
  final Color hizbCompletedBorder;
  final Color hizbCompletedText;

  // ── Retours d'état ──────────────────────────────────────────────────────
  /// Information calme (hors ligne, contexte) — famille champagne plutôt que
  /// l'orange Material, qui jure avec la direction artistique.
  final Color noticeSurface;
  final Color noticeBorder;
  final Color noticeText;

  final Color dangerSurface;
  final Color dangerBorder;
  final Color dangerText;

  final Color shadow;
  final Color scrim;

  /// Palette claire — la seule validée par la direction artistique.
  factory AnisColors.light() => const AnisColors(
        brightness: Brightness.light,
        surfaceBase: AnisPalette.ivory,
        surfaceElevated: AnisPalette.white,
        surfaceSoft: AnisPalette.mint50,
        surfaceSunken: AnisPalette.ivoryDeep,
        surfaceInverse: AnisPalette.green800,
        textPrimary: AnisPalette.ink900,
        textSecondary: AnisPalette.ink600,
        textTertiary: AnisPalette.ink400,
        textOnAction: AnisPalette.white,
        textOnInverse: AnisPalette.white,
        actionPrimary: AnisPalette.green700,
        actionPrimaryPressed: AnisPalette.green800,
        actionSecondarySurface: AnisPalette.mint100,
        actionSecondaryText: AnisPalette.green700,
        actionSecondaryBorder: AnisPalette.mint200,
        actionDisabledSurface: AnisPalette.ivoryDeep,
        actionDisabledText: AnisPalette.ink400,
        accentGold: AnisPalette.gold500,
        accentGoldStrong: AnisPalette.gold700,
        accentGoldText: AnisPalette.gold900,
        accentGoldSurface: AnisPalette.gold50,
        borderSubtle: AnisPalette.line200,
        borderStrong: AnisPalette.line300,
        borderFocus: AnisPalette.green600,
        divider: AnisPalette.line200,
        progressTrack: AnisPalette.mint200,
        progressActive: AnisPalette.green700,
        progressCompleted: AnisPalette.green600,
        progressTip: AnisPalette.gold500,
        hizbAvailableSurface: AnisPalette.ivoryDeep,
        hizbAvailableBorder: AnisPalette.line200,
        hizbAvailableText: AnisPalette.ink600,
        hizbPendingSurface: AnisPalette.gold50,
        hizbPendingBorder: AnisPalette.gold100,
        hizbPendingText: AnisPalette.gold900,
        hizbReservedSurface: AnisPalette.gold100,
        hizbReservedBorder: AnisPalette.gold700,
        hizbReservedText: AnisPalette.gold900,
        hizbMineSurface: AnisPalette.mint100,
        hizbMineBorder: AnisPalette.green700,
        hizbMineText: AnisPalette.green800,
        hizbInProgressSurface: AnisPalette.mint200,
        hizbInProgressBorder: AnisPalette.gold700,
        hizbInProgressText: AnisPalette.green900,
        hizbCompletedSurface: AnisPalette.green700,
        hizbCompletedBorder: AnisPalette.green800,
        hizbCompletedText: AnisPalette.white,
        noticeSurface: AnisPalette.gold50,
        noticeBorder: AnisPalette.gold100,
        noticeText: AnisPalette.gold900,
        dangerSurface: AnisPalette.dangerSurface,
        dangerBorder: AnisPalette.dangerBorder,
        dangerText: AnisPalette.dangerText,
        shadow: AnisPalette.green900,
        scrim: AnisPalette.green900,
      );

  /// Palette sombre **provisoire**.
  ///
  /// DS-01 est un sprint clair : cette fabrique existe pour prouver que
  /// l'architecture supporte le mode sombre, pas pour livrer une direction
  /// artistique sombre. Elle sera retravaillée quand le dark sera cadré.
  factory AnisColors.dark() => const AnisColors(
        brightness: Brightness.dark,
        surfaceBase: AnisPalette.darkBase,
        surfaceElevated: AnisPalette.darkElevated,
        surfaceSoft: AnisPalette.darkSoft,
        surfaceSunken: AnisPalette.darkBase,
        surfaceInverse: AnisPalette.mint100,
        textPrimary: AnisPalette.darkInk50,
        textSecondary: AnisPalette.darkInk300,
        textTertiary: AnisPalette.darkInk500,
        textOnAction: AnisPalette.darkBase,
        textOnInverse: AnisPalette.green900,
        actionPrimary: AnisPalette.darkGreen,
        actionPrimaryPressed: AnisPalette.green600,
        actionSecondarySurface: AnisPalette.darkSoft,
        actionSecondaryText: AnisPalette.darkGreen,
        actionSecondaryBorder: AnisPalette.darkLine,
        actionDisabledSurface: AnisPalette.darkSoft,
        actionDisabledText: AnisPalette.darkInk500,
        accentGold: AnisPalette.gold500,
        accentGoldStrong: AnisPalette.gold500,
        accentGoldText: AnisPalette.gold500,
        accentGoldSurface: AnisPalette.darkSoft,
        borderSubtle: AnisPalette.darkLine,
        borderStrong: AnisPalette.darkLine,
        borderFocus: AnisPalette.darkGreen,
        divider: AnisPalette.darkLine,
        progressTrack: AnisPalette.darkLine,
        progressActive: AnisPalette.darkGreen,
        progressCompleted: AnisPalette.darkGreen,
        progressTip: AnisPalette.gold500,
        hizbAvailableSurface: AnisPalette.darkSoft,
        hizbAvailableBorder: AnisPalette.darkLine,
        hizbAvailableText: AnisPalette.darkInk300,
        hizbPendingSurface: AnisPalette.darkSoft,
        hizbPendingBorder: AnisPalette.gold700,
        hizbPendingText: AnisPalette.gold500,
        hizbReservedSurface: AnisPalette.darkSoft,
        hizbReservedBorder: AnisPalette.gold500,
        hizbReservedText: AnisPalette.gold500,
        hizbMineSurface: AnisPalette.darkSoft,
        hizbMineBorder: AnisPalette.darkGreen,
        hizbMineText: AnisPalette.darkInk50,
        hizbInProgressSurface: AnisPalette.darkLine,
        hizbInProgressBorder: AnisPalette.gold500,
        hizbInProgressText: AnisPalette.darkInk50,
        hizbCompletedSurface: AnisPalette.darkGreen,
        hizbCompletedBorder: AnisPalette.green600,
        hizbCompletedText: AnisPalette.darkBase,
        noticeSurface: AnisPalette.darkSoft,
        noticeBorder: AnisPalette.gold700,
        noticeText: AnisPalette.gold500,
        dangerSurface: AnisPalette.darkSoft,
        dangerBorder: AnisPalette.dangerBorder,
        dangerText: AnisPalette.dangerBorder,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
      );

  /// Lecture depuis le thème, avec repli sur la palette claire.
  ///
  /// Le repli garantit qu'un composant DS reste utilisable dans un
  /// `MaterialApp` nu — cas des tests de widget isolés.
  static AnisColors of(BuildContext context) =>
      Theme.of(context).extension<AnisColors>() ?? AnisColors.light();

  @override
  AnisColors copyWith({
    Brightness? brightness,
    Color? surfaceBase,
    Color? surfaceElevated,
    Color? surfaceSoft,
    Color? surfaceSunken,
    Color? surfaceInverse,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textOnAction,
    Color? textOnInverse,
    Color? actionPrimary,
    Color? actionPrimaryPressed,
    Color? actionSecondarySurface,
    Color? actionSecondaryText,
    Color? actionSecondaryBorder,
    Color? actionDisabledSurface,
    Color? actionDisabledText,
    Color? accentGold,
    Color? accentGoldStrong,
    Color? accentGoldText,
    Color? accentGoldSurface,
    Color? borderSubtle,
    Color? borderStrong,
    Color? borderFocus,
    Color? divider,
    Color? progressTrack,
    Color? progressActive,
    Color? progressCompleted,
    Color? progressTip,
    Color? hizbAvailableSurface,
    Color? hizbAvailableBorder,
    Color? hizbAvailableText,
    Color? hizbPendingSurface,
    Color? hizbPendingBorder,
    Color? hizbPendingText,
    Color? hizbReservedSurface,
    Color? hizbReservedBorder,
    Color? hizbReservedText,
    Color? hizbMineSurface,
    Color? hizbMineBorder,
    Color? hizbMineText,
    Color? hizbInProgressSurface,
    Color? hizbInProgressBorder,
    Color? hizbInProgressText,
    Color? hizbCompletedSurface,
    Color? hizbCompletedBorder,
    Color? hizbCompletedText,
    Color? noticeSurface,
    Color? noticeBorder,
    Color? noticeText,
    Color? dangerSurface,
    Color? dangerBorder,
    Color? dangerText,
    Color? shadow,
    Color? scrim,
  }) {
    return AnisColors(
      brightness: brightness ?? this.brightness,
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      surfaceInverse: surfaceInverse ?? this.surfaceInverse,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textOnAction: textOnAction ?? this.textOnAction,
      textOnInverse: textOnInverse ?? this.textOnInverse,
      actionPrimary: actionPrimary ?? this.actionPrimary,
      actionPrimaryPressed: actionPrimaryPressed ?? this.actionPrimaryPressed,
      actionSecondarySurface:
          actionSecondarySurface ?? this.actionSecondarySurface,
      actionSecondaryText: actionSecondaryText ?? this.actionSecondaryText,
      actionSecondaryBorder:
          actionSecondaryBorder ?? this.actionSecondaryBorder,
      actionDisabledSurface:
          actionDisabledSurface ?? this.actionDisabledSurface,
      actionDisabledText: actionDisabledText ?? this.actionDisabledText,
      accentGold: accentGold ?? this.accentGold,
      accentGoldStrong: accentGoldStrong ?? this.accentGoldStrong,
      accentGoldText: accentGoldText ?? this.accentGoldText,
      accentGoldSurface: accentGoldSurface ?? this.accentGoldSurface,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      borderFocus: borderFocus ?? this.borderFocus,
      divider: divider ?? this.divider,
      progressTrack: progressTrack ?? this.progressTrack,
      progressActive: progressActive ?? this.progressActive,
      progressCompleted: progressCompleted ?? this.progressCompleted,
      progressTip: progressTip ?? this.progressTip,
      hizbAvailableSurface: hizbAvailableSurface ?? this.hizbAvailableSurface,
      hizbAvailableBorder: hizbAvailableBorder ?? this.hizbAvailableBorder,
      hizbAvailableText: hizbAvailableText ?? this.hizbAvailableText,
      hizbPendingSurface: hizbPendingSurface ?? this.hizbPendingSurface,
      hizbPendingBorder: hizbPendingBorder ?? this.hizbPendingBorder,
      hizbPendingText: hizbPendingText ?? this.hizbPendingText,
      hizbReservedSurface: hizbReservedSurface ?? this.hizbReservedSurface,
      hizbReservedBorder: hizbReservedBorder ?? this.hizbReservedBorder,
      hizbReservedText: hizbReservedText ?? this.hizbReservedText,
      hizbMineSurface: hizbMineSurface ?? this.hizbMineSurface,
      hizbMineBorder: hizbMineBorder ?? this.hizbMineBorder,
      hizbMineText: hizbMineText ?? this.hizbMineText,
      hizbInProgressSurface:
          hizbInProgressSurface ?? this.hizbInProgressSurface,
      hizbInProgressBorder: hizbInProgressBorder ?? this.hizbInProgressBorder,
      hizbInProgressText: hizbInProgressText ?? this.hizbInProgressText,
      hizbCompletedSurface: hizbCompletedSurface ?? this.hizbCompletedSurface,
      hizbCompletedBorder: hizbCompletedBorder ?? this.hizbCompletedBorder,
      hizbCompletedText: hizbCompletedText ?? this.hizbCompletedText,
      noticeSurface: noticeSurface ?? this.noticeSurface,
      noticeBorder: noticeBorder ?? this.noticeBorder,
      noticeText: noticeText ?? this.noticeText,
      dangerSurface: dangerSurface ?? this.dangerSurface,
      dangerBorder: dangerBorder ?? this.dangerBorder,
      dangerText: dangerText ?? this.dangerText,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AnisColors lerp(ThemeExtension<AnisColors>? other, double t) {
    if (other is! AnisColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AnisColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      surfaceBase: c(surfaceBase, other.surfaceBase),
      surfaceElevated: c(surfaceElevated, other.surfaceElevated),
      surfaceSoft: c(surfaceSoft, other.surfaceSoft),
      surfaceSunken: c(surfaceSunken, other.surfaceSunken),
      surfaceInverse: c(surfaceInverse, other.surfaceInverse),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      textOnAction: c(textOnAction, other.textOnAction),
      textOnInverse: c(textOnInverse, other.textOnInverse),
      actionPrimary: c(actionPrimary, other.actionPrimary),
      actionPrimaryPressed: c(actionPrimaryPressed, other.actionPrimaryPressed),
      actionSecondarySurface:
          c(actionSecondarySurface, other.actionSecondarySurface),
      actionSecondaryText: c(actionSecondaryText, other.actionSecondaryText),
      actionSecondaryBorder:
          c(actionSecondaryBorder, other.actionSecondaryBorder),
      actionDisabledSurface:
          c(actionDisabledSurface, other.actionDisabledSurface),
      actionDisabledText: c(actionDisabledText, other.actionDisabledText),
      accentGold: c(accentGold, other.accentGold),
      accentGoldStrong: c(accentGoldStrong, other.accentGoldStrong),
      accentGoldText: c(accentGoldText, other.accentGoldText),
      accentGoldSurface: c(accentGoldSurface, other.accentGoldSurface),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      borderStrong: c(borderStrong, other.borderStrong),
      borderFocus: c(borderFocus, other.borderFocus),
      divider: c(divider, other.divider),
      progressTrack: c(progressTrack, other.progressTrack),
      progressActive: c(progressActive, other.progressActive),
      progressCompleted: c(progressCompleted, other.progressCompleted),
      progressTip: c(progressTip, other.progressTip),
      hizbAvailableSurface: c(hizbAvailableSurface, other.hizbAvailableSurface),
      hizbAvailableBorder: c(hizbAvailableBorder, other.hizbAvailableBorder),
      hizbAvailableText: c(hizbAvailableText, other.hizbAvailableText),
      hizbPendingSurface: c(hizbPendingSurface, other.hizbPendingSurface),
      hizbPendingBorder: c(hizbPendingBorder, other.hizbPendingBorder),
      hizbPendingText: c(hizbPendingText, other.hizbPendingText),
      hizbReservedSurface: c(hizbReservedSurface, other.hizbReservedSurface),
      hizbReservedBorder: c(hizbReservedBorder, other.hizbReservedBorder),
      hizbReservedText: c(hizbReservedText, other.hizbReservedText),
      hizbMineSurface: c(hizbMineSurface, other.hizbMineSurface),
      hizbMineBorder: c(hizbMineBorder, other.hizbMineBorder),
      hizbMineText: c(hizbMineText, other.hizbMineText),
      hizbInProgressSurface:
          c(hizbInProgressSurface, other.hizbInProgressSurface),
      hizbInProgressBorder: c(hizbInProgressBorder, other.hizbInProgressBorder),
      hizbInProgressText: c(hizbInProgressText, other.hizbInProgressText),
      hizbCompletedSurface: c(hizbCompletedSurface, other.hizbCompletedSurface),
      hizbCompletedBorder: c(hizbCompletedBorder, other.hizbCompletedBorder),
      hizbCompletedText: c(hizbCompletedText, other.hizbCompletedText),
      noticeSurface: c(noticeSurface, other.noticeSurface),
      noticeBorder: c(noticeBorder, other.noticeBorder),
      noticeText: c(noticeText, other.noticeText),
      dangerSurface: c(dangerSurface, other.dangerSurface),
      dangerBorder: c(dangerBorder, other.dangerBorder),
      dangerText: c(dangerText, other.dangerText),
      shadow: c(shadow, other.shadow),
      scrim: c(scrim, other.scrim),
    );
  }
}
