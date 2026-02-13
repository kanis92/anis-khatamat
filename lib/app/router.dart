import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/khatma_screen.dart';
import '../screens/hizb_distribution_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/khatma_detail_screen.dart';
import '../screens/mushaf_selection_screen.dart';
import '../screens/mushaf_hafs_screen.dart';
import '../screens/mushaf_warsh_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/training_screen.dart';
import '../core/models/khatma.dart';
import '../core/providers/auth_provider.dart';
import '../l10n/gen_l10n/app_localizations.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isDemo = ref.watch(demoModeProvider);
      final isLoggedIn = isDemo || authState.valueOrNull != null;
      final isAuthScreen =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isLoggingIn = isAuthScreen;

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
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
        builder: (context, state) => const MushafHafsScreen(),
      ),
      GoRoute(
        path: '/mushaf/warsh',
        builder: (context, state) => const MushafWarshScreen(),
      ),
      GoRoute(
        path: '/khatma/:id',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final khatma = extra['khatma'];
          if (khatma == null) return const SizedBox.shrink();
          return KhatmaDetailScreen(khatma: khatma as Khatma);
        },
      ),
      GoRoute(
        path: '/khatma/distribute',
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
      ShellRoute(
        builder: (context, state, child) =>
            _MainShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/khatma',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: KhatmaScreen()),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NotificationsScreen()),
          ),
          GoRoute(
            path: '/training',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TrainingScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
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
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(location),
        onDestinationSelected: (index) => _onItemTapped(context, index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: AppLocalizations.of(context)!.khatma,
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_outlined),
            selectedIcon: const Icon(Icons.notifications),
            label: AppLocalizations.of(context)!.notifications,
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school),
            label: AppLocalizations.of(context)!.training,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settings,
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/khatma')) return 1;
    if (location.startsWith('/notifications')) return 2;
    if (location.startsWith('/training')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/khatma');
        break;
      case 2:
        context.go('/notifications');
        break;
      case 3:
        context.go('/training');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }
}
