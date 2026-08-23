import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../anis_theme.dart';
import '../tokens/anis_colors.dart';
import '../tokens/anis_geometry.dart';

/// Barre de progression ANIS.
///
/// Piste menthe, remplissage vert, extrémités arrondies. La valeur chiffrée est
/// portée par le libellé au-dessus, jamais par la couleur seule.
class AnisProgressBar extends StatelessWidget {
  const AnisProgressBar({
    super.key,
    required this.value,
    this.label,
    this.valueLabel,
    this.semanticLabel,
    this.thickness = 8,
  });

  /// Progression entre 0 et 1. Bornée par sécurité.
  final double value;

  /// Libellé de gauche.
  final String? label;

  /// Valeur affichée à droite — « 34/60 », « 57 % ».
  final String? valueLabel;

  final String? semanticLabel;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;
    final clamped = value.clamp(0.0, 1.0);

    return Semantics(
      label: semanticLabel ?? label,
      value: valueLabel ?? '${(clamped * 100).round()} %',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null || valueLabel != null) ...[
            Row(
              children: [
                if (label != null)
                  Expanded(
                    child: Text(
                      label!,
                      style: text.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (valueLabel != null)
                  Text(
                    valueLabel!,
                    style: text.label.copyWith(color: colors.actionPrimary),
                  ),
              ],
            ),
            const SizedBox(height: AnisSpacing.sm),
          ],
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: AnisRadius.pillAll,
              child: LinearProgressIndicator(
                value: clamped,
                minHeight: thickness,
                backgroundColor: colors.progressTrack,
                valueColor: AlwaysStoppedAnimation(colors.progressActive),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Anneau de progression ANIS.
///
/// Reprend la géométrie de `KhatmaRing` — arc à extrémité arrondie, point de
/// tête, piste continue — qui fonctionnait bien et reste la forme la plus
/// reconnaissable du produit. Trois différences :
///
/// - les couleurs viennent des tokens et non plus du blanc en dur, donc
///   l'anneau vit sur fond clair comme sur fond plein ;
/// - le point de tête est or, ce qui rattache la progression à l'accent
///   précieux du système ;
/// - le libellé sort de l'anneau. L'ancienne version empilait trois textes à
///   24 / 8,5 / 7,5 px dans 108 px, ce qui débordait dès 130 % d'échelle.
class AnisProgressRing extends StatelessWidget {
  const AnisProgressRing({
    super.key,
    required this.value,
    this.diameter = 92,
    this.thickness = 8,
    this.centerLabel,
    this.semanticLabel,
    this.tone = AnisProgressRingTone.onLight,
  });

  final double value;
  final double diameter;
  final double thickness;

  /// Texte au centre. `null` affiche le pourcentage.
  final String? centerLabel;

  final String? semanticLabel;
  final AnisProgressRingTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;
    final clamped = value.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();

    final Color track;
    final Color arc;
    final Color label;
    switch (tone) {
      case AnisProgressRingTone.onLight:
        track = colors.progressTrack;
        arc = colors.progressActive;
        label = colors.textPrimary;
        break;
      case AnisProgressRingTone.onInverse:
        track = colors.textOnInverse.withValues(alpha: 0.25);
        arc = colors.textOnInverse;
        label = colors.textOnInverse;
        break;
    }

    return Semantics(
      label: semanticLabel,
      value: '$percent %',
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: CustomPaint(
          painter: _AnisRingPainter(
            value: clamped,
            track: track,
            arc: arc,
            tip: colors.progressTip,
            thickness: thickness,
          ),
          child: Center(
            child: Padding(
              // Garde le texte à l'intérieur de l'anneau quelle que soit
              // l'échelle : le FittedBox réduit au lieu de déborder.
              padding: EdgeInsets.all(thickness * 2),
              child: FittedBox(
                child: ExcludeSemantics(
                  child: Text(
                    centerLabel ?? '$percent %',
                    style: text.numberLarge.copyWith(color: label),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fond sur lequel l'anneau est posé.
enum AnisProgressRingTone {
  /// Fond ivoire ou blanc — le cas courant.
  onLight,

  /// Bloc vert plein.
  onInverse,
}

class _AnisRingPainter extends CustomPainter {
  const _AnisRingPainter({
    required this.value,
    required this.track,
    required this.arc,
    required this.tip,
    required this.thickness,
  });

  final double value;
  final Color track;
  final Color arc;
  final Color tip;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - thickness / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..strokeWidth = thickness
        ..style = PaintingStyle.stroke,
    );

    if (value <= 0) return;

    const start = -math.pi / 2;
    final sweep = 2 * math.pi * value;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      Paint()
        ..color = arc
        ..strokeWidth = thickness
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final angle = start + sweep;
    canvas.drawCircle(
      Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      ),
      thickness * 0.42,
      Paint()..color = tip,
    );
  }

  @override
  bool shouldRepaint(_AnisRingPainter old) =>
      old.value != value ||
      old.track != track ||
      old.arc != arc ||
      old.tip != tip ||
      old.thickness != thickness;
}

/// Palette exposée pour les états Hizb, en attente de DS-02.
///
/// Regroupée ici afin que la grille des 60 Hizb n'ait, le jour de sa migration,
/// qu'un seul point d'entrée à consommer.
class AnisHizbStateColors {
  const AnisHizbStateColors._(this.surface, this.border, this.foreground);

  final Color surface;
  final Color border;
  final Color foreground;

  static AnisHizbStateColors available(AnisColors c) => AnisHizbStateColors._(
      c.hizbAvailableSurface, c.hizbAvailableBorder, c.hizbAvailableText);

  static AnisHizbStateColors pending(AnisColors c) => AnisHizbStateColors._(
      c.hizbPendingSurface, c.hizbPendingBorder, c.hizbPendingText);

  static AnisHizbStateColors reserved(AnisColors c) => AnisHizbStateColors._(
      c.hizbReservedSurface, c.hizbReservedBorder, c.hizbReservedText);

  static AnisHizbStateColors mine(AnisColors c) => AnisHizbStateColors._(
      c.hizbMineSurface, c.hizbMineBorder, c.hizbMineText);

  static AnisHizbStateColors inProgress(AnisColors c) => AnisHizbStateColors._(
      c.hizbInProgressSurface, c.hizbInProgressBorder, c.hizbInProgressText);

  static AnisHizbStateColors completed(AnisColors c) => AnisHizbStateColors._(
      c.hizbCompletedSurface, c.hizbCompletedBorder, c.hizbCompletedText);
}
