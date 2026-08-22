import 'package:flutter/material.dart';

import '../../core/widgets/anis_icon.dart';
import '../anis_theme.dart';
import '../tokens/anis_geometry.dart';

/// Abstraction d'icône du design system.
///
/// L'application fait cohabiter trois familles d'icônes : 149 icônes Material
/// distinctes, 51 icônes Lucide et 12 SVG propriétaires. DS-01 ne remplace pas
/// cet inventaire — ce serait un chantier à lui seul — mais impose un point de
/// passage unique.
///
/// Règles portées ici :
///
/// - **Taille** : uniquement les paliers d'[AnisIconSize].
/// - **Couleur** : toujours explicite, jamais héritée d'un `IconTheme` inconnu.
/// - **Direction** : [mirrorInRtl] pour les icônes directionnelles.
/// - **Désactivé** : une seule couleur d'état désactivé pour tout le système.
/// - **Sémantique** : décoratif par défaut, car le texte adjacent porte le sens.
///
/// Le SVG propriétaire est privilégié quand il existe ; Material reste toléré
/// derrière cette abstraction, ce qui permettra de basculer une icône sans
/// toucher aux écrans.
class AnisGlyph extends StatelessWidget {
  /// Icône propriétaire ANIS (SVG).
  const AnisGlyph.anis(
    AnisIconType this.anisType, {
    super.key,
    this.size = AnisIconSize.md,
    this.color,
    this.disabled = false,
    this.semanticLabel,
  })  : materialIcon = null,
        mirrorInRtl = false;

  /// Icône Material, en attente de son équivalent propriétaire.
  const AnisGlyph.material(
    IconData this.materialIcon, {
    super.key,
    this.size = AnisIconSize.md,
    this.color,
    this.disabled = false,
    this.mirrorInRtl = false,
    this.semanticLabel,
  }) : anisType = null;

  final AnisIconType? anisType;
  final IconData? materialIcon;
  final double size;
  final Color? color;
  final bool disabled;
  final bool mirrorInRtl;

  /// À ne renseigner que si l'icône porte seule l'information.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final resolved = disabled
        ? colors.actionDisabledText
        : (color ?? colors.textSecondary);

    final Widget glyph = AnisMirrorInRtl(
      enabled: mirrorInRtl,
      child: anisType != null
          ? AnisIcon(type: anisType!, size: size, color: resolved)
          : Icon(materialIcon, size: size, color: resolved),
    );

    if (semanticLabel != null) {
      return Semantics(label: semanticLabel, image: true, child: glyph);
    }
    return ExcludeSemantics(child: glyph);
  }
}

/// Retourne son enfant horizontalement en lecture de droite à gauche.
///
/// `Icon` ne prend pas de paramètre de miroir : seules les `IconData` qui
/// déclarent elles-mêmes `matchTextDirection` sont retournées, ce qui est
/// inégal d'une icône Material à l'autre et donc impossible à garantir. Un
/// miroir explicite rend le comportement identique pour toutes les icônes
/// directionnelles du système.
class AnisMirrorInRtl extends StatelessWidget {
  const AnisMirrorInRtl({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled || Directionality.of(context) != TextDirection.rtl) {
      return child;
    }
    return Transform.scale(scaleX: -1, child: child);
  }
}
