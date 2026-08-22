import 'package:flutter/material.dart';

import '../../core/widgets/anis_icon.dart';
import '../anis_theme.dart';
import '../foundations/anis_haptics.dart';
import '../tokens/anis_geometry.dart';
import '../tokens/anis_motion.dart';

/// Un onglet de la navigation basse.
class AnisNavigationItem {
  const AnisNavigationItem({required this.label, this.icon, this.materialIcon})
    : assert(
        icon != null || materialIcon != null,
        'AnisNavigationItem requires icon or materialIcon',
      );

  final String label;

  /// Icône propriétaire ANIS. Prioritaire lorsqu'elle est fournie.
  final AnisIconType? icon;

  /// Repli Material lorsqu'aucune icône ANIS n'existe encore pour l'onglet.
  final IconData? materialIcon;
}

/// Navigation basse ANIS.
///
/// Chrome partagé par tous les écrans du shell, migré ici parce que la barre
/// fait partie de l'identité de la Home. Le comportement est inchangé — mêmes
/// onglets, mêmes indices, mêmes destinations — seule la présentation évolue.
///
/// Trois corrections d'accessibilité par rapport à la version précédente :
/// chaque onglet est annoncé avec son état sélectionné, la hauteur libre
/// remplace le `SizedBox(height: 64)` qui tronquait les libellés à 130 %
/// d'échelle, et le libellé ne descend plus sous 12 px.
class AnisBottomNavigation extends StatelessWidget {
  const AnisBottomNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<AnisNavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        border: BorderDirectional(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AnisSpacing.sm,
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _AnisNavigationTab(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () {
                      if (i == currentIndex) return;
                      AnisHaptics.selection();
                      onSelected(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnisNavigationTab extends StatelessWidget {
  const _AnisNavigationTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AnisNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;
    final tint = selected ? colors.actionPrimary : colors.textSecondary;

    return Semantics(
      label: item.label,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: AnisRadius.mdAll),
        child: ExcludeSemantics(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AnisIconSize.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AnisSpacing.sm,
                horizontal: AnisSpacing.xs,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (item.icon != null)
                    AnisIcon(
                      type: item.icon!,
                      size: AnisIconSize.lg,
                      color: tint,
                    )
                  else
                    Icon(item.materialIcon, size: AnisIconSize.lg, color: tint),
                  const SizedBox(height: AnisSpacing.xs),
                  Text(
                    item.label,
                    style: text.label.copyWith(
                      color: tint,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AnisSpacing.xs),
                  AnimatedContainer(
                    duration: AnisMotion.durationOf(context, AnisMotion.fast),
                    curve: AnisMotion.enter,
                    width: selected ? 18 : 0,
                    height: 3,
                    decoration: BoxDecoration(
                      color: colors.accentGoldStrong,
                      borderRadius: AnisRadius.pillAll,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
