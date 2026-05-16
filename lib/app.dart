import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/album/album_page.dart';
import 'features/album/nation_detail_page.dart';
import 'features/copa/copa_page.dart';
import 'features/duplicates/duplicates_page.dart';
import 'features/import/figuritas_import_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/profiles/profiles_page.dart';
import 'features/scan/scan_page.dart';
import 'features/settings/upgrade_page.dart';
import 'features/stats/stats_page.dart';
import 'features/trades/compare_friend_page.dart';
import 'features/trades/trades_page.dart';
import 'features/you/favorite_nations_page.dart';
import 'features/you/player_names_import_page.dart';
import 'features/you/you_page.dart';

final onboardedProvider = FutureProvider<bool>((_) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarded') ?? false;
});

class FigusApp extends ConsumerWidget {
  const FigusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardedAsync = ref.watch(onboardedProvider);
    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final onboarded = onboardedAsync.value ?? true;
        if (!onboarded && state.matchedLocation != '/onboarding') return '/onboarding';
        return null;
      },
      routes: [
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
        ShellRoute(
          builder: (_, __, child) => RootShell(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const AlbumPage()),
            GoRoute(path: '/duplicates', builder: (_, __) => const DuplicatesPage()),
            GoRoute(path: '/copa', builder: (_, __) => const CopaPage()),
            GoRoute(path: '/trades', builder: (_, __) => const TradesPage()),
            GoRoute(path: '/you', builder: (_, __) => const YouPage()),
          ],
        ),
        GoRoute(
          path: '/nation/:code',
          builder: (_, state) => NationDetailPage(code: state.pathParameters['code']!),
        ),
        GoRoute(path: '/scan', builder: (_, __) => const ScanPage()),
        GoRoute(path: '/progress', builder: (_, __) => const StatsPage()),
        GoRoute(path: '/profiles', builder: (_, __) => const ProfilesPage()),
        GoRoute(path: '/import', builder: (_, __) => const FiguritasImportPage()),
        GoRoute(path: '/upgrade', builder: (_, __) => const UpgradePage()),
        GoRoute(path: '/favorites', builder: (_, __) => const FavoriteNationsPage()),
        GoRoute(path: '/names-import', builder: (_, __) => const PlayerNamesImportPage()),
        GoRoute(path: '/compare', builder: (_, __) => const CompareFriendPage()),
      ],
    );

    return MaterialApp.router(
      title: 'Figus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}

class RootShell extends StatelessWidget {
  final Widget child;
  const RootShell({super.key, required this.child});

  static const _navTabs = <_NavItem>[
    _NavItem('/', Icons.grid_view_rounded, 'Coleção'),
    _NavItem('/duplicates', Icons.copy_all_rounded, 'Repetidas'),
    _NavItem('/trades', Icons.swap_horiz_rounded, 'Trocas'),
    _NavItem('/you', Icons.person_rounded, 'Você'),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final activeIndex = _navTabs.indexWhere((t) => loc == t.path);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: activeIndex < 0 ? 0 : activeIndex,
        onTap: (i) => context.go(_navTabs[i].path),
        type: BottomNavigationBarType.fixed,
        items: [
          for (final t in _navTabs)
            BottomNavigationBarItem(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final String label;
  const _NavItem(this.path, this.icon, this.label);
}
