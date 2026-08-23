import 'package:flutter/material.dart';

import '../anis_theme.dart';
import '../tokens/anis_effects.dart';
import '../tokens/anis_geometry.dart';
import '../tokens/anis_motion.dart';

/// Niveau de relief d'une surface ANIS.
enum AnisSurfaceLevel {
  /// Aucun relief : le trait seul sépare la surface du fond.
  flat,

  /// Élément posé — tuiles, lignes de liste.
  subtle,

  /// Carte standard.
  soft,

  /// Carte principale d'un écran.
  raised,
}

/// Teinte de fond d'une surface ANIS.
enum AnisSurfaceTone {
  /// Blanc : le cas courant, sur fond ivoire.
  elevated,

  /// Menthe très légère : profondeur, zone de progression.
  soft,

  /// Ivoire creusé : zone en retrait.
  sunken,

  /// Vert profond : bloc plein, à utiliser avec parcimonie.
  inverse,
}

/// Conteneur de base du design system : la brique dont toutes les cartes,
/// tuiles et blocs de l'application dérivent.
///
/// Remplace les 175 `Card` et 178 `Container` décorés à la main relevés par
/// l'audit. Un écran ne définit plus ni couleur de fond, ni rayon, ni ombre,
/// ni bordure : il choisit un [tone] et un [level].
class AnisSurface extends StatelessWidget {
  const AnisSurface({
    super.key,
    required this.child,
    this.tone = AnisSurfaceTone.elevated,
    this.level = AnisSurfaceLevel.soft,
    this.radius = AnisRadius.lg,
    this.padding = const EdgeInsetsDirectional.all(AnisSpacing.xl),
    this.onTap,
    this.semanticLabel,
    this.semanticButton,
    this.borderColor,
    this.borderWidth = AnisBorder.hairline,
    this.showBorder = true,
    this.backgroundColor,
  });

  final Widget child;
  final AnisSurfaceTone tone;
  final AnisSurfaceLevel level;
  final double radius;

  /// Directionnel par défaut : le padding suit la direction de lecture.
  final EdgeInsetsGeometry padding;

  final VoidCallback? onTap;

  /// Libellé annoncé quand la surface est interactive. Requis dès que [onTap]
  /// est fourni et que le contenu n'est pas déjà auto-descriptif.
  final String? semanticLabel;

  /// Force l'annonce « bouton ». Par défaut, vrai dès que [onTap] existe.
  final bool? semanticButton;

  final Color? borderColor;
  final double borderWidth;
  final bool showBorder;

  /// Fond explicite, pour les surfaces porteuses d'un état ([AnisNotice], états
  /// Hizb). À n'utiliser qu'avec une couleur issue des tokens.
  final Color? backgroundColor;

  Color _background(BuildContext context) {
    if (backgroundColor != null) return backgroundColor!;
    final c = context.anisColors;
    switch (tone) {
      case AnisSurfaceTone.elevated:
        return c.surfaceElevated;
      case AnisSurfaceTone.soft:
        return c.surfaceSoft;
      case AnisSurfaceTone.sunken:
        return c.surfaceSunken;
      case AnisSurfaceTone.inverse:
        return c.surfaceInverse;
    }
  }

  List<BoxShadow> _shadow(BuildContext context) {
    final shadow = context.anisColors.shadow;
    switch (level) {
      case AnisSurfaceLevel.flat:
        return AnisElevation.none;
      case AnisSurfaceLevel.subtle:
        return AnisElevation.subtle(shadow);
      case AnisSurfaceLevel.soft:
        return AnisElevation.soft(shadow);
      case AnisSurfaceLevel.raised:
        return AnisElevation.raised(shadow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final borderRadius = BorderRadius.circular(radius);
    final side = showBorder && tone != AnisSurfaceTone.inverse
        ? BorderSide(
            color: borderColor ?? colors.borderSubtle,
            width: borderWidth,
          )
        : BorderSide.none;

    Widget content = Padding(padding: padding, child: child);

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashFactory: NoSplash.splashFactory,
        highlightColor:
            colors.actionPrimary.withValues(alpha: AnisOpacity.hover),
        child: content,
      );
    }

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: _shadow(context),
      ),
      child: Material(
        color: _background(context),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: side,
        ),
        clipBehavior: Clip.antiAlias,
        animationDuration: AnisMotion.durationOf(context, AnisMotion.fast),
        child: content,
      ),
    );

    if (semanticLabel != null || onTap != null) {
      surface = Semantics(
        label: semanticLabel,
        button: semanticButton ?? (onTap != null),
        container: true,
        child: surface,
      );
    }

    return surface;
  }
}
