import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/figus_colors.dart';
import '../../core/widgets/figus_app_bar.dart';
import '../../data/providers.dart';
import '../../domain/models/album_view_models.dart';
import '../pro/pro_badge.dart';
import '../pro/pro_service.dart';
import '../streak/streak_service.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(albumStatsProvider);
    final isPro = ref.watch(proProvider).isActive;
    final c = context.fc;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: const FigusAppBar(title: 'Estatísticas'),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (s) => _StatsBody(stats: s, isPro: isPro),
      ),
    );
  }
}

class _StatsBody extends ConsumerWidget {
  final AlbumStats stats;
  final bool isPro;
  const _StatsBody({required this.stats, required this.isPro});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.fc;
    final pct = stats.percentComplete;
    final pctInt = (pct * 100).round();
    // SEQUÊNCIA vem do StreakService (mesma fonte do banner em Ajustes).
    // Antes a Stats lia stats.streak (dias com figurinhas marcadas) e o
    // Ajustes lia currentStreak (dias de visita ao app) — números
    // divergiam ("Ajustes: 2 dias seguidos" × "Stats: 1d sequência").
    final streak = ref.watch(currentStreakProvider).valueOrNull;
    final currentStreakDays = streak?.currentStreak ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Album header ─────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/figus-icon-512.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      'F',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.gold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Copa do Mundo FIFA 2026',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'EUA · México · Canadá',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Big progress ring ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.border),
            ),
            child: Column(
              children: [
                Text(
                  'PROGRESSO GERAL',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: pct,
                        strokeWidth: 12,
                        backgroundColor: c.border,
                        valueColor: AlwaysStoppedAnimation<Color>(c.accent),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pctInt%',
                          style: GoogleFonts.inter(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: c.accent,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          'completo',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: c.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: c.border,
                          valueColor: AlwaysStoppedAnimation<Color>(c.accent),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${stats.owned} de ${stats.total}',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 11, color: c.textMuted),
                          ),
                          Text(
                            'faltam ${stats.missing}',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 11, color: c.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Stats grid ────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.check_circle_rounded,
                  iconColor: c.accent,
                  label: 'TENHO',
                  value: '${stats.owned}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.cancel_rounded,
                  iconColor: AppTheme.pulpSoft,
                  label: 'FALTAM',
                  value: '${stats.missing}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.copy_rounded,
                  iconColor: AppTheme.sky,
                  label: 'REPETIDAS',
                  value: '${stats.duplicates}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: AppTheme.goldSoft,
                  label: 'BRILHANTES',
                  value: '${stats.foilOwned}/${stats.foilTotal}',
                  sub: stats.foilExtraCopies > 0
                      ? '${stats.foilExtraCopies} repetida${stats.foilExtraCopies == 1 ? '' : 's'}'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.collections_rounded,
                  iconColor: AppTheme.field,
                  label: 'TOTAL',
                  value: '${stats.total}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.donut_large_rounded,
                  iconColor: AppTheme.flame,
                  label: 'COMPLETO',
                  value: '${(pct * 100).toStringAsFixed(1)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Temporal stats ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'ATIVIDADE',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: c.accent,
                letterSpacing: 0.1,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.trending_up_rounded,
                  iconColor: c.accent,
                  label: 'ESTA SEMANA',
                  value: '+${stats.collectedThisWeek}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: AppTheme.flame,
                  label: 'SEQUÊNCIA',
                  value: '${currentStreakDays}d',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.calendar_today_rounded,
                  iconColor: AppTheme.pulpSoft,
                  label: 'DIAS ATIVOS',
                  value: '${stats.activeDays}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.hourglass_bottom_rounded,
                  iconColor: AppTheme.goldSoft,
                  label: 'COLECIONANDO',
                  value: '${stats.daysCollecting}d',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _AdvancedStatsSection(stats: stats, isPro: isPro),
        ],
      ),
    );
  }
}

class _AdvancedStatsSection extends StatelessWidget {
  final AlbumStats stats;
  final bool isPro;
  const _AdvancedStatsSection({required this.stats, required this.isPro});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    // Derived numbers from the existing stats — keeps this section meaningful
    // without adding new SQL queries this sprint.
    final pace = stats.collectedThisWeek;
    final remaining = stats.total - stats.owned;
    final weeksToFinish = pace > 0 ? (remaining / pace).ceil() : null;
    final avgPerDay =
        stats.daysCollecting > 0 ? stats.owned / stats.daysCollecting : 0.0;
    final foilPct = stats.foilTotal > 0
        ? (stats.foilOwned / stats.foilTotal * 100).round()
        : 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.gold.withValues(alpha: 0.10),
            AppTheme.gold.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ESTATÍSTICAS AVANÇADAS',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.gold,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 6),
              const ProBadge(compact: true),
            ],
          ),
          const SizedBox(height: 14),
          if (!isPro)
            _AdvancedTeaser()
          else
            _AdvancedRealView(
              stats: stats,
              pace: pace,
              weeksToFinish: weeksToFinish,
              avgPerDay: avgPerDay,
              foilPct: foilPct,
            ),
        ],
      ),
    );
  }
}

