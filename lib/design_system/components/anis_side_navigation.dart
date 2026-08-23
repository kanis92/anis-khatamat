import 'package:flutter/material.dart';

import '../../core/widgets/anis_icon.dart';
import '../anis_theme.dart';
import '../foundations/anis_accessibility_layout.dart';
import '../foundations/anis_haptics.dart';
import '../tokens/anis_geometry.dart';
import '../tokens/anis_motion.dart';
import 'anis_bottom_navigation.dart';

/// Navigation latérale ANIS pour le shell EXPANDED (desktop / large viewport).
///
/// Mêmes destinations, labels, icônes et sémantique que [AnisBottomNavigation].
class AnisSideNavigation extends StatelessWidget {
  const AnisSideNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  static const double width = 240;

  final List<AnisNavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final mode = AnisAccessibilityLayout.modeOf(context);

    return Semantics(
      container: true,
      label: 'Navigation principale',
      child: Material(
        color: colors.surfaceElevated,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: BorderDirectional(
              end: BorderSide(color: colors.borderSubtle),
            ),
          ),
          child: SafeArea(
            right: false,
            left: false,
            child: SizedBox(
              width: width,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: AnisSpacing.lg,
                  horizontal: AnisSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _AnisSideNavigationDestination(
                        item: items[i],
                        selected: i == currentIndex,
                        compactLabels:
                            mode != AnisAccessibilityTextMode.normal,
                        onTap: () {
                          if (i == currentIndex) return;
                          AnisHaptics.selection();
                          onSelected(i);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnisSideNavigationDestination extends StatelessWidget {
  const _AnisSideNavigationDestination({
    required this.item,
    required this.selected,
    required this.compactLabels,
    required this.onTap,
  });

  final AnisNavigationItem item;
  final bool selected;
  final bool compactLabels;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.anisColors;
    final text = context.anisText;
    final tint = selected ? colors.actionPrimary : colors.textSecondary;
    final bg = selected ? colors.actionPrimary.withValues(alpha: 0.08) : null;

    return Semantics(
      label: item.label,
      button: true,
      selected: selected,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: AnisSpacing.xs),
        child: Material(
          color: bg ?? Colors.transparent,
          borderRadius: AnisRadius.mdAll,
          child: InkWell(
            onTap: onTap,
            borderRadius: AnisRadius.mdAll,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AnisIconSize.minTapTarget,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AnisSpacing.md,
                  vertical: AnisSpacing.sm,
                ),
                child: Row(
                  children: [
                    if (item.icon != null)
                      AnisIcon(
                        type: item.icon!,
                        size: AnisIconSize.lg,
                        color: tint,
                      )
                    else
                      Icon(
                        item.materialIcon,
                        size: AnisIconSize.lg,
                        color: tint,
                      ),
                    const SizedBox(width: AnisSpacing.md),
                    Expanded(
                      child: Text(
                        item.label,
                        style: text.label.copyWith(
                          color: tint,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        maxLines: compactLabels ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedContainer(
                      duration: AnisMotion.durationOf(context, AnisMotion.fast),
                      curve: AnisMotion.enter,
                      width: 3,
                      height: selected ? 20 : 0,
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
      ),
    );
  }
}
