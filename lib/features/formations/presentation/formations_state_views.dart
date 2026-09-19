import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/l10n_extensions.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';
import '../providers/formations_access.dart';

String formationsErrorMessage(Object error, AppLocalizations l10n) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => l10n.formationsErrorPermissionDenied,
      'unavailable' => l10n.formationsErrorUnavailable,
      _ => l10n.errorLoadingFormations,
    };
  }
  return l10n.errorLoadingFormations;
}

/// Rend l'échec d'un provider Formation.
///
/// Absence de credentials et erreur Firestore sont deux états distincts, et
/// aucun des deux ne doit ressembler à un catalogue vide ou disparaître
/// silencieusement.
class FormationsFailureView extends StatelessWidget {
  const FormationsFailureView({
    required this.error,
    required this.onRetry,
    super.key,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (error is FormationsAuthRequiredException) {
      return FormationsStateCard(
        icon: Icons.lock_outline,
        title: l10n.formationsSignInRequiredTitle,
        body: l10n.formationsSignInRequiredBody,
        actionIcon: Icons.login,
        actionLabel: l10n.loginButton,
        onAction: () => context.go('/auth'),
      );
    }

    return FormationsStateCard(
      icon: Icons.error_outline,
      body: formationsErrorMessage(error, l10n),
      actionIcon: Icons.refresh,
      actionLabel: l10n.retry,
      onAction: onRetry,
    );
  }
}

class FormationsStateCard extends StatelessWidget {
  const FormationsStateCard({
    required this.icon,
    required this.body,
    required this.actionIcon,
    required this.actionLabel,
    required this.onAction,
    this.title,
    super.key,
  });

  final IconData icon;
  final String? title;
  final String body;
  final IconData actionIcon;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
            ],
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon, size: 18),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
