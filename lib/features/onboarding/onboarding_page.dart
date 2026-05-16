import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart' show onboardedProvider;
import '../../core/theme/app_theme.dart';
import '../../core/theme/figus_colors.dart';

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
    final c = context.fc;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        // Cap the onboarding to a mobile-sized column so the layout doesn't
        // explode on wide desktop browsers — slides were designed for ~400px.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                // Dot indicators
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_total, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 22 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? c.accent
                              : c.text.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
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

                // Bottom nav row
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                  child: Row(
                    children: [
                      if (_index < _total - 1)
                        TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(
                            foregroundColor: c.text.withValues(alpha: 0.5),
                          ),
                          child: const Text('Pular'),
                        )
                      else
                        const SizedBox.shrink(),
                      const Spacer(),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: c.accent,
                          foregroundColor: scheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999)),
                          textStyle: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w700),
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
                        child: Text(
                            _index < _total - 1 ? 'Próximo' : 'Entrar no álbum'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Sticker cards stack
        LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          return SizedBox(
            height: 280,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Card 1 — left, rotate -0.2 rad
                Positioned(
                  left: w * 0.08,
                  top: 30,
                  child: Transform.rotate(
                    angle: -0.2,
                    child: _StickerCard(
                      gradient: const LinearGradient(
                        colors: [AppTheme.gold, AppTheme.goldDeep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shadowColor: AppTheme.gold,
                      label: '#073',
                    ),
                  ),
                ),
                // Card 2 — center
                Positioned(
                  left: w * 0.38,
                  top: 10,
                  child: _StickerCard(
                    gradient: const LinearGradient(
                      colors: [AppTheme.pulp, Color(0xFF8A2E5A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shadowColor: AppTheme.pulp,
                    label: '#142',
                  ),
                ),
                // Card 3 — right, rotate +0.18 rad
                Positioned(
                  right: w * 0.08,
                  top: 20,
                  child: Transform.rotate(
                    angle: 0.18,
                    child: _StickerCard(
                      gradient: const LinearGradient(
                        colors: [AppTheme.field, Color(0xFF1F5F36)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shadowColor: AppTheme.field,
                      label: '#218',
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // Text block
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BEM-VINDO',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: AppTheme.gold,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 40,
                    color: AppTheme.cream,
                    fontStyle: FontStyle.italic,
                    height: 1.1,
                  ),
                  children: const [
                    TextSpan(text: 'Sua coleção,\n'),
                    TextSpan(
                      text: 'raríssima',
                      style: TextStyle(color: AppTheme.gold),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Monte seu álbum da Copa 2026, encontre trocas e acompanhe cada figurinha.',
                style: TextStyle(
                  color: AppTheme.creamSoft,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StickerCard extends StatelessWidget {
  final LinearGradient gradient;
  final Color shadowColor;
  final String label;

  const _StickerCard({
    required this.gradient,
    required this.shadowColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 114,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
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
          Text(
            'Toque para marcar.',
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSerif(
              fontSize: 32,
              fontStyle: FontStyle.italic,
              color: AppTheme.cream,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toque novamente para adicionar outra cópia. Pressione e segure para remover.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.creamSoft,
              fontSize: 15,
              height: 1.4,
            ),
          ),
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
              alignment: Alignment.center,
              child: Text(
                '2',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
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
          Text(
            'Troque com\namigos.',
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSerif(
              fontSize: 32,
              fontStyle: FontStyle.italic,
              color: AppTheme.cream,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Compartilhe sua coleção e receba sugestões automáticas de troca.',
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
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
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
      child: Text(
        code,
        style: GoogleFonts.jetBrainsMono(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Slide 3 — Favoritas ──────────────────────────────────────────────────────

class _Slide3 extends StatelessWidget {
  const _Slide3();

  static const _sky = Color(0xFF3F8FE0);
  static const _flame = Color(0xFFE85A3C);

  static const _countries = [
    ('BRA', AppTheme.gold),
    ('ARG', _sky),
    ('FRA', _sky),
    ('ESP', _flame),
    ('GER', AppTheme.creamSoft),
    ('ENG', _flame),
    ('POR', AppTheme.field),
    ('NED', _flame),
    ('USA', _sky),
    ('MEX', AppTheme.field),
    ('URU', _sky),
    ('BEL', _flame),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.3,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final (code, color) in _countries)
                _CountryChip(
                  code: code,
                  color: color,
                  selected: code == 'BRA' || code == 'ARG',
                ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Escolha suas\nfavoritas.',
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSerif(
              fontSize: 32,
              fontStyle: FontStyle.italic,
              color: AppTheme.cream,
              height: 1.1,
            ),
          ),
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
  const _CountryChip(
      {required this.code, required this.color, required this.selected});

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
