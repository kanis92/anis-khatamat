import 'package:flutter/material.dart';

import '../../core/widgets/anis_icon.dart';
import '../anis_theme.dart';
import '../tokens/anis_geometry.dart';
import 'anis_signature_mark.dart';

/// Intention portée par un badge.
enum AnisBadgeTone {
  /// Information neutre.
  neutral,

  /// Information liée à l'action en cours.
  active,

  /// Accomplissement, distinction.
  accent,

  /// Attention calme (hors ligne, en attente).
  notice,
}

/// Pastille compacte porteuse d'une information courte.
///
/// Toujours accompagnée de texte : l'audit relevait des états encodés par la
/// seule couleur, ce que ce composant rend impossible puisque [label] est requis.
class AnisBadge extends StatelessWidget {
  const AnisBadge({
    super.key,
    required this.label,
    this.tone = AnisBadgeTone.neutral,
    this.icon,
    this.anisIcon,
    this.showSignature = false,
    this.semanticLabel,
  });

  final String label;
  final AnisBadgeTone tone;
  final IconData? icon;

  /// Icône propriétaire ANIS. Prend le pas sur [icon] lorsqu'elle est fournie.
  final AnisIconType? anisIcon;

  /// Ajoute la marque ۞ en tête. Réservé aux badges qui désignent un repère de
  /// lecture (Hizb, Khatma).
  final bool showSignature;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;

    final Color background;
    final Color foreground;
    final Color border;
    switch (tone) {
      case AnisBadgeTone.neutral:
        background = colors.surfaceSunken;
        foreground = colors.textSecondary;
        border = colors.borderSubtle;
        break;
      case AnisBadgeTone.active:
        background = colors.surfaceSoft;
        foreground = colors.actionSecondaryText;
        border = colors.actionSecondaryBorder;
        break;
      case AnisBadgeTone.accent:
        background = colors.accentGoldSurface;
        foreground = colors.accentGoldText;
        border = colors.accentGoldStrong;
        break;
      case AnisBadgeTone.notice:
        background = colors.noticeSurface;
        foreground = colors.noticeText;
        border = colors.noticeBorder;
        break;
    }

    return Semantics(
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AnisSpacing.md,
          vertical: AnisSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AnisRadius.pillAll,
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSignature) ...[
              AnisSignatureMark(
                role: AnisSignatureRole.marker,
                color: foreground,
              ),
              const SizedBox(width: AnisSpacing.xs),
            ] else if (anisIcon != null) ...[
              AnisIcon(
                type: anisIcon!,
                size: AnisIconSize.sm,
                color: foreground,
              ),
              const SizedBox(width: AnisSpacing.xs),
            ] else if (icon != null) ...[
              Icon(icon, size: AnisIconSize.sm, color: foreground),
              const SizedBox(width: AnisSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                style: text.label.copyWith(color: foreground),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
