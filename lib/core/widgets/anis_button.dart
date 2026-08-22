import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Variantes du bouton ANIS
enum AnisButtonVariant {
  /// Vert principal (#0E5E46)
  primary,
  /// Or accent (#D4AF37)
  accent,
  /// Bordure verte, fond transparent
  outline,
}

/// Bouton du Design System ANIS — La Compagnie du Coran
class AnisButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AnisButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;

  const AnisButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AnisButtonVariant.primary,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return SizedBox(
        width: fullWidth ? double.infinity : null,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: _buildStyle(context),
        ),
      );
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: FilledButton(
        onPressed: onPressed,
        style: _buildStyle(context),
        child: Text(label),
      ),
    );
  }

  ButtonStyle _buildStyle(BuildContext context) {
    switch (variant) {
      case AnisButtonVariant.primary:
        return FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      case AnisButtonVariant.accent:
        return FilledButton.styleFrom(
          backgroundColor: AppTheme.accentGold,
          foregroundColor: AppTheme.darkGreen,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      case AnisButtonVariant.outline:
        return FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.primaryGreen,
          side: const BorderSide(color: AppTheme.primaryGreen, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
    }
  }
}
