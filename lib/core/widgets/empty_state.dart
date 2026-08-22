import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'anis_button.dart';
import 'anis_icon.dart';

/// État vide illustré — Design System ANIS
/// Utilisé quand une liste ou une section est vide
class EmptyState extends StatelessWidget {
  final AnisIconType? icon;
  final IconData? fallbackIcon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon,
    this.fallbackIcon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  }) : assert(icon != null || fallbackIcon != null, 'icon or fallbackIcon required');

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: icon != null
                  ? AnisIcon(type: icon!, size: 48, color: AppTheme.primaryGreen)
                  : Icon(fallbackIcon!, size: 48, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              AnisButton(
                label: actionLabel!,
                onPressed: onAction,
                icon: Icons.add_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
