import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/figus_colors.dart';
import '../../data/providers.dart';
import '../pro/pro_service.dart';

class YouPage extends ConsumerWidget {
  const YouPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.fc;
    final profileAsync = ref.watch(profilesListProvider);
    final statsAsync = ref.watch(albumStatsProvider);
    final pro = ref.watch(proProvider);

    final profileName = profileAsync.maybeWhen(
      data: (list) =>
          list.firstWhere((p) => p.isActive, orElse: () => list.first).name,
      orElse: () => '...',
    );

    final stats = statsAsync.valueOrNull;
    final owned = stats?.owned ?? 0;
    final total = stats?.total ?? 0;
    final missing = total - owned;
    final pct = total > 0 ? (owned / total * 100).round() : 0;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Text(
          'Você',
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const SizedBox(height: 16),

          // ── Profile card ───────────────────────────────────────────────────
          _ProfileCard(
            name: profileName,
            isPro: pro.isPro,
            onTap: () => context.push('/profiles'),
          ),
          const SizedBox(height: 12),

          // ── Progress card ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PROGRESSO · COPA 2026',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AppTheme.gold,
                        letterSpacing: 0.08,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/progress'),
                      child: Text(
                        'Ver tudo →',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: c.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: total > 0 ? owned / total : 0,
                            strokeWidth: 6,
                            backgroundColor: c.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.gold),
                          ),
                        ),
                        Text(
                          '$pct%',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _StatRow(color: c.text,        label: 'TENHO',     value: owned.toString()),
                          const SizedBox(height: 8),
                          _StatRow(color: AppTheme.pulpSoft, label: 'FALTAM',    value: missing.toString()),
                          const SizedBox(height: 8),
                          _StatRow(color: AppTheme.gold,     label: 'REPETIDAS', value: '${stats?.duplicates ?? 0}'),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(color: c.border, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${stats?.foilOwned ?? 0} brilhantes',
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                    Text(
                      'Sincronizado',
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Figus Pro ──────────────────────────────────────────────────────
          _ProCard(
            isPro: pro.isPro,
            onTap: () => context.push(pro.isPro ? '/themes' : '/upgrade'),
          ),
          const SizedBox(height: 16),

          // ── Menu group 1 ───────────────────────────────────────────────────
          _MenuGroup(
            children: [
              _MenuRow(
                icon: Icons.insights_rounded,
                title: 'Estatísticas',
                onTap: () => context.push('/progress'),
              ),
              _MenuRow(
                icon: Icons.palette_outlined,
                title: 'Temas de cor',
                iconColor: AppTheme.gold,
                onTap: () => context.push('/themes'),
              ),
              _MenuRow(
                icon: Icons.star_outline_rounded,
                title: 'Seleções favoritas',
                iconColor: AppTheme.gold,
                onTap: () => context.push('/favorites'),
              ),
              _MenuRow(
                icon: Icons.upload_rounded,
                title: 'Importar coleção',
                onTap: () => context.push('/import'),
              ),
              _MenuRow(
                icon: Icons.help_outline_rounded,
                title: 'Como usar',
                onTap: () => context.push('/help'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Menu group 2 ───────────────────────────────────────────────────
          _MenuGroup(
            children: [
              _MenuRow(
                icon: Icons.share_rounded,
                title: 'Compartilhar Figus',
                onTap: () => Share.share(
                  'Baixe o Figus — o melhor app para controlar sua coleção de figurinhas da Copa 2026 ⚽🏆\n\nhttps://appfigus.com',
                ),
              ),
              _MenuRow(
                icon: Icons.favorite_border_rounded,
                title: 'Apoiar o dev',
                iconColor: AppTheme.pulpSoft,
                onTap: () => context.push('/donate'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Menu group 3 ───────────────────────────────────────────────────
          _MenuGroup(
            children: [
              _MenuRow(
                icon: Icons.settings_outlined,
                title: 'Configurações',
                onTap: () => context.push('/settings'),
              ),
              const _MenuRow(
                icon: Icons.info_outline_rounded,
                title: 'Sobre · v 2.6.0',
                muted: true,
                onTap: null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── _ProfileCard ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String name;
  final bool isPro;
  final VoidCallback onTap;
  const _ProfileCard({required this.name, required this.isPro, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.gold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withValues(alpha: 0.20),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      color: AppTheme.inkDeep,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.instrumentSerif(
                          fontStyle: FontStyle.italic,
                          fontSize: 22,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Copa 2026',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: AppTheme.gold,
                          letterSpacing: 0.06,
                        ),
                      ),
                    ],
                  ),
                ),
                // PRO/FREE badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPro
                        ? AppTheme.gold.withValues(alpha: 0.15)
                        : c.text.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                    border: isPro
                        ? Border.all(color: AppTheme.gold.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Text(
                    isPro ? 'PRO' : 'FREE',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isPro
                          ? AppTheme.gold
                          : c.text.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: c.textMuted.withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── _ProCard ──────────────────────────────────────────────────────────────────

class _ProCard extends StatelessWidget {
  final bool isPro;
  final VoidCallback onTap;
  const _ProCard({required this.isPro, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B6914), Color(0xFFE5B14B), Color(0xFF7A5B1A)],
            stops: [0.0, 0.55, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.gold.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPro ? 'FIGUS PRO · ATIVO' : 'FIGUS PRO',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPro
                        ? 'Ativo · Sem anúncios · Temas premium desbloqueados'
                        : 'Remove anúncios · Temas premium · Sync multi-device',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isPro
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isPro ? '✓ Ativo' : 'R\$6,90',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isPro ? Colors.white : AppTheme.inkDeep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _MenuGroup ────────────────────────────────────────────────────────────────

class _MenuGroup extends StatelessWidget {
  final List<Widget> children;
  const _MenuGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: children),
    );
  }
}

// ── _MenuRow ──────────────────────────────────────────────────────────────────

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final bool muted;
  final VoidCallback? onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    this.iconColor,
    this.muted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final effectiveIconColor = iconColor ?? c.text;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: c.border.withValues(alpha: 0.6), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: effectiveIconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: muted ? c.text.withValues(alpha: 0.45) : c.text,
                ),
              ),
            ),
            const Spacer(),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: c.textMuted.withValues(alpha: 0.5),
                size: 12,
              ),
          ],
        ),
      ),
    );
  }
}

// ── _StatRow ──────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _StatRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: c.text.withValues(alpha: 0.55),
              letterSpacing: 0.06,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
