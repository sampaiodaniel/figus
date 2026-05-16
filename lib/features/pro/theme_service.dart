import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeSeed {
  blue('Azul', Color(0xFF1F66FF), false),
  gold('Dourado', Color(0xFFB8860B), true),
  crimson('Vermelho', Color(0xFFCC1126), true),
  emerald('Esmeralda', Color(0xFF007A5A), true),
  violet('Roxo', Color(0xFF6B3FA0), true);

  final String label;
  final Color color;
  final bool proOnly;
  const AppThemeSeed(this.label, this.color, this.proOnly);
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
