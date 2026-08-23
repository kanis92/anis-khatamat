import 'package:flutter/material.dart';

import '../anis_theme.dart';
import '../foundations/anis_responsive_layout.dart';
import '../tokens/anis_geometry.dart';

/// Structure de page ANIS.
///
/// Impose le fond ivoire, la marge horizontale de page et la réserve basse
/// au-dessus de la navigation. Un écran migré ne fixe plus lui-même sa couleur
/// de fond ni son padding : c'est ce qui garantit qu'une page reste alignée sur
/// les autres même quand son contenu change.
class AnisScaffold extends StatelessWidget {
  const AnisScaffold({
    super.key,
    required this.body,
    this.header,
    this.onRefresh,
    this.scrollable = true,
    this.padHorizontal = true,
  });

  /// Contenu de la page. Reçoit déjà la marge de page si [padHorizontal].
  final Widget body;

  /// En-tête fixe, hors zone de défilement.
  final Widget? header;

  /// Tirer pour rafraîchir. Absent si `null`.
  final Future<void> Function()? onRefresh;

  final bool scrollable;
  final bool padHorizontal;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final bottomPadding = AnisResponsiveLayout.shellBodyBottomInset(context);

    Widget content = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        padHorizontal ? AnisSpacing.page : 0,
        AnisSpacing.lg,
        padHorizontal ? AnisSpacing.page : 0,
        bottomPadding,
      ),
      child: body,
    );

    if (scrollable) {
      content = SingleChildScrollView(
        physics:
            onRefresh == null
                ? const BouncingScrollPhysics()
                : const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
        child: content,
      );
    }

    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        color: colors.actionPrimary,
        backgroundColor: colors.surfaceElevated,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: Column(
        children: [if (header != null) header!, Expanded(child: content)],
      ),
    );
  }
}
