import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/figus_colors.dart';

enum AppThemeSeed {
  // free
  blue('Azul', Color(0xFF1F66FF), false, true),
  // pro — dark
  gold('Dourado', Color(0xFFE5B14B), true, true),
  crimson('Vermelho', Color(0xFFCC1126), true, true),
  // pro — light
  emerald('Copa', Color(0xFF1A7A4A), true, false),
  violet('Papel', Color(0xFF6B3FA0), true, false);

  final String label;
  final Color color;
  final bool proOnly;

  /// True → dark theme; false → light theme.
  final bool isDark;

  const AppThemeSeed(this.label, this.color, this.proOnly, this.isDark);

  FigusColors get figusColors {
    if (!isDark) {
      return this == AppThemeSeed.violet
          ? FigusColors.coolLight
          : FigusColors.warmLight;
    }
    return FigusColors.dark;
  }

  String get description {
    switch (this) {
      case AppThemeSeed.blue:    return 'Clássico · modo escuro';
      case AppThemeSeed.gold:    return 'Dourado quente · modo escuro';
      case AppThemeSeed.crimson: return 'Vermelho vibrante · modo escuro';
      case AppThemeSeed.emerald: return 'Copa verde · modo claro ☀️';
      case AppThemeSeed.violet:  return 'Papel roxo · modo claro ☀️';
    }
  }
}

class ThemeSeedNotifier extends StateNotifier<AppThemeSeed> {
  ThemeSeedNotifier() : super(AppThemeSeed.blue) {
    _load();
  }

  static const _key = 'theme_seed';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString(_key);
    if (saved == null) return;
    final match = AppThemeSeed.values.where((t) => t.name == saved).firstOrNull;
    if (match != null) state = match;
  }

  Future<void> set(AppThemeSeed seed) async {
    state = seed;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, seed.name);
  }
}

final themeSeedProvider = StateNotifierProvider<ThemeSeedNotifier, AppThemeSeed>(
  (_) => ThemeSeedNotifier(),
);
