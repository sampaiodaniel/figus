import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'paywall_sheet.dart';
import 'pro_service.dart';
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
    super.dispose();
  }

  void _startPreview(AppThemeSeed seed) {
    _previewTimer?.cancel();
    setState(() {
      _previewing = seed;
      _previewSecsLeft = 10;
    });

    // Temporarily apply so the app shows the color
    ref.read(previewThemeSeedProvider.notifier).state = seed;

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
    ref.read(previewThemeSeedProvider.notifier).state = null;
    setState(() {
      _previewing = null;
      _previewSecsLeft = 0;
    });
    if (openPaywall && mounted) {
      showPaywall(context, trigger: PaywallContext.theme);
    }
  }

  Future<void> _selectTheme(AppThemeSeed seed, bool isPro) async {
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
    final currentSeed = ref.watch(themeSeedProvider);
    final isPro = ref.watch(proProvider).isActive;

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
                        const Icon(Icons.timer_rounded, size: 16, color: AppTheme.inkSoft),
                        const SizedBox(width: 4),
                        Text('$_previewSecsLeft s',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.inkSoft,
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
                for (final seed in AppThemeSeed.values) ...[
                  _ThemeTile(
                    seed: seed,
                    isSelected: currentSeed == seed,
                    isPro: isPro,
                    isPreviewing: _previewing == seed,
                    previewSecsLeft: _previewSecsLeft,
                    onTap: () => _selectTheme(seed, isPro),
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
          children: [
            // Color swatch
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: seed.color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: seed.color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
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
                                  ? AppTheme.inkSoft
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
                        style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                    const SizedBox(height: 2),
                    const Text('Toque para ver uma prévia',
                        style: TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
                  ] else if (isSelected)
                    Text(seed.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.inkSoft,
                          fontWeight: FontWeight.w600,
                        ))
                  else
                    Text(seed.description,
                        style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
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
