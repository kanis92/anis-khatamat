import 'package:flutter/material.dart';

import '../anis_theme.dart';
import '../tokens/anis_geometry.dart';
import 'anis_glyph.dart';
import 'anis_surface.dart';

/// Accès rapide — icône au-dessus d'un libellé court.
///
/// Conçu pour tenir dans une rangée de quatre sur un écran de 320 dp : la cible
/// tactile reste garantie à 48 dp de haut et le libellé passe sur deux lignes
/// plutôt que de se tronquer.
class AnisQuickAction extends StatelessWidget {
  const AnisQuickAction({
    super.key,
    required this.glyph,
    required this.label,
    required this.onTap,
  });

  final AnisGlyph glyph;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.anisText;

    return AnisSurface(
      level: AnisSurfaceLevel.subtle,
      radius: AnisRadius.md,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AnisSpacing.sm,
        vertical: AnisSpacing.md,
      ),
      onTap: onTap,
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AnisIconSize.minTapTarget,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExcludeSemantics(child: glyph),
            const SizedBox(height: AnisSpacing.sm),
            ExcludeSemantics(
              child: Text(
                label,
                style: text.caption,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rangée d'accès rapides à largeur égale.
class AnisQuickActionRow extends StatelessWidget {
  const AnisQuickActionRow({super.key, required this.actions});

  final List<AnisQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    // `IntrinsicHeight` aligne la hauteur des quatre tuiles sans qu'aucune ne
    // reçoive de contrainte verticale infinie : la rangée vit dans une zone de
    // défilement, où `CrossAxisAlignment.stretch` seul serait invalide.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: AnisSpacing.sm),
            Expanded(child: actions[i]),
          ],
        ],
      ),
    );
  }
}