/// Pro view — uses real numbers derived from AlbumStats.
class _AdvancedRealView extends StatelessWidget {
  final AlbumStats stats;
  final int pace;
  final int? weeksToFinish;
  final double avgPerDay;
  final int foilPct;

  const _AdvancedRealView({
    required this.stats,
    required this.pace,
    required this.weeksToFinish,
    required this.avgPerDay,
    required this.foilPct,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.speed_rounded,
                iconColor: AppTheme.gold,
                label: 'RITMO',
                value: '${pace}/sem',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.flag_rounded,
                iconColor: AppTheme.goldSoft,
                label: weeksToFinish == null ? 'PREVISÃO' : 'CONCLUSÃO',
                value: weeksToFinish == null ? '—' : '~${weeksToFinish}sem',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.trending_up_rounded,
                iconColor: AppTheme.gold,
                label: 'MÉDIA/DIA',
                value: avgPerDay.toStringAsFixed(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.calendar_today_rounded,
                iconColor: AppTheme.goldSoft,
                label: 'MELHOR DIA',
                value: _shortDay(stats.bestDayOfWeek),
                sub: stats.bestDayOfWeek == null
                    ? null
                    : '${stats.bestDayOfWeekCount} marcações',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _WeeklyChart(history: stats.weeklyHistory),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  size: 18, color: AppTheme.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  weeksToFinish == null
                      ? 'Marque uma figurinha pra começarmos a estimar quando você completa.'
                      : 'Mantendo o ritmo, você completa o álbum em ~$weeksToFinish semana${weeksToFinish == 1 ? '' : 's'}.',
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textMuted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _shortDay(int? dow) {
    if (dow == null) return '—';
    const labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return labels[(dow - 1).clamp(0, 6)];
  }
}

/// 4-bar weekly history. Index 0 = 4 weeks ago, index 3 = this week.
class _WeeklyChart extends StatelessWidget {
  final List<int> history;
  const _WeeklyChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final maxValue = history.fold<int>(0, (m, v) => v > m ? v : m);
    final labels = const ['-3 sem', '-2 sem', '-1 sem', 'Esta'];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HISTÓRICO SEMANAL',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.gold,
                  letterSpacing: 0.5,
                ),
              ),
              if (maxValue > 0)
                Text(
                  '+${history[3]} esta semana',
                  style: TextStyle(
                    fontSize: 10,
                    color: c.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < history.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${history[i]}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: c.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: maxValue == 0
                                ? 4
                                : (history[i] / maxValue) * 38 + 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.gold,
                                  AppTheme.gold.withValues(alpha: 0.5),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final l in labels)
                Expanded(
                  child: Center(
                    child: Text(
                      l,
                      style: TextStyle(fontSize: 9, color: c.textMuted),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Free view — same layout as Pro but with realistic example numbers + a
/// mock weekly chart, so the user sees exactly what they unlock.
class _AdvancedTeaser extends StatelessWidget {
  static const _mockHistory = <int>[8, 14, 11, 18];

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Visualização exemplo · ative Pro pra ver seus números reais',
          style: TextStyle(
            fontSize: 11,
            color: c.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: 0.6,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.speed_rounded,
                      iconColor: AppTheme.gold,
                      label: 'RITMO',
                      value: '18/sem',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.flag_rounded,
                      iconColor: AppTheme.goldSoft,
                      label: 'CONCLUSÃO',
                      value: '~6 sem',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.trending_up_rounded,
                      iconColor: AppTheme.gold,
                      label: 'MÉDIA/DIA',
                      value: '2.3',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.calendar_today_rounded,
                      iconColor: AppTheme.goldSoft,
                      label: 'MELHOR DIA',
                      value: 'Dom',
                      sub: '12 marcações',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _WeeklyChart(history: _mockHistory),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        size: 18, color: AppTheme.gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mantendo o ritmo, você completa o álbum em ~6 semanas.',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => context.push('/upgrade'),
          icon: const Icon(Icons.lock_open_rounded, size: 18),
          label: const Text('Desbloquear meus dados (Pro)'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.gold,
            foregroundColor: AppTheme.inkDeep,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? sub;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: c.textMuted,
                    letterSpacing: 0.06,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: c.text,
                    height: 1.1,
                  ),
                ),
                if (sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      sub!,
                      style: TextStyle(
                        fontSize: 10,
                        color: c.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
