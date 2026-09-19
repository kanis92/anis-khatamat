import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/l10n_extensions.dart';
import '../../../core/widgets/anis_icon.dart';
import '../../../design_system/anis_design_system.dart';

/// Ayat Fadila — annoncé ; contenu PDF à venir.
class AyatFadilaScreen extends StatelessWidget {
  const AyatFadilaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.anisColors;

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AyatFadilaHero(onBack: () => _pop(context)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.all(AnisSpacing.page),
              child: Column(
                children: [
                  AnisBadge(
                    label: l10n.upcoming,
                    tone: AnisBadgeTone.accent,
                    anisIcon: AnisIconType.starDiamond,
                  ),
                  const SizedBox(height: AnisSpacing.xl),
                  AnisEmptyState(
                    title: l10n.upcoming,
                    message: l10n.ayatFadilaComingSoonMessage,
                    glyph: AnisGlyph.anis(
                      AnisIconType.handsQuran,
                      size: AnisIconSize.xl,
                      color: colors.accentGoldText,
                    ),
                    showSignature: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
}

class _AyatFadilaHero extends StatelessWidget {
  const _AyatFadilaHero({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.anisText;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AnisPalette.green825,
            AnisPalette.green800,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AnisSpacing.page,
            AnisSpacing.sm,
            AnisSpacing.page,
            AnisSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: Colors.white,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AnisPalette.gold500.withValues(alpha: 0.18),
                      borderRadius: AnisRadius.lgAll,
                      border: Border.all(
                        color: AnisPalette.gold500.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AnisSpacing.md),
                      child: AnisGlyph.anis(
                        AnisIconType.handsQuran,
                        size: AnisIconSize.xl,
                        color: AnisPalette.gold500,
                      ),
                    ),
                  ),
                  const SizedBox(width: AnisSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.ayatFadilaTitle,
                          style: text.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AnisSpacing.xs),
                        Text(
                          l10n.ayatFadilaHeaderSubtitle,
                          style: text.bodySecondary.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
