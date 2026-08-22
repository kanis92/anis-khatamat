import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/khatma.dart';
import '../core/models/khatma_load_result.dart';
import '../core/providers/reading_provider.dart';
import '../core/services/khatma_link_service.dart';
import '../core/utils/khatma_completion_utils.dart';
import '../core/utils/khatma_navigation_utils.dart';
import '../core/widgets/empty_state.dart';
import 'hizb_reservation_screen.dart';
import 'khatma_completion_screen.dart';
import 'khatma_detail_screen.dart';

/// Route canonique `/khatma/:id` — charge par ID, indépendamment de `GoRouter.extra`.
class KhatmaRouteScreen extends ConsumerWidget {
  final String khatmaId;
  final Khatma? preloadedKhatma;
  final String? guestId;

  const KhatmaRouteScreen({
    super.key,
    required this.khatmaId,
    this.preloadedKhatma,
    this.guestId,
  });

  String? get _effectiveGuestId {
    if (guestId != null && guestId!.isNotEmpty) return guestId;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.isAnonymous) return user.uid;
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (khatmaId.isEmpty) {
      return _KhatmaRouteErrorScaffold(
        title: 'Khatma introuvable',
        message: 'Cette Khatma n\'existe plus ou le lien n\'est pas valide.',
        onBack: () => _goBack(context),
        onMyKhatmas: () => context.go('/khatma'),
      );
    }

    final seed = validatePreloadedKhatma(preloadedKhatma, khatmaId);
    final loadAsync = ref.watch(khatmaLoadProvider(khatmaId));
    final streamAsync = ref.watch(khatmaStreamProvider(khatmaId));

    final streamed = streamAsync.valueOrNull;
    final resolved = resolveKhatmaSnapshot(
      khatmaId: khatmaId,
      preloaded: seed,
      fetched: loadAsync.valueOrNull?.khatma,
      streamed: streamed,
    );

    if (resolved != null) {
      return _buildExperience(resolved);
    }

    return loadAsync.when(
      loading: () => seed != null
          ? _buildExperience(seed)
          : const _KhatmaRouteLoadingScaffold(),
      error: (_, __) => _KhatmaRouteErrorScaffold(
        title: 'Erreur réseau',
        message: 'Impossible de charger la Khatma. Vérifiez votre connexion.',
        onBack: () => _goBack(context),
        onRetry: () {
          ref.invalidate(khatmaLoadProvider(khatmaId));
          ref.invalidate(khatmaStreamProvider(khatmaId));
        },
        onMyKhatmas: () => context.go('/khatma'),
      ),
      data: (result) {
        if (result.failure == KhatmaLoadFailure.accessDenied) {
          return _KhatmaRouteErrorScaffold(
            title: 'Accès refusé',
            message: 'Vous n\'avez pas accès à cette Khatma.',
            onBack: () => _goBack(context),
            onMyKhatmas: () => context.go('/khatma'),
          );
        }
        if (result.failure == KhatmaLoadFailure.network) {
          return _KhatmaRouteErrorScaffold(
            title: 'Erreur réseau',
            message: 'Impossible de charger la Khatma. Vérifiez votre connexion.',
            onBack: () => _goBack(context),
            onRetry: () => ref.invalidate(khatmaLoadProvider(khatmaId)),
            onMyKhatmas: () => context.go('/khatma'),
          );
        }
        if (result.khatma != null) {
          return _buildExperience(result.khatma!);
        }
        return _KhatmaRouteErrorScaffold(
          title: 'Khatma introuvable',
          message: 'Cette Khatma n\'existe plus ou le lien n\'est pas valide.',
          onBack: () => _goBack(context),
          onMyKhatmas: () => context.go('/khatma'),
          secondaryActionLabel: 'Rejoindre avec un code',
          onSecondaryAction: () => context.go(KhatmaLinkService.joinPath(khatmaId)),
        );
      },
    );
  }

  Widget _buildExperience(Khatma khatma) {
    if (khatma.reservationMode &&
        KhatmaCompletionUtils.isFullyCompleted(khatma)) {
      return KhatmaCompletionScreen(
        khatma: khatma,
        playCelebrationAnimation: false,
      );
    }
    switch (khatmaExperienceFor(khatma)) {
      case KhatmaExperience.collaborative:
        return HizbReservationScreen(khatma: khatma, guestId: _effectiveGuestId);
      case KhatmaExperience.classic:
        return KhatmaDetailScreen(khatma: khatma);
    }
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/khatma');
    }
  }
}

class _KhatmaRouteLoadingScaffold extends StatelessWidget {
  const _KhatmaRouteLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khatma')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement de la Khatma...'),
          ],
        ),
      ),
    );
  }
}

class _KhatmaRouteErrorScaffold extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onBack;
  final VoidCallback? onRetry;
  final VoidCallback? onMyKhatmas;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const _KhatmaRouteErrorScaffold({
    required this.title,
    required this.message,
    required this.onBack,
    this.onRetry,
    this.onMyKhatmas,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khatma')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          EmptyState(
            fallbackIcon: Icons.error_outline,
            title: title,
            subtitle: message,
            actionLabel: onRetry != null ? 'Réessayer' : 'Retour',
            onAction: onRetry ?? onBack,
          ),
          if (onMyKhatmas != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onMyKhatmas,
              child: const Text('Mes Khatmas'),
            ),
          ],
          if (secondaryActionLabel != null && onSecondaryAction != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onSecondaryAction, child: Text(secondaryActionLabel!)),
          ],
        ],
      ),
    );
  }
}
