import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/figus_colors.dart';
import '../../data/repos/sync_repo.dart';
import 'pro_service.dart';

enum AppThemeSeed {
  // ── free (2 — 1 escuro + 1 claro) ────────────────────────────────────────
  gold('Dourado', Color(0xFFE5B14B), false, true),
  morning('Manhã', Color(0xFF1AB4D3), false, false),

  // ── pro · dark (8) ───────────────────────────────────────────────────────
  blue('Azul', Color(0xFF1F66FF), true, true),
  crimson('Vermelho', Color(0xFFCC1126), true, true),
  forest('Selva', Color(0xFF22A87E), true, true),
  navy('Profundo', Color(0xFF3F7AE0), true, true),
  royal('Realeza', Color(0xFF8A3FFC), true, true),
  sunset('Pôr-do-Sol', Color(0xFFFF7B3D), true, true),
  neon('Neon', Color(0xFFFF2D87), true, true),
  graphite('Grafite', Color(0xFF8C9099), true, true),

  // ── pro · light warm (3) ─────────────────────────────────────────────────
  emerald('Copa', Color(0xFF1A7A4A), true, false),
  sand('Areia', Color(0xFFB8843D), true, false),
  coffee('Café', Color(0xFF6E422A), true, false),

  // ── pro · light cool (2) ─────────────────────────────────────────────────
  violet('Papel', Color(0xFF6B3FA0), true, false),
  mint('Menta', Color(0xFF2A9E6F), true, false);

  final String label;
  final Color color;
  final bool proOnly;

  /// True → dark theme; false → light theme.
  final bool isDark;

  const AppThemeSeed(this.label, this.color, this.proOnly, this.isDark);

  /// Cool-toned light themes use the lavender [coolLight] palette; warm-toned
  /// light themes use the cream [warmLight] palette.
  static const _coolLightSeeds = {
    AppThemeSeed.morning,
    AppThemeSeed.violet,
    AppThemeSeed.mint,
  };

  FigusColors get figusColors {
    if (isDark) return FigusColors.dark;
    return _coolLightSeeds.contains(this)
        ? FigusColors.coolLight
        : FigusColors.warmLight;
  }

  String get description {
    switch (this) {
      // free
      case AppThemeSeed.gold:     return 'Dourado Figus · modo escuro';
      case AppThemeSeed.morning:  return 'Manhã turquesa · modo claro ☀️';
      // pro · dark
      case AppThemeSeed.blue:     return 'Azul clássico · modo escuro';
      case AppThemeSeed.crimson:  return 'Vermelho vibrante · modo escuro';
      case AppThemeSeed.forest:   return 'Verde selva · modo escuro';
      case AppThemeSeed.navy:     return 'Azul profundo · modo escuro';
      case AppThemeSeed.royal:    return 'Roxo real · modo escuro';
      case AppThemeSeed.sunset:   return 'Laranja pôr-do-sol · modo escuro';
      case AppThemeSeed.neon:     return 'Rosa neon · modo escuro';
      case AppThemeSeed.graphite: return 'Cinza neutro · modo escuro';
      // pro · light warm
      case AppThemeSeed.emerald:  return 'Copa verde · modo claro ☀️';
      case AppThemeSeed.sand:     return 'Areia quente · modo claro ☀️';
      case AppThemeSeed.coffee:   return 'Café tostado · modo claro ☀️';
      // pro · light cool
      case AppThemeSeed.violet:   return 'Papel roxo · modo claro ☀️';
      case AppThemeSeed.mint:     return 'Menta fresca · modo claro ☀️';
    }
  }
}

class ThemeSeedNotifier extends StateNotifier<AppThemeSeed> {
  final Ref ref;
  ThemeSeedNotifier(this.ref) : super(AppThemeSeed.gold) {
    // ignore: discarded_futures
    _init();
  }

  static const _key = 'theme_seed';
  // Remembers the most recent FREE theme the user picked, so when a Pro
  // theme can no longer be honored (trial expired, debug Pro off, etc.)
  // we fall back to what they were used to — not the default Dourado.
  static const _keyLastFree = 'theme_last_free_seed';
  AppThemeSeed _lastFreeSeed = AppThemeSeed.gold;
  AppThemeSeed get lastFreeSeed => _lastFreeSeed;

  Future<void> _init() async {
    await _load();
    // Wait for ProNotifier to finish its own prefs read so we don't demote
    // a legitimate Pro user during the boot race.
    await ref.read(proProvider.notifier).loaded;
    _enforceProGating(ref.read(proProvider));
    // React to subsequent Pro state changes (trial expires while running,
    // debug toggle off, purchase event, etc.). The listener is registered
    // AFTER the initial enforce so we don't double-fire.
    ref.listen<ProState>(proProvider, (prev, next) {
      _enforceProGating(next);
    });
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final lastFree = p.getString(_keyLastFree);
    if (lastFree != null) {
      final match = AppThemeSeed.values
          .where((t) => t.name == lastFree && !t.proOnly)
          .firstOrNull;
      if (match != null) _lastFreeSeed = match;
    }
    final saved = p.getString(_key);
    if (saved != null) {
      final match =
          AppThemeSeed.values.where((t) => t.name == saved).firstOrNull;
      if (match != null) state = match;
      // Don't gate here — _init() will gate against the Pro state once
      // ProNotifier has finished loading.
    }
  }

  /// Force-fall back to [_lastFreeSeed] (and persist) whenever the current
  /// state is a Pro-only seed but Pro is no longer active. Runs on boot
  /// after Pro is loaded AND on every subsequent Pro state change.
  void _enforceProGating(ProState pro) {
    if (pro.isActive) return;
    if (!state.proOnly) return;
    final fallback = _lastFreeSeed;
    state = fallback;
    // Persist the demoted seed so the next cold start renders the same
    // thing as the in-memory state. Fire-and-forget — UI already updated.
    // ignore: discarded_futures
    SharedPreferences.getInstance().then((p) {
      p.setString(_key, fallback.name);
    });
  }

  /// Apply a theme. Set [pushToCloud] false when applying a value that came
  /// FROM the cloud (avoids pushing it right back and creating a loop).
  Future<void> set(AppThemeSeed seed, {bool pushToCloud = true}) async {
    // Defense in depth: never persist a Pro theme for a non-Pro user, no
    // matter the call site (picker, paywall sheet, remote settings apply,
    // auto-sync). app.dart enforces visually too, but stopping the write
    // keeps the persisted state honest.
    final isPro = ref.read(proProvider).isActive;
    if (seed.proOnly && !isPro) {
      return;
    }
    state = seed;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, seed.name);
    if (!seed.proOnly) {
      _lastFreeSeed = seed;
      await p.setString(_keyLastFree, seed.name);
    }
    if (pushToCloud) {
      // ignore: discarded_futures
      ref.read(syncRepoProvider).pushUserSettings(theme: seed.name);
    }
  }
}

final themeSeedProvider = StateNotifierProvider<ThemeSeedNotifier, AppThemeSeed>(
  (ref) => ThemeSeedNotifier(ref),
);
