import 'package:flutter/material.dart';

import '../anis_theme.dart';
import '../tokens/anis_geometry.dart';
import 'anis_buttons.dart';
import 'anis_glyph.dart';
import 'anis_surface.dart';

/// Nature d'un message en ligne.
enum AnisNoticeTone {
  /// Contexte calme — hors ligne, synchronisation en attente.
  notice,

  /// Échec de chargement.
  danger,
}

/// Message en ligne, posé dans le flux de la page.
///
/// Remplace la bannière orange Material par un bloc de la famille champagne,
/// cohérent avec la direction artistique. Le message est annoncé comme
/// `liveRegion` pour qu'un lecteur d'écran le signale à son apparition.
class AnisNotice extends StatelessWidget {
  const AnisNotice({
    super.key,
    required this.message,
    this.tone = AnisNoticeTone.notice,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AnisNoticeTone tone;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;

    final Color surface;
    final Color border;
    final Color foreground;
    switch (tone) {
      case AnisNoticeTone.notice:
        surface = colors.noticeSurface;
        border = colors.noticeBorder;
        foreground = colors.noticeText;
        break;
      case AnisNoticeTone.danger:
        surface = colors.dangerSurface;
        border = colors.dangerBorder;
        foreground = colors.dangerText;
        break;
    }

    return Semantics(
      liveRegion: true,
      child: AnisSurface(
        level: AnisSurfaceLevel.flat,
        radius: AnisRadius.md,
        borderColor: border,
        backgroundColor: surface,
        padding: const EdgeInsetsDirectional.all(AnisSpacing.md),
        child: Row(
          children: [
            if (icon != null) ...[
              AnisGlyph.material(
                icon!,
                size: AnisIconSize.md,
                color: foreground,
              ),
              const SizedBox(width: AnisSpacing.sm),
            ],
            Expanded(
              child: Text(
                message,
                style: text.bodySecondary.copyWith(color: foreground),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: AnisSpacing.sm),
              AnisTextAction(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
