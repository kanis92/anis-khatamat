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
          padding: const EdgeInsetsDirectional.fromSTEB(
            AnisSpacing.page,
            AnisSpacing.md,
            AnisSpacing.page,
            AnisSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: text.title,
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
                const SizedBox(height: AnisSpacing.lg),
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }
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
