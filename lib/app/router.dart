import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/web/legacy_join_url_bridge.dart';

import '../screens/home_screen.dart';
import '../screens/auth_welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/khatma_screen.dart';
import '../screens/hizb_distribution_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/mushaf_selection_screen.dart';
import '../screens/mushaf_hafs_screen.dart';
import '../screens/mushaf_warsh_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/training_screen.dart';
import '../screens/course_detail_screen.dart';
import '../screens/lesson_screen.dart';
import '../screens/wird_screen.dart';
import '../core/models/khatma.dart';
import '../core/providers/auth_provider.dart';
import '../features/formations/models/course.dart';
import '../features/formations/providers/formations_providers.dart';
import '../core/services/khatma_link_service.dart';
import '../core/constants/hizb_definitions.dart';
import '../core/models/mushaf_open_target.dart';
import '../screens/khatma_route_screen.dart';
import '../screens/khatma_completion_screen.dart';
import '../screens/mushaf_women_screen.dart';
import '../l10n/gen_l10n/app_localizations.dart';
import '../design_system/anis_design_system.dart';
import '../core/widgets/anis_icon.dart';

/// Notifie GoRouter lorsque l'auth, le mode démo ou un hash legacy change.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(demoModeProvider, (_, __) => notifyListeners());
    if (kIsWeb) {
      listenLegacyJoinHashChanges(notifyListeners);
    }
  }
}

