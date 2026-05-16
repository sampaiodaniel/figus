import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart' show onboardedProvider;
import '../../core/theme/app_theme.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});
  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _ctrl = PageController();
  int _index = 0;
  static const _total = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inkDeep,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                child: _index < _total - 1
                    ? TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(foregroundColor: AppTheme.creamSoft),
                        child: const Text('Pular'),
                      )
                    : const SizedBox(height: 40),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _index = i),
                children: const [
                  _Slide0(),
                  _Slide1(),
                  _Slide2(),
                  _Slide3(),
                ],
              ),
            ),

            // Page dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_total, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppTheme.gold : AppTheme.ink4,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // CTA button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.inkDeep,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                onPressed: () async {
                  if (_index < _total - 1) {
                    _ctrl.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut);
                  } else {
                    await _finish();
                  }
                },
                child: Text(_index < _total - 1 ? 'Próximo' : 'Entrar no álbum'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    ref.invalidate(onboardedProvider);
    if (mounted) context.go('/');
  }
}

// ── Slide 0 — Hero ────────────────────────────────────────────────────────────

class _Slide0 extends StatelessWidget {
  const _Slide0();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo placeholder (ball icon in golden circle)
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.gold, AppTheme.goldDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.sports_soccer_rounded,
                color: AppTheme.inkDeep, size: 52),
          ),
          const SizedBox(height: 36),
          Text(
            'Figus',
            style: GoogleFonts.inter(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: AppTheme.cream,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sua coleção, raríssima.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.goldSoft,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.ink3,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Copa do Mundo 2026 · 980 figurinhas',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: AppTheme.creamSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide 1 — Marcar ─────────────────────────────────────────────────────────

class _Slide1 extends StatelessWidget {
  const _Slide1();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mini album grid demo
          SizedBox(
            width: 200,
            height: 160,
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (int i = 0; i < 12; i++)
                  _DemoCard(owned: i < 5, dupe: i == 2 || i == 4),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Text('Toque para marcar.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppTheme.cream,
                height: 1.1,
              )),
          const SizedBox(height: 8),
          Text('Toque novamente para adicionar outra cópia.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.creamSoft,
                fontSize: 15,
                height: 1.4,
              )),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final bool owned;
  final bool dupe;
  const _DemoCard({required this.owned, required this.dupe});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: owned ? null : AppTheme.inkDeep,
            gradient: owned
                ? const LinearGradient(
                    colors: [AppTheme.gold, AppTheme.goldDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(6),
            border: owned ? null : Border.all(color: AppTheme.ink4),
          ),
        ),
        if (dupe)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.pulp,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.inkDeep, width: 1.5),
              ),
              child: const Center(
                child: Text('2',
                    style: TextStyle(
                        color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Slide 2 — Trocas ─────────────────────────────────────────────────────────

class _Slide2 extends StatelessWidget {
  const _Slide2();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TradePill(code: 'BRA 5', color: AppTheme.gold),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.swap_horiz_rounded,
                    color: AppTheme.creamSoft, size: 32),
              ),
              _TradePill(code: 'ARG 11', color: AppTheme.pulp),
            ],
          ),
          const SizedBox(height: 36),
          Text('O Figus encontra o\nmatch pra você.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppTheme.cream,
                height: 1.1,
              )),
          const SizedBox(height: 8),
          const Text(
            'Compartilhe sua coleção e receba sugestões automáticas de troca com amigos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.creamSoft, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _TradePill extends StatelessWidget {
  final String code;
  final Color color;
  const _TradePill({required this.code, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(code,
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          )),
    );
  }
}

// ── Slide 3 — Favoritos ──────────────────────────────────────────────────────

class _Slide3 extends StatelessWidget {
  const _Slide3();

  static const _countries = [
    ('BRA', AppTheme.gold), ('ARG', AppTheme.sky), ('FRA', AppTheme.sky),
    ('ESP', AppTheme.flame), ('GER', AppTheme.creamSoft), ('ING', AppTheme.flame),
    ('POR', AppTheme.field), ('NED', AppTheme.flame), ('USA', AppTheme.sky),
    ('MEX', AppTheme.field), ('URU', AppTheme.sky), ('BEL', AppTheme.flame),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Country grid
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.3,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final (code, color) in _countries)
                _CountryChip(code: code, color: color, selected: code == 'BRA' || code == 'ARG'),
            ],
          ),
          const SizedBox(height: 32),
          Text('Escolha suas favoritas.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppTheme.cream,
                height: 1.1,
              )),
          const SizedBox(height: 8),
          const Text(
            'Prioridade nas alertas de jogos e nas sugestões de troca.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.creamSoft, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _CountryChip extends StatelessWidget {
  final String code;
  final Color color;
  final bool selected;
  const _CountryChip({required this.code, required this.color, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.2) : AppTheme.ink,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? color : AppTheme.ink4,
          width: selected ? 1.5 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        code,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: selected ? color : AppTheme.creamSoft,
        ),
      ),
    );
  }
}
