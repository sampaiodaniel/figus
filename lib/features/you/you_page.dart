import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/figus_colors.dart';
import '../../data/providers.dart';
import '../../data/repos/sync_repo.dart';
import '../pro/pro_service.dart';

Future<void> _showSyncOptions(BuildContext context, WidgetRef ref, String email) async {
  final messenger = ScaffoldMessenger.of(context);
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.account_circle_rounded),
            title: Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Conta conectada'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.sync_rounded),
            title: const Text('Sincronizar agora'),
            onTap: () async {
              Navigator.pop(sheetCtx);
              // Immediate feedback so the user doesn't think the button was
              // ignored while the bulk-upsert HTTP call runs.
              messenger
                ..clearSnackBars()
                ..showSnackBar(const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Sincronizando...'),
                    ],
                  ),
                  duration: Duration(minutes: 1),
                ));
              final repo = ref.read(collectionRepoProvider);
              final pushed = await repo.pushAllLocal();
              final remote = await ref.read(syncRepoProvider).pullAll();
              await repo.applyRemoteEntries(remote);
              ref.invalidate(collectionVersionProvider);
              messenger
                ..clearSnackBars()
                ..showSnackBar(SnackBar(
                  content: Text(
                    pushed > 0
                        ? 'Sincronizado · $pushed enviado(s), ${remote.length} recebido(s)'
                        : 'Sincronizado · ${remote.length} figurinha(s) recebida(s)',
                  ),
                  duration: const Duration(seconds: 4),
                ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sair da conta'),
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () async {
              Navigator.pop(sheetCtx);
              await ref.read(syncRepoProvider).signOut();
            },
          ),
        ],
      ),
    ),
  );
}

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

    // Watch for reactivity on sign-in / sign-out
    ref.watch(syncAuthStateProvider);
    final sync = ref.read(syncRepoProvider);
    final isSignedIn = sync.isSignedIn;
    final syncEmail = sync.userEmail;

    final stats = statsAsync.valueOrNull;
    final owned = stats?.owned ?? 0;
    final total = stats?.total ?? 0;
    final missing = total - owned;
    final pct = total > 0 ? (owned / total * 100).round() : 0;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Image.asset(
              'assets/figus-logo-square.png',
              width: 32,
              height: 32,
              filterQuality: FilterQuality.medium,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Configurações',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: c.text,
                ),
              ),
            ),
          ],
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
            isPro: pro.isActive,
            isTrial: pro.isTrial,
            trialDaysLeft: pro.trialDaysLeft,
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
                        color: c.accent,
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
                            valueColor: AlwaysStoppedAnimation<Color>(c.accent),
                          ),
                        ),
                        Text(
                          '$pct%',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: c.accent,
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
                          _StatRow(color: c.accent,          label: 'REPETIDAS', value: '${stats?.duplicates ?? 0}'),
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
                      isSignedIn ? '☁ ${syncEmail ?? "Sync ativo"}' : '○ Local',
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Figus Pro ──────────────────────────────────────────────────────
          _ProCard(
            isPro: pro.isActive,
            isTrial: pro.isTrial,
            trialDaysLeft: pro.trialDaysLeft,
            // Trial users go to /upgrade so they can convert before expiry.
            // Paid Pro goes to /themes (showcase).
            onTap: () => context.push(pro.isPro ? '/themes' : '/upgrade'),
          ),
          const SizedBox(height: 16),

          // ── Menu group 1 ───────────────────────────────────────────────────
          _MenuGroup(
            children: [
              _MenuRow(
                icon: isSignedIn ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                iconColor: isSignedIn ? c.accent : c.textMuted,
                title: isSignedIn ? 'Conta sync ativa' : 'Entrar · Sincronizar',
                subtitle: isSignedIn ? syncEmail : 'Acesse em vários dispositivos',
                onTap: isSignedIn
                    ? () => _showSyncOptions(context, ref, syncEmail ?? '')
                    : () => context.push('/auth'),
              ),
              _MenuRow(
                icon: Icons.insights_rounded,
                title: 'Estatísticas',
                onTap: () => context.push('/progress'),
              ),
              _MenuRow(
                icon: Icons.palette_outlined,
                title: 'Temas de cor',
                iconColor: c.accent,
                onTap: () => context.push('/themes'),
              ),
              _MenuRow(
                icon: Icons.star_outline_rounded,
                title: 'Seleções favoritas',
                iconColor: c.accent,
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

          // ── Debug Pro toggle (remove before public release) ────────────────
          _MenuGroup(
            children: [
              _MenuRow(
                icon: pro.isPro
                    ? Icons.toggle_on_rounded
                    : Icons.toggle_off_outlined,
                iconColor: pro.isPro ? c.accent : c.textMuted,
                title: pro.isPro ? 'Desativar Pro (debug)' : 'Ativar Pro (debug)',
                subtitle: pro.isTrial
                    ? 'Trial ativo · ${pro.trialDaysLeft}d restantes'
                    : 'Atalho de desenvolvedor pra testar visão Pro',
                onTap: () async {
                  if (pro.isPro) {
                    await ref.read(proProvider.notifier).deactivatePro();
                  } else {
                    await ref.read(proProvider.notifier).activatePro();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Menu group 3 ───────────────────────────────────────────────────
          _MenuGroup(
            children: const [
              _MenuRow(
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
  final bool isTrial;
  final int trialDaysLeft;
  final VoidCallback onTap;
  const _ProfileCard({
    required this.name,
    required this.isPro,
    required this.isTrial,
    required this.trialDaysLeft,
    required this.onTap,
  });

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
                    color: c.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: c.accent.withValues(alpha: 0.20),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onPrimary,
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
                          color: c.accent,
                          letterSpacing: 0.06,
                        ),
                      ),
                    ],
                  ),
                ),
                // PRO/TRIAL/FREE badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPro
                        ? c.accent.withValues(alpha: 0.15)
                        : c.text.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                    border: isPro
                        ? Border.all(color: c.accent.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Text(
                    isTrial ? 'TRIAL ${trialDaysLeft}d' : (isPro ? 'PRO' : 'FREE'),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isPro
                          ? c.accent
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
  final bool isTrial;
  final int trialDaysLeft;
  final VoidCallback onTap;
  const _ProCard({
    required this.isPro,
    required this.isTrial,
    required this.trialDaysLeft,
    required this.onTap,
  });

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
                    isTrial
                        ? 'FIGUS PRO · TRIAL'
                        : (isPro ? 'FIGUS PRO · ATIVO' : 'FIGUS PRO'),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isTrial
                        ? 'Trial expira em ${trialDaysLeft}d · toque pra assinar'
                        : (isPro
                            ? 'Ativo · Sem anúncios · Temas premium desbloqueados'
                            : 'Remove anúncios · Temas premium · Sync multi-device'),
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
                isTrial ? '${trialDaysLeft}d' : (isPro ? '✓ Ativo' : 'R\$6,90'),
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
  final String? subtitle;
  final Color? iconColor;
  final bool muted;
  final VoidCallback? onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    this.subtitle,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: muted ? c.text.withValues(alpha: 0.45) : c.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11, color: c.textMuted),
                    ),
                  ],
                ],
              ),
            ),
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
