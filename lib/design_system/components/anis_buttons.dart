import 'package:flutter/material.dart';

import '../../core/widgets/anis_icon.dart';
import '../anis_theme.dart';
import '../foundations/anis_haptics.dart';
import '../tokens/anis_geometry.dart';

/// Retour haptique associé à un bouton.
enum AnisButtonFeedback {
  /// Aucun retour tactile — le cas par défaut.
  none,

  /// Choix dans un ensemble.
  selection,

  /// Action engageante réussie.
  confirm;

  void fire() {
    switch (this) {
      case AnisButtonFeedback.none:
        break;
      case AnisButtonFeedback.selection:
        AnisHaptics.selection();
        break;
      case AnisButtonFeedback.confirm:
        AnisHaptics.confirm();
        break;
    }
  }
}

/// Bouton d'action principale.
///
/// Une seule action principale par bloc. Hauteur garantie à 48 dp, largeur
/// pleine par défaut : c'est la forme qui porte l'intention sur cet écran.
class AnisPrimaryButton extends StatelessWidget {
  const AnisPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.anisIcon,
    this.expand = true,
    this.feedback = AnisButtonFeedback.none,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AnisIconType? anisIcon;

  /// Occupe toute la largeur disponible.
  final bool expand;

  final AnisButtonFeedback feedback;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;

    final action = onPressed;
    final button = FilledButton(
      onPressed:
          action == null
              ? null
              : () {
                feedback.fire();
                action();
              },
      style: FilledButton.styleFrom(
        backgroundColor: colors.actionPrimary,
        foregroundColor: colors.textOnAction,
        disabledBackgroundColor: colors.actionDisabledSurface,
        disabledForegroundColor: colors.actionDisabledText,
        elevation: 0,
        minimumSize: Size(
          expand ? double.infinity : 0,
          AnisIconSize.minTapTarget,
        ),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AnisSpacing.xl,
          vertical: AnisSpacing.md,
        ),
        shape: RoundedRectangleBorder(borderRadius: AnisRadius.lgAll),
        textStyle: text.label,
      ),
      child: _AnisButtonContent(
        label: label,
        icon: icon,
        anisIcon: anisIcon,
        iconColor: colors.textOnAction,
      ),
    );

    if (semanticLabel == null) return button;
    return Semantics(label: semanticLabel, button: true, child: button);
  }
}

/// Bouton d'action secondaire — menthe légère, texte vert, trait subtil.
///
/// Se place à côté d'une action principale ou porte seul une action non
/// engageante (« Voir tout », « Rejoindre »).
class AnisSecondaryButton extends StatelessWidget {
  const AnisSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.feedback = AnisButtonFeedback.none,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final AnisButtonFeedback feedback;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;

    final action = onPressed;
    final button = OutlinedButton(
      onPressed:
          action == null
              ? null
              : () {
                feedback.fire();
                action();
              },
      style: OutlinedButton.styleFrom(
        backgroundColor: colors.actionSecondarySurface,
        foregroundColor: colors.actionSecondaryText,
        disabledForegroundColor: colors.actionDisabledText,
        elevation: 0,
        side: BorderSide(
          color: colors.actionSecondaryBorder,
          width: AnisBorder.hairline,
        ),
        minimumSize: Size(
          expand ? double.infinity : 0,
          AnisIconSize.minTapTarget,
        ),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AnisSpacing.xl,
          vertical: AnisSpacing.md,
        ),
        shape: RoundedRectangleBorder(borderRadius: AnisRadius.lgAll),
        textStyle: text.label,
      ),
      child: _AnisButtonContent(label: label, icon: icon),
    );

    if (semanticLabel == null) return button;
    return Semantics(label: semanticLabel, button: true, child: button);
  }
}

/// Action textuelle discrète — « Voir tout », « Réessayer ».
///
/// N'a pas de surface : à réserver aux actions de navigation latérale, jamais
/// à une action destructive ou engageante.
class AnisTextAction extends StatelessWidget {
  const AnisTextAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Icône de fin de ligne. Miroitée automatiquement en RTL.
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: colors.actionSecondaryText,
        minimumSize: const Size(0, AnisIconSize.minTapTarget),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AnisSpacing.sm,
        ),
        textStyle: text.label,
        shape: RoundedRectangleBorder(borderRadius: AnisRadius.smAll),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (trailingIcon != null) ...[
            const SizedBox(width: AnisSpacing.xs),
            Icon(
              trailingIcon,
              size: AnisIconSize.sm,
              // Suit la direction de lecture : la flèche de progression pointe
              // vers la droite en français, vers la gauche en arabe.
              textDirection: Directionality.of(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnisButtonContent extends StatelessWidget {
  const _AnisButtonContent({
    required this.label,
    this.icon,
    this.anisIcon,
    this.iconColor,
  });

  final String label;
  final IconData? icon;
  final AnisIconType? anisIcon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    if (icon == null && anisIcon == null) {
      return Text(
        label,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (anisIcon != null)
          AnisIcon(type: anisIcon!, size: AnisIconSize.md, color: iconColor)
        else
          Icon(icon, size: AnisIconSize.md, color: iconColor),
        const SizedBox(width: AnisSpacing.sm),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