final _routerRefreshProvider = Provider<_RouterRefreshNotifier>(
  (ref) => _RouterRefreshNotifier(ref),
);

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(_routerRefreshProvider);

  final initialLocation = () {
    if (kIsWeb) {
      final legacy = KhatmaLinkService.redirectPathForLegacyJoinUri(Uri.base);
      if (legacy != null) {
        stripLegacyJoinFragment(legacy);
        return legacy;
      }
    }
    return '/auth';
  }();

  return GoRouter(
    initialLocation: initialLocation,
    debugLogDiagnostics: true,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      if (kIsWeb) {
        final legacyJoin = KhatmaLinkService.redirectPathForLegacyJoinUri(
          Uri.base,
        );
        if (legacyJoin != null && state.uri.path != legacyJoin) {
          stripLegacyJoinFragment(legacyJoin);
          return legacyJoin;
        }
      }

      final isDemo = ref.read(demoModeProvider);
      final authReadiness = ref.read(authReadinessProvider);

      // Prevent login screen flash during session restoration
      if (authReadiness.status == AuthStatus.initializing) {
        return null; // Stay on current route during initialization
      }

      final isLoggedIn = isDemo || authReadiness.status == AuthStatus.signedIn;
      final isAuthScreen =
          state.matchedLocation == '/auth' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isJoinRoute = state.matchedLocation.startsWith('/join/');

      if (!isLoggedIn && !isAuthScreen && !isJoinRoute) {
        return '/auth';
      }
      if (isLoggedIn && isAuthScreen) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthWelcomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/mushaf',
        builder: (context, state) => const MushafSelectionScreen(),
      ),
      GoRoute(
        path: '/mushaf/hafs',
        builder: (context, state) {
          final t = MushafOpenTarget.fromRoute(state.extra, state.uri);
          return MushafHafsScreen(
            initialSurah: t.surah,
            initialVerse: t.verse,
            initialPage: t.page,
            initialHizb: t.hizb,
            hizbDefinitionId:
                t.hizb == null
                    ? null
                    : (t.hizbDefinitionId ??
                        HizbDefinitions.quranFoundationHafsV1),
            resumePage: t.resumePage,
          );
        },
      ),
      GoRoute(
        path: '/mushaf/warsh',
        builder: (context, state) {
          final t = MushafOpenTarget.fromRoute(state.extra, state.uri);
          return MushafWarshScreen(
            initialSurah: t.surah,
            initialVerse: t.verse,
            initialPage: t.page,
            initialHizb: t.hizb,
            hizbDefinitionId:
                t.hizb == null
                    ? null
                    : (t.hizbDefinitionId ??
                        HizbDefinitions.quranFoundationHafsV1),
            resumePage: t.resumePage,
          );
        },
      ),
      GoRoute(
        path: '/mushaf/women',
        builder: (context, state) {
          final t = MushafOpenTarget.fromRoute(state.extra, state.uri);
          return MushafWomenScreen(
            initialSurah: t.surah,
            initialVerse: t.verse,
            initialPage: t.page,
            initialHizb: t.hizb,
            hizbDefinitionId:
                t.hizb == null
                    ? null
                    : (t.hizbDefinitionId ??
                        HizbDefinitions.quranFoundationHafsV1),
            resumePage: t.resumePage,
          );
        },
      ),
      GoRoute(
        path: '/join/:id',
        builder: (context, state) {
          final rawId = state.pathParameters['id'] ?? '';
          final khatmaId = KhatmaLinkService.normalizeJoinKhatmaId(rawId) ?? '';
          final guestId = state.uri.queryParameters['guestId'];
          return KhatmaRouteScreen(
            khatmaId: khatmaId,
            guestId: guestId,
          );
        },
      ),
      GoRoute(
        path: KhatmaLinkService.distributePath,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return HizbDistributionScreen(
            khatmaTitle: extra['title'] as String? ?? 'Ma Khatma',
            khatmaObjectives: extra['objectives'] as String?,
            isGroup: extra['isGroup'] as bool? ?? false,
            members: List<String>.from(extra['members'] as List? ?? []),
          );
        },
      ),
      GoRoute(
        path: '/khatma/:id/completion',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final preloaded = extra?['khatma'] as Khatma?;
          final playCelebration = extra?['playCelebration'] as bool? ?? false;
          final seed =
              preloaded ??
              Khatma(
                id: id,
                title: '',
                isGroup: false,
                createdBy: '',
                createdAt: DateTime.now(),
              );
          return KhatmaCompletionScreen(
            khatma: seed,
            playCelebrationAnimation: playCelebration,
          );
        },
      ),
      GoRoute(
        path: '/khatma/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final preloaded = extra?['khatma'] as Khatma?;
          final guestId = extra?['guestId'] as String?;
          return KhatmaRouteScreen(
            khatmaId: id,
            preloadedKhatma: preloaded,
            guestId: guestId,
          );
        },
      ),
      ShellRoute(
        builder:
            (context, state, child) =>
                _MainShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: AnisHomePage()),
          ),
          GoRoute(
            path: '/khatma',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: KhatmaScreen()),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: NotificationsScreen()),
          ),
          GoRoute(
            path: '/wird',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: WirdScreen()),
          ),
          GoRoute(
            path: '/training',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: TrainingScreen()),
          ),
          GoRoute(
            path: '/formations/:courseId',
            pageBuilder: (context, state) {
              final courseId = state.pathParameters['courseId']!;
              final extra = state.extra as Map<String, dynamic>?;
              final course = extra?['course'] as Course?;

              if (course != null) {
                return NoTransitionPage(
                  child: CourseDetailScreen(course: course),
                );
              }

              // Fallback: fetch course by ID
              return NoTransitionPage(
                child: FutureBuilder<Course?>(
                  future: ProviderScope.containerOf(context)
                      .read(courseDetailProvider(courseId).future),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return Scaffold(
                        appBar: AppBar(),
                        body: const Center(child: Text('Course not found')),
                      );
                    }

                    return CourseDetailScreen(course: snapshot.data!);
                  },
                ),
              );
            },
          ),
          GoRoute(
            path: '/formations/:courseId/lessons/:lessonId',
            pageBuilder: (context, state) {
              final courseId = state.pathParameters['courseId']!;
              final lessonId = state.pathParameters['lessonId']!;

              return NoTransitionPage(
                child: LessonScreen(
                  courseId: courseId,
                  lessonId: lessonId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/settings',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );
});

class _MainShell extends StatelessWidget {
  final String location;
  final Widget child;

  const _MainShell({required this.location, required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _shellNavigationItems(l10n);
    final currentIndex = _calculateSelectedIndex(location);
    final onSelected = (int index) => _onItemTapped(context, index);
    final content = AnisShellContent(child: child);

    if (AnisResponsiveLayout.usesSideNavigation(context)) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnisSideNavigation(
              items: items,
              currentIndex: currentIndex,
              onSelected: onSelected,
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      body: content,
      bottomNavigationBar: AnisBottomNavigation(
        currentIndex: currentIndex,
        onSelected: onSelected,
        items: items,
      ),
    );
  }

  static List<AnisNavigationItem> _shellNavigationItems(AppLocalizations l10n) => [
    AnisNavigationItem(label: l10n.home, icon: AnisIconType.home),
    AnisNavigationItem(label: l10n.khatma, icon: AnisIconType.khatma),
    AnisNavigationItem(label: l10n.formations, icon: AnisIconType.training), // Using training icon
    AnisNavigationItem(label: l10n.wird, icon: AnisIconType.wird),
    AnisNavigationItem(label: l10n.settings, icon: AnisIconType.settings),
  ];

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/khatma')) return 1;
    if (location.startsWith('/training') || location.startsWith('/formations')) return 2; // Formations
    if (location.startsWith('/wird')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    final currentPath = GoRouterState.of(context).uri.path;

    switch (index) {
      case 0:
        // Accueil: no-op if already at root
        if (currentPath != '/') context.go('/');
        break;
      case 1:
        // Khatma: no-op if already at /khatma
        if (currentPath != '/khatma') context.go('/khatma');
        break;
      case 2:
        // Formations: always navigate to /training (resets nested routes)
        context.go('/training');
        break;
      case 3:
        // Wird: no-op if already at /wird
        if (currentPath != '/wird') context.go('/wird');
        break;
      case 4:
        // Settings: no-op if already at /settings
        if (currentPath != '/settings') context.go('/settings');
        break;
    }
  }
}
