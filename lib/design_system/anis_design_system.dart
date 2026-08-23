/// ANIS Design System — V1 (sprint DS-01).
///
/// Source de vérité unique du langage visuel ANIS. Un écran migré importe ce
/// seul fichier et n'écrit plus aucune couleur, aucun rayon, aucune ombre ni
/// aucun `TextStyle` à la main.
///
/// Périmètre de DS-01 : fondations + écran d'accueil. Les autres univers
/// (Khatamat, Mushaf, Formation, Profil) restent sur l'ancien thème jusqu'à
/// leur propre sprint de migration.
///
/// Frontière à ne pas franchir : le rendu du texte coranique appartient au
/// package `flutter_quran` (police `hafs`, métriques propres). Aucun token de
/// ce système ne doit l'atteindre.
library;

export 'anis_theme.dart';
export 'components/anis_badge.dart';
export 'components/anis_bottom_navigation.dart';
export 'components/anis_buttons.dart';
export 'components/anis_empty_state.dart';
export 'components/anis_glyph.dart';
export 'components/anis_icon_action.dart';
export 'components/anis_list_tile.dart';
export 'components/anis_metric_tile.dart';
export 'components/anis_notice.dart';
export 'components/anis_page_header.dart';
export 'components/anis_progress.dart';
export 'components/anis_quick_action.dart';
export 'components/anis_scaffold.dart';
export 'components/anis_section_header.dart';
export 'components/anis_signature_mark.dart';
export 'components/anis_skeleton.dart';
export 'components/anis_surface.dart';
export 'foundations/anis_accessibility_layout.dart';
export 'foundations/anis_haptics.dart';
export 'tokens/anis_colors.dart';
export 'tokens/anis_effects.dart';
export 'tokens/anis_geometry.dart';
export 'tokens/anis_motion.dart';
export 'tokens/anis_typography.dart';
