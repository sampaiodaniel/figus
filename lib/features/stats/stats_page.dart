import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/figus_colors.dart';
import '../../data/providers.dart';
import '../../domain/models/album_view_models.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(albumStatsProvider);
    final c = context.fc;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Text(
          'Estatísticas',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: c.text,
          ),
        ),
        backgroundColor: c.cardAlt,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (s) => _StatsBody(stats: s),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final AlbumStats stats;
  const _StatsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final pct = stats.percentComplete;
    final pctInt = (pct * 100).round();

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
                    color: AppTheme.gold,
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
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(AppTheme.gold),
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
                            color: AppTheme.gold,
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
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.gold),
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
                  iconColor: AppTheme.gold,
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
                color: AppTheme.gold,
                letterSpacing: 0.1,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.trending_up_rounded,
                  iconColor: AppTheme.seed,
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
                  value: '${stats.streak}d',
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
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
