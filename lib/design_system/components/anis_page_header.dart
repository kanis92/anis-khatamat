import 'package:flutter/material.dart';

import '../anis_theme.dart';
import '../tokens/anis_geometry.dart';
import 'anis_signature_mark.dart';

/// En-tête de page ANIS.
///
/// Rupture assumée avec l'ancien en-tête : plus de dégradé vert plein sur toute
/// la largeur. La direction artistique est lumineuse, donc l'en-tête vit sur le
/// fond ivoire et se sépare du contenu par un simple trait. Le vert redevient
/// ce qu'il doit être — une couleur d'action et d'information, pas un décor.
///
/// L'en-tête absorbe l'encoche via [SafeArea] et ne fixe aucune hauteur : il
/// grandit avec l'échelle de texte au lieu de tronquer.
class AnisPageHeader extends StatelessWidget {
  const AnisPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.leading,
    this.actions = const [],
    this.showSignature = true,
    this.bottom,
  });

  /// Ligne dominante : nom de l'utilisateur, titre de l'écran.
  final String title;

  /// Ligne de contexte au-dessus du titre (salutation, section).
  final String? eyebrow;

  /// Élément de tête — avatar, bouton retour.
  final Widget? leading;

  /// Actions de fin de ligne. Chacune doit être une [AnisIconAction].
  final List<Widget> actions;

  /// Marque de signature ۞ à côté du titre.
  ///
  /// Une seule occurrence par écran : c'est l'ancrage d'identité, pas un motif.
  final bool showSignature;

  /// Contenu additionnel sous la ligne de titre, dans le même bloc d'en-tête.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;
    final largeText = _isLargeAccessibilityText(context);
    final extremeText = _isExtremeAccessibilityText(context);
    final titleStyle = extremeText ? text.sectionTitle : text.title;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        border: BorderDirectional(
          bottom: BorderSide(color: colors.borderSubtle),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            AnisSpacing.page,
            extremeText ? AnisSpacing.sm : AnisSpacing.md,
            AnisSpacing.page,
            extremeText ? AnisSpacing.md : AnisSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AnisSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eyebrow != null)
                          Text(
                            eyebrow!,
                            style: text.bodySecondary,
                            maxLines: extremeText ? 2 : (largeText ? 3 : 1),
                            overflow:
                                largeText
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        if (largeText)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: titleStyle,
                                softWrap: true,
                                maxLines: extremeText ? 2 : 3,
                                overflow: TextOverflow.visible,
                              ),
                              if (showSignature) ...[
                                SizedBox(
                                  height:
                                      extremeText
                                          ? AnisSpacing.xs
                                          : AnisSpacing.sm,
                                ),
                                const AnisSignatureMark(
                                  role: AnisSignatureRole.brand,
                                ),
                              ],
                            ],
                          )
                        else
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: titleStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (showSignature) ...[
                                const SizedBox(width: AnisSpacing.sm),
                                const AnisSignatureMark(
                                  role: AnisSignatureRole.brand,
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                  ...actions,
                ],
              ),
              if (bottom != null) ...[
                SizedBox(height: extremeText ? AnisSpacing.md : AnisSpacing.lg),
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

bool _isLargeAccessibilityText(BuildContext context) {
  return MediaQuery.textScalerOf(context).scale(12) >= 15;
}

/// Palier « accessibility-extra-extra-large » et au-delà : le titre passe en
/// [AnisTypography.sectionTitle] pour conserver la hiérarchie sans saturer
/// la hauteur d'en-tête. L'échelle système reste active.
bool _isExtremeAccessibilityText(BuildContext context) {
  return MediaQuery.textScalerOf(context).scale(12) >= 20;
}

/// Pastille d'identité de l'utilisateur.
///
/// N'affiche que ce que l'application connaît réellement : une initiale issue
/// de l'identité Firebase. Aucun nom, aucune image, aucune valeur de repli
/// inventée.
class AnisAvatar extends StatelessWidget {
  const AnisAvatar({
    super.key,
    required this.initial,
    this.diameter = 40,
    this.semanticLabel,
  });

  final String initial;
  final double diameter;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;

    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.actionPrimary,
        ),
        alignment: Alignment.center,
        child: ExcludeSemantics(
          child: Text(
            initial,
            style: text.label.copyWith(color: colors.textOnAction),
            textScaler: TextScaler.noScaling,
          ),
        ),
      ),
    );
  }
}
