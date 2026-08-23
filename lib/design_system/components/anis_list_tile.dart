import 'package:flutter/material.dart';

import '../anis_theme.dart';
import '../tokens/anis_effects.dart';
import '../tokens/anis_geometry.dart';
import 'anis_glyph.dart';
import 'anis_surface.dart';

/// Ligne de liste ANIS.
///
/// Le chevron de fin de ligne est miroité en RTL — l'audit comptait 17
/// `arrow_forward_ios` orientés en dur, qui pointaient à contresens en arabe.
class AnisListTile extends StatelessWidget {
  const AnisListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;

  /// Icône de tête, présentée dans un bloc menthe.
  final IconData? leadingIcon;

  /// Élément de tête personnalisé. Prend le pas sur [leadingIcon].
  final Widget? leading;

  /// Élément de fin de ligne — badge, valeur. Remplace le chevron.
  final Widget? trailing;

  final VoidCallback? onTap;
  final bool showChevron;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;

    Widget? head = leading;
    if (head == null && leadingIcon != null) {
      head = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color:
              colors.actionPrimary.withValues(alpha: AnisOpacity.subtleFill),
          borderRadius: AnisRadius.smAll,
        ),
        alignment: Alignment.center,
        child: Icon(
          leadingIcon,
          size: AnisIconSize.md,
          color: colors.actionPrimary,
        ),
      );
    }

    return AnisSurface(
      level: AnisSurfaceLevel.subtle,
      radius: AnisRadius.md,
      padding: const EdgeInsetsDirectional.all(AnisSpacing.lg),
      onTap: onTap,
      semanticLabel:
          semanticLabel ?? (subtitle == null ? title : '$title. $subtitle'),
      child: Row(
        children: [
          if (head != null) ...[
            ExcludeSemantics(child: head),
            const SizedBox(width: AnisSpacing.md),
          ],
          Expanded(
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AnisSpacing.xxs),
                    Text(
                      subtitle!,
                      style: text.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AnisSpacing.md),
            trailing!,
          ] else if (showChevron && onTap != null) ...[
            const SizedBox(width: AnisSpacing.sm),
            AnisGlyph.material(
              Icons.chevron_right_rounded,
              size: AnisIconSize.lg,
              color: colors.textTertiary,
              mirrorInRtl: true,
            ),
          ],
        ],
      ),
    );
  }
}
