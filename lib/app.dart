import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';

import 'core/debug/mobile_preview.dart';
import 'core/theme/app_theme.dart';
import 'data/auto_sync_observer.dart';
import 'features/achievements/achievements_page.dart';
import 'features/ads/banner_ad_widget.dart';
import 'features/ads/banner_gallery_page.dart';
import 'features/pro/pro_service.dart';
import 'features/ads/interstitial_helper.dart';
import 'features/pro/theme_picker_page.dart';
import 'features/pro/theme_service.dart';
import 'features/album/album_page.dart';
import 'features/album/nation_detail_page.dart';
import 'features/copa/copa_page.dart';
import 'features/duplicates/duplicates_page.dart';
import 'features/import/figuritas_import_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/profiles/avatar_picker_page.dart';
import 'features/profiles/profiles_page.dart';
import 'features/scan/scan_page.dart';
import 'features/settings/upgrade_page.dart';
import 'features/stats/stats_page.dart';
import 'features/trades/compare_friend_page.dart';
import 'features/trades/trade_matcher.dart';
import 'features/trades/trade_qr_page.dart';
import 'features/trades/trades_page.dart';
import 'features/auth/auth_page.dart';
import 'features/donate/donate_page.dart';
import 'features/help/help_page.dart';
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
    // Effective seed:
    //  · `previewSeed` wins for the 10s demo
    //  · otherwise the user's saved seed, BUT enforce Pro gating: if the
    //    saved theme is Pro-only and the user isn't Pro (trial expired,
    //    debug Pro turned off, etc.), fall back to the LAST FREE seed the
    //    user picked — Dourado as ultimate default — so we never leak Pro
    //    visuals to non-Pro users but also don't yank away the look they
    //    chose for themselves.
    final savedSeed = ref.watch(themeSeedProvider);
    final previewSeed = ref.watch(previewThemeSeedProvider);
    final isPro = ref.watch(proProvider).isActive;
    final enforcedSaved = (savedSeed.proOnly && !isPro)
        ? ref.read(themeSeedProvider.notifier).lastFreeSeed
        : savedSeed;
    final effectiveSeed = previewSeed ?? enforcedSaved;

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
        GoRoute(path: '/achievements', builder: (_, __) => const AchievementsPage()),
        GoRoute(path: '/themes', builder: (_, __) => const ThemePickerPage()),

        GoRoute(path: '/auth', builder: (_, __) => const AuthPage()),
        GoRoute(path: '/profiles', builder: (_, __) => const ProfilesPage()),
        GoRoute(path: '/avatars', builder: (_, __) => const AvatarPickerPage()),
        GoRoute(path: '/import', builder: (_, __) => const FiguritasImportPage()),
        GoRoute(path: '/upgrade', builder: (_, __) => const UpgradePage()),
        GoRoute(path: '/favorites', builder: (_, __) => const FavoriteNationsPage()),
        GoRoute(path: '/names-import', builder: (_, __) => const PlayerNamesImportPage()),
        GoRoute(
          path: '/compare',
          builder: (_, state) => CompareFriendPage(
            initialFriend: state.extra is TradeInventory
                ? state.extra as TradeInventory
                : null,
          ),
        ),
        GoRoute(
          path: '/trade-qr',
          builder: (_, state) => TradeQrPage(
            mode: state.uri.queryParameters['mode'] ?? 'show',
          ),
        ),
        GoRoute(path: '/donate', builder: (_, __) => const DonatePage()),
        GoRoute(path: '/how-to', builder: (_, __) => const HelpPage()),
        GoRoute(path: '/help', builder: (_, __) => const HelpPage()),
        GoRoute(path: '/debug/banners', builder: (_, __) => const BannerGalleryPage()),
      ],
    );

    // Preload interstitial on app start
    InterstitialHelper.preload();

    // Global error handler so a single bad widget doesn't tank the
    // process — Flutter's default presents a red error screen in debug
    // and prints to logs in release. Without this hook a crash inside a
    // build can corrupt mid-write SQLite state on the next launch.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('[FigusApp] uncaught: ${details.exception}');
    };

    return MaterialApp.router(
      title: 'Figus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(
        overrideSeed: effectiveSeed.color,
        figusColors: effectiveSeed.figusColors,
      ),
      darkTheme: AppTheme.dark(
        overrideSeed: effectiveSeed.color,
        figusColors: effectiveSeed.figusColors,
      ),
      themeMode: effectiveSeed.isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      // Wrap every route so debug mobile-preview clipping is global,
      // and the auto-sync lifecycle observer is mounted once at the root.
      builder: (context, child) => AutoSyncObserver(
        child: MobilePreviewWrapper(
          child: kDebugMode
              ? _ThemeDebugOverlay(
                  saved: savedSeed,
                  preview: previewSeed,
                  effective: effectiveSeed,
                  lastFree: ref
                      .read(themeSeedProvider.notifier)
                      .lastFreeSeed,
                  isPro: isPro,
                  child: child ?? const SizedBox(),
                )
              : (child ?? const SizedBox()),
        ),
      ),
    );
  }
}

/// Debug-only overlay that pins a tiny strip at the top showing the actual
/// theme resolution so we can see exactly what the engine is rendering vs
/// what the picker thinks is selected.
class _ThemeDebugOverlay extends StatelessWidget {
  final AppThemeSeed saved;
  final AppThemeSeed? preview;
  final AppThemeSeed effective;
  final AppThemeSeed lastFree;
  final bool isPro;
  final Widget child;

  const _ThemeDebugOverlay({
    required this.saved,
    required this.preview,
    required this.effective,
    required this.lastFree,
    required this.isPro,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: IgnorePointer(
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  'saved=${saved.name}${saved.proOnly ? "*" : ""} '
                  'prev=${preview?.name ?? "-"} '
                  'eff=${effective.name} '
                  'lastFree=${lastFree.name} '
                  'pro=${isPro ? "Y" : "N"}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
    _NavItem('/copa', Icons.emoji_events_rounded, 'Copa'),
    _NavItem('/you', Icons.settings_rounded, 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final activeIndex = _navTabs.indexWhere((t) => loc == t.path);
    return Scaffold(
      body: Column(
        children: [
          const BannerAdWidget(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        // Compact labels so 5 tabs fit without wrapping on narrow tablets/phones.
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        child: NavigationBar(
          selectedIndex: activeIndex < 0 ? 0 : activeIndex,
          onDestinationSelected: (i) => context.go(_navTabs[i].path),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 64,
          destinations: [
            for (final t in _navTabs)
              NavigationDestination(icon: Icon(t.icon), label: t.label),
          ],
        ),
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

class _SimplePage extends StatelessWidget {
  final String title;
  final String body;
  const _SimplePage({required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(body, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16)),
      )),
    );
  }
}
