import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/figus_colors.dart';
import 'paywall_sheet.dart';
import 'pro_service.dart';
import 'theme_preview.dart';
import 'theme_service.dart';

class ThemePickerPage extends ConsumerStatefulWidget {
  const ThemePickerPage({super.key});
  @override
  ConsumerState<ThemePickerPage> createState() => _ThemePickerPageState();
}

class _ThemePickerPageState extends ConsumerState<ThemePickerPage> {
  AppThemeSeed? _previewing;
  int _previewSecsLeft = 0;
  Timer? _previewTimer;

  @override
  void dispose() {
    _previewTimer?.cancel();
    // If the user leaves mid-preview (back button, swipe, route change), the
    // preview seed could otherwise stay applied forever — the app would keep
    // showing the Pro theme they don't own, while the picker thinks the saved
    // theme is still active. Clear it on the way out.
    // ref.read is allowed in dispose for ConsumerState — Riverpod keeps the
    // container alive even as the widget tears down.
    ref.read(previewThemeSeedProvider.notifier).state = null;
    super.dispose();
  }

  void _startPreview(AppThemeSeed seed) {
    _previewTimer?.cancel();
    setState(() {
      _previewing = seed;
      _previewSecsLeft = 10;
    });

    // Temporarily apply so the app shows the color. Wrap in try/catch so a
    // bad theme color (e.g. a paint shader that fails on this device) can't
    // tank the whole app — we'd rather log it and back out of the preview.
    try {
      ref.read(previewThemeSeedProvider.notifier).state = seed;
    } catch (e, st) {
      debugPrint('[ThemePicker] preview start failed for ${seed.name}: $e\n$st');
      setState(() {
        _previewing = null;
        _previewSecsLeft = 0;
      });
      return;
    }

    _previewTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _previewSecsLeft--);
      if (_previewSecsLeft <= 0) {
        t.cancel();
        _endPreview(openPaywall: true);
      }
    });
  }

  void _endPreview({bool openPaywall = false}) {
    _previewTimer?.cancel();
    // Clear preview override BEFORE rebuilding our own state and BEFORE
    // opening the paywall. `invalidate` forces every watcher to re-resolve,
    // including FigusApp's themeMode/theme builders.
    ref.invalidate(previewThemeSeedProvider);
    if (!mounted) return;
    setState(() {
      _previewing = null;
      _previewSecsLeft = 0;
    });
    if (openPaywall) {
      // Defer until the theme rebuild lands so the paywall opens on top of
      // the restored theme, not the preview one.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showPaywall(context, trigger: PaywallContext.theme);
      });
    }
  }

  Future<void> _selectTheme(AppThemeSeed seed) async {
    // Read fresh from the provider — passing it through the widget tree had
    // a habit of going stale after the debug Pro toggle.
    final proState = ref.read(proProvider);
    final isPro = proState.isActive;
    debugPrint('[ThemePicker] tap seed=${seed.name} proOnly=${seed.proOnly} '
        'isPro=$isPro isActive=$isPro isTrial=${proState.isTrial} '
        'trialDaysLeft=${proState.trialDaysLeft}');
    if (!seed.proOnly || isPro) {
      // Apply directly
      await ref.read(themeSeedProvider.notifier).set(seed);
      ref.read(previewThemeSeedProvider.notifier).state = null;
      if (mounted) Navigator.pop(context);
      return;
    }
    // Pro-only: offer 10s preview then paywall
    _startPreview(seed);
  }

  @override
  Widget build(BuildContext context) {
    final savedSeed = ref.watch(themeSeedProvider);
    final isPro = ref.watch(proProvider).isActive;
    // Show as "current" whichever seed is actually rendering — matches
    // app.dart's enforcedSaved gating so the picker doesn't claim a Pro
    // theme is active while the app is silently rendering Dourado/Manhã.
    final currentSeed = (savedSeed.proOnly && !isPro)
        ? ref.read(themeSeedProvider.notifier).lastFreeSeed
        : savedSeed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Temas'),
        actions: _previewing != null
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_rounded, size: 16, color: context.fc.textMuted),
                        const SizedBox(width: 4),
                        Text('$_previewSecsLeft s',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: context.fc.textMuted,
                            )),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () => _endPreview(openPaywall: false),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kDebugMode)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPro
                    ? const Color(0xFFE5B14B).withValues(alpha: 0.20)
                    : context.fc.cardAlt,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'DEBUG · Pro state: ${isPro ? "ATIVO (trial ou Pro)" : "INATIVO"}'
                ' · proOnly check ${isPro ? "BYPASS" : "ATIVO"}',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: context.fc.text,
                ),
              ),
            ),
          if (!isPro)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.seed, Color(0xFF7A5BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Temas com ★ são exclusivos do Pro. Toque para ver uma prévia de 10 segundos.',
                      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                _SectionHeader(title: 'Grátis para todos'),
                for (final seed in AppThemeSeed.values.where((s) => !s.proOnly)) ...[
                  _ThemeTile(
                    seed: seed,
                    isSelected: currentSeed == seed,
                    isPro: isPro,
                    isPreviewing: _previewing == seed,
                    previewSecsLeft: _previewSecsLeft,
                    onTap: () => _selectTheme(seed),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
                _SectionHeader(title: 'Pro · modo escuro'),
                for (final seed in AppThemeSeed.values.where((s) => s.proOnly && s.isDark)) ...[
                  _ThemeTile(
                    seed: seed,
                    isSelected: currentSeed == seed,
                    isPro: isPro,
                    isPreviewing: _previewing == seed,
                    previewSecsLeft: _previewSecsLeft,
                    onTap: () => _selectTheme(seed),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
                _SectionHeader(title: 'Pro · modo claro ☀️'),
                for (final seed in AppThemeSeed.values.where((s) => s.proOnly && !s.isDark)) ...[
                  _ThemeTile(
                    seed: seed,
                    isSelected: currentSeed == seed,
                    isPro: isPro,
                    isPreviewing: _previewing == seed,
                    previewSecsLeft: _previewSecsLeft,
                    onTap: () => _selectTheme(seed),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final AppThemeSeed seed;
  final bool isSelected;
  final bool isPro;
  final bool isPreviewing;
  final int previewSecsLeft;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.seed,
    required this.isSelected,
    required this.isPro,
    required this.isPreviewing,
    required this.previewSecsLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = seed.proOnly && !isPro;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected || isPreviewing
                ? seed.color
                : Colors.transparent,
            width: 2,
          ),
          color: isSelected || isPreviewing
              ? seed.color.withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Mini mockup do app no tema — vale 1000 swatches
            ThemePreview(seed: seed, width: 70),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(seed.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          )),
                      if (seed.proOnly) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: locked
                                ? AppTheme.slotSoft
                                : const Color(0xFFB8860B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            locked ? '★ Pro' : '★',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: locked
                                  ? context.fc.textMuted
                                  : const Color(0xFFB8860B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isPreviewing)
                    Text(
                      'Prévia: ${previewSecsLeft}s restantes',
                      style: TextStyle(
                        fontSize: 12,
                        color: seed.color,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (locked) ...[
                    Text(seed.description,
                        style: TextStyle(fontSize: 12, color: context.fc.textMuted)),
                    const SizedBox(height: 2),
                    Text('Toque para ver uma prévia',
                        style: TextStyle(fontSize: 11, color: context.fc.textMuted)),
                  ] else if (isSelected)
                    Text(seed.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.fc.textMuted,
                          fontWeight: FontWeight.w600,
                        ))
                  else
                    Text(seed.description,
                        style: TextStyle(fontSize: 12, color: context.fc.textMuted)),
                ],
              ),
            ),
            if (isSelected && !isPreviewing)
              Icon(Icons.check_circle_rounded, color: seed.color, size: 24),
          ],
        ),
      ),
    );
  }
}

// Temporary override during theme preview (does NOT persist to disk)
final previewThemeSeedProvider = StateProvider<AppThemeSeed?>((ref) => null);

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: context.fc.textMuted,
        ),
      ),
    );
  }
}
