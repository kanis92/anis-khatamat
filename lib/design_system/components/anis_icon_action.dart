import 'package:flutter/material.dart';

import '../../core/widgets/anis_icon.dart';
import '../anis_theme.dart';
import '../tokens/anis_effects.dart';
import '../tokens/anis_geometry.dart';
import 'anis_glyph.dart';

/// Bouton composé d'une icône seule.
///
/// L'audit relevait 24 `IconButton` sur 55 sans aucune description. Ce
/// composant rend l'omission impossible : [tooltip] est requis et sert aussi
/// de libellé sémantique. La cible tactile est verrouillée à 48 dp, quelle que
/// soit la taille de l'icône.
class AnisIconAction extends StatelessWidget {
  const AnisIconAction({
    super.key,
    required IconData this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = AnisIconSize.lg,
    this.tone = AnisIconActionTone.plain,
    this.mirrorInRtl = false,
    this.badge = false,
  }) : anisIcon = null;

  /// Variante portant une icône propriétaire ANIS.
  const AnisIconAction.anis({
    super.key,
    required AnisIconType this.anisIcon,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = AnisIconSize.lg,
    this.tone = AnisIconActionTone.plain,
    this.badge = false,
  })  : icon = null,
        mirrorInRtl = false;

  final IconData? icon;
  final AnisIconType? anisIcon;

  /// Description de l'action. Sert d'infobulle **et** de libellé pour un
  /// lecteur d'écran : jamais optionnel.
  final String tooltip;

  final VoidCallback? onPressed;
  final double iconSize;
  final AnisIconActionTone tone;

  /// À activer pour les icônes directionnelles (retour, chevrons).
  ///
  /// L'audit comptait 44 icônes directionnelles rendues en LTR même en locale
  /// arabe. `matchTextDirection` demande un `Directionality` ancêtre, garanti
  /// ici par `MaterialApp`.
  final bool mirrorInRtl;

  /// Point de notification. Purement visuel : l'information doit aussi être
  /// portée par [tooltip].
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;

    final Color background;
    final Color foreground;
    switch (tone) {
      case AnisIconActionTone.plain:
        background = Colors.transparent;
        foreground = colors.textSecondary;
        break;
      case AnisIconActionTone.soft:
        background = colors.surfaceSoft;
        foreground = colors.actionPrimary;
        break;
      case AnisIconActionTone.accent:
        background =
            colors.actionPrimary.withValues(alpha: AnisOpacity.subtleFill);
        foreground = colors.actionPrimary;
        break;
    }

    final tint =
        onPressed == null ? colors.actionDisabledText : foreground;

    Widget glyph = AnisMirrorInRtl(
      enabled: mirrorInRtl,
      child: anisIcon != null
          ? AnisIcon(type: anisIcon!, size: iconSize, color: tint)
          : Icon(icon, size: iconSize, color: tint),
    );

    if (badge) {
      glyph = Stack(
        clipBehavior: Clip.none,
        children: [
          glyph,
          PositionedDirectional(
            end: -1,
            top: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.accentGoldStrong,
                border: Border.all(color: colors.surfaceElevated, width: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        button: true,
        enabled: onPressed != null,
        child: InkWell(
          onTap: onPressed,
          customBorder: RoundedRectangleBorder(borderRadius: AnisRadius.mdAll),
          child: Container(
            constraints: const BoxConstraints(
              minWidth: AnisIconSize.minTapTarget,
              minHeight: AnisIconSize.minTapTarget,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: AnisRadius.mdAll,
            ),
            alignment: Alignment.center,
            child: ExcludeSemantics(child: glyph),
          ),
        ),
      ),
    );
  }
}

/// Traitement de surface d'une action icône.
enum AnisIconActionTone {
  /// Sans fond — barre d'en-tête, ligne de liste.
  plain,

  /// Fond menthe légère — action mise en avant discrètement.
  soft,

  /// Fond vert très transparent — action principale de l'en-tête.
  accent,
}
