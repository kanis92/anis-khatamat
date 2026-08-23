import 'package:flutter/material.dart';

import '../anis_theme.dart';
import '../foundations/anis_accessibility_layout.dart';
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
    final mode = AnisAccessibilityLayout.modeOf(context);
    final extreme = mode == AnisAccessibilityTextMode.extreme;

    final verticalPadding = extreme ? AnisSpacing.md : AnisSpacing.xxxl;
    final iconSize = extreme ? 48.0 : 72.0;
    final iconGap = extreme ? AnisSpacing.xs : AnisSpacing.xl;
    final titleStyle = extreme ? text.accessibilityCompact : text.title;
    final messageStyle = extreme ? text.caption : text.bodySecondary;
    final actionsGap = extreme ? AnisSpacing.md : AnisSpacing.xl;

    return AnisSurface(
      level: AnisSurfaceLevel.soft,
      radius: AnisRadius.xl,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AnisSpacing.xl,
        vertical: verticalPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surfaceSoft,
              border: Border.all(color: colors.borderSubtle),
            ),
            alignment: Alignment.center,
            child:
                showSignature || glyph == null
                    // L'encre du glyphe n'occupe qu'une partie de sa boîte d'emploi :
                    // au palier `lg` il se perdait dans le cercle de 72 dp.
                    ? AnisSignatureMark(
                      role: AnisSignatureRole.accomplishment,
                      size:
                          extreme ? AnisIconSize.md : AnisIconSize.illustration,
                    )
                    : glyph!,
          ),
          SizedBox(height: iconGap),
          Semantics(
            header: true,
            child: Text(
              title,
              style: titleStyle,
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: extreme ? AnisSpacing.xs : AnisSpacing.sm),
            Text(
              message!,
              style: messageStyle,
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ],
          if (primaryActionLabel != null && onPrimaryAction != null) ...[
            SizedBox(height: actionsGap),
            AnisPrimaryButton(
              label: primaryActionLabel!,
              onPressed: onPrimaryAction,
            ),
          ],
          if (secondaryActionLabel != null && onSecondaryAction != null) ...[
            SizedBox(height: extreme ? AnisSpacing.xs : AnisSpacing.sm),
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
