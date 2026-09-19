import 'package:flutter/material.dart';

import '../anis_theme.dart';
import '../tokens/anis_colors.dart';
import '../tokens/anis_geometry.dart';
import 'anis_surface.dart';

/// Familles visuelles des tuiles d'accès rapide (accueil).
enum AnisHomeQuickActionVariant {
  douaaArrabita,
  khatma,
  formations,
  ayatFadila,
}

/// Photo de marque partagée — même univers que [AnisHomeHero] (Mushaf, lumière or).
const kAnisQuickActionPhotoAsset = 'assets/images/anis_header.png';

/// Tuile éditoriale : **vignette photo réelle** + texte (pas d'icône SVG décorative).
class AnisHomeQuickActionTile extends StatelessWidget {
  const AnisHomeQuickActionTile({
    super.key,
    required this.variant,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final AnisHomeQuickActionVariant variant;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static _VariantVisual _visual(AnisHomeQuickActionVariant v) {
    return switch (v) {
      AnisHomeQuickActionVariant.douaaArrabita => const _VariantVisual(
        photoAlignment: Alignment(0.05, 0.55),
        photoScale: 1.35,
        accent: AnisPalette.green700,
        border: AnisPalette.mint200,
      ),
      AnisHomeQuickActionVariant.khatma => const _VariantVisual(
        photoAlignment: Alignment(0.0, -0.12),
        photoScale: 1.25,
        accent: AnisPalette.gold700,
        border: AnisPalette.gold100,
      ),
      AnisHomeQuickActionVariant.formations => const _VariantVisual(
        photoAlignment: Alignment(-0.35, 0.15),
        photoScale: 1.4,
        accent: AnisPalette.green800,
        border: AnisPalette.mint300,
      ),
      AnisHomeQuickActionVariant.ayatFadila => const _VariantVisual(
        photoAlignment: Alignment(0.42, -0.35),
        photoScale: 1.3,
        accent: AnisPalette.gold700,
        border: AnisPalette.gold100,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;
    final visual = _visual(variant);

    return AnisSurface(
      level: AnisSurfaceLevel.soft,
      radius: AnisRadius.lg,
      padding: EdgeInsets.zero,
      borderColor: visual.border.withValues(alpha: 0.55),
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      child: ClipRRect(
        borderRadius: AnisRadius.lgAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 76,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Transform.scale(
                    scale: visual.photoScale,
                    child: Image.asset(
                      kAnisQuickActionPhotoAsset,
                      fit: BoxFit.cover,
                      alignment: visual.photoAlignment,
                      filterQuality: FilterQuality.high,
                      semanticLabel: title,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          colors.shadow.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ColoredBox(
              color: colors.surfaceElevated,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AnisSpacing.md,
                  AnisSpacing.md,
                  AnisSpacing.md,
                  AnisSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AnisSpacing.xxs),
                    Text(
                      subtitle,
                      style: text.caption.copyWith(
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AnisSpacing.sm),
                    Container(
                      height: 2,
                      width: 28,
                      color: visual.accent.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariantVisual {
  const _VariantVisual({
    required this.photoAlignment,
    required this.photoScale,
    required this.accent,
    required this.border,
  });

  final Alignment photoAlignment;
  final double photoScale;
  final Color accent;
  final Color border;
}
