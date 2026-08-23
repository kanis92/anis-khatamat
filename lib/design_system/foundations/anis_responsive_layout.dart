import 'package:flutter/material.dart';

import '../components/anis_bottom_navigation.dart';
import '../tokens/anis_geometry.dart';

/// Palier de mise en page selon la largeur disponible (pas la plateforme).
enum AnisLayoutSize { compact, medium, expanded }

/// Largeurs maximales sémantiques pour le contenu ANIS.
abstract final class AnisContentWidth {
  AnisContentWidth._();

  /// Formulaires, champs, actions primaires.
  static const double form = 560;

  /// Lecture, listes denses, contenu principal.
  static const double reading = 720;

  /// Tableaux de bord, cartes multiples (Home, Khatma).
  static const double dashboard = 960;
}

/// Contrat responsive partagé par le shell, le scaffold et les conteneurs.
abstract final class AnisResponsiveLayout {
  AnisResponsiveLayout._();

  /// Seuil haut COMPACT — téléphone / mobile web.
  static const double compactMax = 599;

  /// Seuil haut MEDIUM — tablette / fenêtre étroite.
  static const double mediumMax = 1099;

  static AnisLayoutSize sizeOfWidth(double width) {
    if (width <= compactMax) return AnisLayoutSize.compact;
    if (width <= mediumMax) return AnisLayoutSize.medium;
    return AnisLayoutSize.expanded;
  }

  static AnisLayoutSize sizeOf(BuildContext context) =>
      sizeOfWidth(MediaQuery.sizeOf(context).width);

  /// Le shell utilise la navigation latérale (EXPANDED).
  static bool usesSideNavigation(BuildContext context) =>
      sizeOf(context) == AnisLayoutSize.expanded;

  /// Largeur max du corps de page dans le shell.
  static double shellContentMaxWidth(BuildContext context) {
    return switch (sizeOf(context)) {
      AnisLayoutSize.compact => double.infinity,
      AnisLayoutSize.medium => AnisContentWidth.dashboard,
      AnisLayoutSize.expanded => AnisContentWidth.dashboard,
    };
  }

  /// Réserve basse au-dessus de la navigation basse (0 si rail latéral).
  static double shellBodyBottomInset(BuildContext context) {
    if (usesSideNavigation(context)) return AnisSpacing.lg;
    return AnisBottomNavigation.bodyBottomInset(context);
  }
}

/// Centre et contraint le contenu du shell sans dupliquer la logique par écran.
class AnisShellContent extends StatelessWidget {
  const AnisShellContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxWidth = AnisResponsiveLayout.shellContentMaxWidth(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveMax = maxWidth.isFinite
            ? maxWidth.clamp(0.0, constraints.maxWidth)
            : constraints.maxWidth;
        return Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: effectiveMax),
            child: SizedBox(width: double.infinity, child: child),
          ),
        );
      },
    );
  }
}
