import 'package:flutter/material.dart';

import '../anis_theme.dart';
import '../tokens/anis_geometry.dart';
import 'anis_surface.dart';

/// Tuile de métrique — une valeur, un libellé.
///
/// Le libellé n'est jamais tronqué : il passe à la ligne. Une tuile qui grandit
/// vaut mieux qu'un chiffre sans sens, en particulier à 130 % d'échelle de texte
/// où les libellés à 11 px de l'ancienne version disparaissaient.
class AnisMetricTile extends StatelessWidget {
  const AnisMetricTile({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
    this.emphasize = false,
  });

  final String value;
  final String label;
  final VoidCallback? onTap;

  /// Met la valeur en vert plutôt qu'en encre : à réserver à la métrique
  /// dominante d'une rangée.
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;

    return AnisSurface(
      tone: AnisSurfaceTone.elevated,
      level: AnisSurfaceLevel.subtle,
      radius: AnisRadius.md,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AnisSpacing.md,
        vertical: AnisSpacing.lg,
      ),
      onTap: onTap,
      semanticLabel: '$label : $value',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Text(
              value,
              style: text.number.copyWith(
                color: emphasize ? colors.actionPrimary : colors.textPrimary,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: AnisSpacing.xs),
          ExcludeSemantics(
            child: Text(
              label,
              style: text.caption,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
