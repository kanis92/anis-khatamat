import 'dart:math' as math;
import 'package:flutter/material.dart';

/// VISUAL PREVIEW GRID - TEST ONLY
/// 
/// Renders Monthly Ring at key progress states:
/// 0%, 2%, 25%, 50%, 75%, 100%
/// 
/// To preview: Replace home screen temporarily with this widget.
/// DO NOT commit as production code.
class RingPreviewGrid extends StatelessWidget {
  const RingPreviewGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7), // ANIS ivory
      appBar: AppBar(
        title: const Text('Ring Preview - All States'),
        backgroundColor: const Color(0xFFFAF9F7),
        elevation: 0,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _PreviewCard(completedRubs: 0, label: '0%\n0 / 240 Rub\''),
          _PreviewCard(completedRubs: 7, label: '2%\n7 / 240 Rub\''),
          _PreviewCard(completedRubs: 60, label: '25%\n60 / 240 Rub\''),
          _PreviewCard(completedRubs: 120, label: '50%\n120 / 240 Rub\''),
          _PreviewCard(completedRubs: 180, label: '75%\n180 / 240 Rub\''),
          _PreviewCard(completedRubs: 240, label: '100%\n240 / 240 Rub\''),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.completedRubs, required this.label});

  final int completedRubs;
  final String label;

  @override
  Widget build(BuildContext context) {
    final progress = completedRubs / 240.0;
    final percentDisplay = ((progress * 100).floor()).toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          _RingPreview(progress: progress, percentDisplay: percentDisplay),
        ],
      ),
    );
  }
}

class _RingPreview extends StatelessWidget {
  const _RingPreview({required this.progress, required this.percentDisplay});

  final double progress;
  final String percentDisplay;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 120),
      painter: _PreviewPainter(
        progress: progress,
        primaryColor: const Color(0xFF047857), // ANIS emerald
        accentColor: const Color(0xFFD97706), // ANIS gold
        trackColor: const Color(0xFFE5E7EB),
      ),
      child: SizedBox(
        width: 120,
        height: 120,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentDisplay%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF047857),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'de ma Khatma',
                style: TextStyle(
                  fontSize: 9,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same painter architecture as production.
class _PreviewPainter extends CustomPainter {
  _PreviewPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
    required this.trackColor,
  });

  final double progress;
  final Color primaryColor;
  final Color accentColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 7.5; // Proportional for 120px preview
    final startAngle = -math.pi / 2;

    // ══════════════════════════════════════════════════════════════════════
    // A. DORMANT 360° BODY — CERCLE COMPLET (richer emerald base)
    // ══════════════════════════════════════════════════════════════════════
    
    // Émeraude désaturé/sombre plus riche
    final dormantBase = Color.lerp(trackColor, primaryColor, 0.35)!;
    
    // Outer edge
    final dormantOuterPaint = Paint()
      ..color = dormantBase.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 1.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);

    canvas.drawCircle(center, radius - strokeWidth / 2, dormantOuterPaint);

    // Dormant body principal (richer)
    final dormantPaint = Paint()
      ..color = dormantBase.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, dormantPaint);

    // Inner edge
    final dormantInnerPaint = Paint()
      ..color = dormantBase.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, dormantInnerPaint);

    // ══════════════════════════════════════════════════════════════════════
    // B-D. PROGRESS ARC ILLUMINÉ — UNE BANDE LUMINEUSE UNIFIÉE
    // ══════════════════════════════════════════════════════════════════════
    
    if (progress > 0) {
      final sweepAngle = math.pi * 2 * progress;
      final arcRect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

      // ────────────────────────────────────────────────────────────────────
      // B. OUTER BLOOM — Lumière émise (tightened)
      // ────────────────────────────────────────────────────────────────────
      
      final outerBloomPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawArc(arcRect, startAngle, sweepAngle, false, outerBloomPaint);

      final innerBloomPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawArc(arcRect, startAngle, sweepAngle, false, innerBloomPaint);

      // ────────────────────────────────────────────────────────────────────
      // C. LUMINOUS BODY — Bande principale avec gradient intégré
      // ────────────────────────────────────────────────────────────────────
      
      // Gradient from darker edges to brighter center
      final darkerEmerald = Color.lerp(primaryColor, Colors.black, 0.15)!;
      final richEmerald = primaryColor;
      final brightEmerald = Color.lerp(primaryColor, const Color(0xFF10B981), 0.25)!;
      
      // Base avec gradient pour effet de profondeur lumineux
      final luminousBodyPaint = Paint()
        ..shader = LinearGradient(
          colors: [darkerEmerald, richEmerald, brightEmerald],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(arcRect, startAngle, sweepAngle, false, luminousBodyPaint);

      // ────────────────────────────────────────────────────────────────────
      // D. SUBTLE INNER HIGHLIGHT — Narrow, soft, integrated
      // ────────────────────────────────────────────────────────────────────
      
      // Highlight très subtil intégré (pas un contour séparé)
      final subtleHighlightPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawArc(arcRect, startAngle, sweepAngle, false, subtleHighlightPaint);

      // ────────────────────────────────────────────────────────────────────
      // E. GOLD ENDPOINT — Extremely subtle, skip at very low progress
      // ────────────────────────────────────────────────────────────────────
      
      if (progress > 0.08) { // Only after 8%
        final endAngle = startAngle + sweepAngle;
        final endpointCenter = Offset(
          center.dx + (radius - strokeWidth / 2) * math.cos(endAngle),
          center.dy + (radius - strokeWidth / 2) * math.sin(endAngle),
        );

        // Gold glow minimal
        final goldGlowPaint = Paint()
          ..color = accentColor.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

        canvas.drawCircle(endpointCenter, 3, goldGlowPaint);

        // Gold point très petit
        final goldPointPaint = Paint()
          ..color = accentColor.withValues(alpha: 0.7)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(endpointCenter, 1.2, goldPointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter old) => old.progress != progress;
}
