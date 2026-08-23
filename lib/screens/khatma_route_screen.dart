import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/bootstrap/firebase_bootstrap.dart';
import '../core/extensions/l10n_extensions.dart';
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
    final user = tryFirebaseAuth()?.currentUser;
    if (user != null && user.isAnonymous) return user.uid;
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    if (khatmaId.isEmpty) {
      return _KhatmaRouteErrorScaffold(
        title: l10n.khatmaRouteNotFoundTitle,
        message: l10n.khatmaRouteNotFoundMessage,
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
      loading:
          () =>
              seed != null
                  ? _buildExperience(seed)
                  : _KhatmaRouteLoadingScaffold(
                    message: l10n.khatmaRouteLoading,
                  ),
      error:
          (_, __) => _KhatmaRouteErrorScaffold(
            title: l10n.khatmaRouteLoadErrorTitle,
            message: l10n.khatmaRouteLoadErrorMessage,
            onBack: () => _goBack(context),
            onRetry: () {
              ref.invalidate(khatmaLoadProvider(khatmaId));
              ref.invalidate(khatmaStreamProvider(khatmaId));
            },
            onMyKhatmas: () => context.go('/khatma'),
            retryLabel: l10n.retry,
            myKhatmasLabel: l10n.myKhatmas,
            backLabel: l10n.back,
            screenTitle: l10n.khatma,
          ),
      data: (result) {
        if (result.failure == KhatmaLoadFailure.accessDenied) {
          return _KhatmaRouteErrorScaffold(
            title: l10n.khatmaRouteAccessDeniedTitle,
            message: l10n.khatmaRouteAccessDeniedMessage,
            onBack: () => _goBack(context),
            onMyKhatmas: () => context.go('/khatma'),
            backLabel: l10n.back,
            myKhatmasLabel: l10n.myKhatmas,
            screenTitle: l10n.khatma,
          );
        }
        if (result.failure == KhatmaLoadFailure.network) {
          return _KhatmaRouteErrorScaffold(
            title: l10n.khatmaRouteNetworkErrorTitle,
            message: l10n.khatmaRouteNetworkErrorMessage,
            onBack: () => _goBack(context),
            onRetry: () => ref.invalidate(khatmaLoadProvider(khatmaId)),
            onMyKhatmas: () => context.go('/khatma'),
            retryLabel: l10n.retry,
            myKhatmasLabel: l10n.myKhatmas,
            backLabel: l10n.back,
            screenTitle: l10n.khatma,
          );
        }
        if (result.failure == KhatmaLoadFailure.demoUnavailable) {
          return _KhatmaRouteErrorScaffold(
            title: l10n.khatmaRouteDemoUnavailableTitle,
            message: l10n.khatmaRouteDemoUnavailableMessage,
            onBack: () => _goBack(context),
            onMyKhatmas: () => context.go('/khatma'),
            backLabel: l10n.back,
            myKhatmasLabel: l10n.myKhatmas,
            screenTitle: l10n.khatma,
          );
        }
        if (result.khatma != null) {
          return _buildExperience(result.khatma!);
        }
        return _KhatmaRouteErrorScaffold(
          title: l10n.khatmaRouteNotFoundTitle,
          message: l10n.khatmaRouteNotFoundMessage,
          onBack: () => _goBack(context),
          onMyKhatmas: () => context.go('/khatma'),
          secondaryActionLabel: l10n.joinWithCode,
          onSecondaryAction:
              () => context.go(KhatmaLinkService.joinPath(khatmaId)),
          backLabel: l10n.back,
          myKhatmasLabel: l10n.myKhatmas,
          screenTitle: l10n.khatma,
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
        return HizbReservationScreen(
          khatma: khatma,
          guestId: _effectiveGuestId,
        );
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
  const _KhatmaRouteLoadingScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.khatma)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _KhatmaRouteErrorScaffold extends StatelessWidget {
  const _KhatmaRouteErrorScaffold({
    required this.title,
    required this.message,
    required this.onBack,
    this.onRetry,
    this.onMyKhatmas,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.retryLabel,
    this.backLabel,
    this.myKhatmasLabel,
    this.screenTitle,
  });

  final String title;
  final String message;
  final VoidCallback onBack;
  final VoidCallback? onRetry;
  final VoidCallback? onMyKhatmas;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final String? retryLabel;
  final String? backLabel;
  final String? myKhatmasLabel;
  final String? screenTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actionLabel =
        onRetry != null ? (retryLabel ?? l10n.retry) : (backLabel ?? l10n.back);

    return Scaffold(
      appBar: AppBar(title: Text(screenTitle ?? l10n.khatma)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          EmptyState(
            fallbackIcon: Icons.error_outline,
            title: title,
            subtitle: message,
            actionLabel: actionLabel,
            onAction: onRetry ?? onBack,
          ),
          if (onMyKhatmas != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onMyKhatmas,
              child: Text(myKhatmasLabel ?? l10n.myKhatmas),
            ),
          ],
          if (secondaryActionLabel != null && onSecondaryAction != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onSecondaryAction,
              child: Text(secondaryActionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
