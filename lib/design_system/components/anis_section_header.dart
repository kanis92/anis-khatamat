import 'package:flutter/material.dart';

import '../anis_theme.dart';
import '../tokens/anis_geometry.dart';
import 'anis_buttons.dart';

/// Titre de section avec action optionnelle de fin de ligne.
///
/// Remplace les titres de section écrits à la main sur chaque écran. Le titre
/// est annoncé comme en-tête pour qu'un lecteur d'écran puisse naviguer de
/// section en section.
class AnisSectionHeader extends StatelessWidget {
  const AnisSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final text = context.anisText;
    final hasAction = actionLabel != null && onAction != null;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AnisSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: text.sectionTitle),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AnisSpacing.xxs),
                  Text(subtitle!, style: text.caption),
                ],
              ],
            ),
          ),
          if (hasAction)
            AnisTextAction(
              label: actionLabel!,
              onPressed: onAction,
              trailingIcon: actionIcon,
            ),
        ],
      ),
    );
  }
}
