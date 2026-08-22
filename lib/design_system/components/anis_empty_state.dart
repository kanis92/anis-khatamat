import 'package:flutter/material.dart';

import '../anis_theme.dart';
import '../tokens/anis_geometry.dart';
import 'anis_buttons.dart';
import 'anis_glyph.dart';
import 'anis_surface.dart';
import 'anis_signature_mark.dart';

/// État vide ANIS.
///
/// Un état vide est une invitation, pas un constat d'échec : titre en menthe
/// claire, illustration sobre, une action principale et au plus une secondaire.
class AnisEmptyState extends StatelessWidget {
  const AnisEmptyState({
    super.key,
    required this.title,
    this.message,
    this.glyph,
    this.showSignature = false,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String? message;
  final AnisGlyph? glyph;

  /// Remplace l'illustration par la marque ۞ — pour les vides liés à la lecture.
  final bool showSignature;

  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;

    return AnisSurface(
      level: AnisSurfaceLevel.soft,
      radius: AnisRadius.xl,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AnisSpacing.xl,
        vertical: AnisSpacing.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surfaceSoft,
              border: Border.all(color: colors.borderSubtle),
            ),
            alignment: Alignment.center,
            child: showSignature || glyph == null
                // L'encre du glyphe n'occupe qu'une partie de sa boîte d'emploi :
                // au palier `lg` il se perdait dans le cercle de 72 dp.
                ? const AnisSignatureMark(
                    role: AnisSignatureRole.accomplishment,
                    size: AnisIconSize.illustration,
                  )
                : glyph!,
          ),
          const SizedBox(height: AnisSpacing.xl),
          Semantics(
            header: true,
            child: Text(
              title,
              style: text.title,
              textAlign: TextAlign.center,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AnisSpacing.sm),
            Text(
              message!,
              style: text.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
          if (primaryActionLabel != null && onPrimaryAction != null) ...[
            const SizedBox(height: AnisSpacing.xl),
            AnisPrimaryButton(
              label: primaryActionLabel!,
              onPressed: onPrimaryAction,
            ),
          ],
          if (secondaryActionLabel != null && onSecondaryAction != null) ...[
            const SizedBox(height: AnisSpacing.sm),
            AnisSecondaryButton(
              label: secondaryActionLabel!,
              onPressed: onSecondaryAction,
            ),
          ],
        ],
      ),
    );
  }
}
