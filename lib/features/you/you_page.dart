import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/debug/mobile_preview.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/figus_colors.dart';
import '../../data/providers.dart';
import '../../data/repos/sync_repo.dart';
import '../profiles/avatars.dart';
import '../pro/pro_service.dart';
import '../pro/theme_service.dart';
import '../streak/streak_service.dart';

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
              // ignored while the network round-trip runs.
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
              // PULL-ONLY: each sticker tap already auto-pushes to the cloud
              // via _upsert in CollectionRepo. Doing a push-then-pull here
              // would overwrite a newer cloud state with stale local data
              // whenever this device hadn't refreshed in a while.
              // Initial backfill of pre-login marks happens in AuthPage._verifyOtp.
              final repo = ref.read(collectionRepoProvider);
              final sync = ref.read(syncRepoProvider);
              final remote = await sync.pullAll();
              final settings = await sync.pullUserSettings();
              final applyStats = await repo.applyRemoteEntries(remote);
              // Apply theme / favorite nations / profile name from cloud too.
              if (settings.theme != null) {
                final seed = AppThemeSeed.values
                    .where((t) => t.name == settings.theme)
                    .firstOrNull;
                if (seed != null) {
                  await ref.read(themeSeedProvider.notifier)
                      .set(seed, pushToCloud: false);
                }
              }
              if (settings.favoriteNations != null) {
                await ref.read(profileRepoProvider).setFavoriteNations(
                      settings.favoriteNations!.toSet(),
                      pushToCloud: false,
                    );
              }
              if (settings.profileName != null &&
                  settings.profileName!.trim().isNotEmpty) {
                final active = await ref.read(profileRepoProvider).active();
                if (active.name != settings.profileName) {
                  await ref.read(profileRepoProvider).rename(
                        active.id,
                        settings.profileName!,
                        pushToCloud: false,
                      );
                }
              }
              if (settings.avatar != null && settings.avatar!.isNotEmpty) {
                await ref.read(profileRepoProvider)
                    .setAvatarEmoji(settings.avatar!, pushToCloud: false);
              }
              // Bump the version (same pattern used by tapSticker / import) so
              // all autoDispose stat/section providers re-fetch. Invalidate
              // directly too just to make sure cached AsyncValues clear.
              ref.read(collectionVersionProvider.notifier).state++;
              ref.invalidate(albumStatsProvider);
              ref.invalidate(albumSectionsProvider);
              ref.invalidate(profilesListProvider);
              // ignore: avoid_print
              print('[Sync] remoteRows=${remote.length} apply=$applyStats settings=$settings');
              messenger
                ..clearSnackBars()
                ..showSnackBar(SnackBar(
                  content: Text(
                    'Sincronizado · ${applyStats.markedApplied} álbum + ${applyStats.extrasApplied} repetidas'
                    '${applyStats.unmatched > 0 ? " · ${applyStats.unmatched} código(s) não reconhecido(s)" : ""}',
                  ),
                  duration: const Duration(seconds: 5),
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

    final activeProfile = profileAsync.maybeWhen(
      data: (list) =>
          list.firstWhere((p) => p.isActive, orElse: () => list.first),
      orElse: () => null,
    );
    final profileName = activeProfile?.name ?? '...';
    final avatarId = activeProfile?.avatarEmoji ?? kDefaultAvatarId;

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
            avatarId: avatarId,
            isPro: pro.isActive,
            isTrial: pro.isTrial,
            trialDaysLeft: pro.trialDaysLeft,
            onTap: () => context.push('/profiles'),
          ),
          const SizedBox(height: 12),

          // ── Streak card ─────────────────────────────────────────────────────
          const _StreakBanner(),
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
                          _StatRow(color: c.text,            label: 'TENHO',     value: owned.toString()),
                          const SizedBox(height: 8),
                          _StatRow(color: AppTheme.pulpSoft, label: 'FALTAM',    value: missing.toString()),
                          const SizedBox(height: 8),
                          _StatRow(color: c.accent,          label: 'REPETIDAS', value: '${stats?.duplicates ?? 0}'),
                          const SizedBox(height: 8),
                          _StatRow(
                            color: AppTheme.gold,
                            label: 'BRILHANTES',
                            value: stats == null
                                ? '0'
                                : '${stats.foilOwned}' +
                                    (stats.foilExtraCopies > 0
                                        ? ' · ${stats.foilExtraCopies} rep'
                                        : ''),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(color: c.border, height: 24),
                // Apenas o status de sync — sem juntar com brilhantes.
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isSignedIn ? '☁ ${syncEmail ?? "Sync ativo"}' : '○ Coleção salva neste aparelho',
                    style: TextStyle(fontSize: 11, color: c.textMuted),
                  ),
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
                icon: Icons.face_outlined,
                title: 'Avatar',
                iconColor: c.accent,
                onTap: () => context.push('/avatars'),
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
                title: 'Ajuda',
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

          // ── Debug toggles (remove before public release) ───────────────────
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
              if (kDebugMode)
                _MenuRow(
                  icon: ref.watch(mobilePreviewProvider)
                      ? Icons.smartphone_rounded
                      : Icons.tablet_rounded,
                  iconColor: ref.watch(mobilePreviewProvider)
                      ? c.accent
                      : c.textMuted,
                  title: ref.watch(mobilePreviewProvider)
                      ? 'Voltar à largura real (debug)'
                      : 'Simular celular (debug)',
                  subtitle: 'Trava a UI em 420px pra prever layout no celular',
                  onTap: () => ref.read(mobilePreviewProvider.notifier).toggle(),
                ),
              if (kDebugMode)
                _MenuRow(
                  icon: Icons.view_carousel_outlined,
                  iconColor: c.textMuted,
                  title: 'Galeria de banners (debug)',
                  subtitle: 'Compara tamanhos lado a lado',
                  onTap: () => context.push('/debug/banners'),
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

// ── _StreakBanner ─────────────────────────────────────────────────────────────

class _StreakBanner extends ConsumerWidget {
  const _StreakBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.fc;
    final streakAsync = ref.watch(currentStreakProvider);
    final streak = streakAsync.valueOrNull;
    if (streak == null || streak.currentStreak == 0) {
      // First-time / inactive profile — keep UI calm, hide the banner.
      return const SizedBox.shrink();
    }
    final days = streak.currentStreak;
    final freezesLeft = 3 - streak.freezesUsedThisMonth;
    final nextMilestone = _nextMilestone(days);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            c.accent.withValues(alpha: 0.18),
            c.accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Text(
            days >= 7 ? '🔥' : '🌱',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  days == 1 ? '1 dia seguido' : '$days dias seguidos',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nextMilestone != null
                      ? 'Faltam ${nextMilestone - days} pra desbloquear marco de $nextMilestone'
                      : 'Maior streak: ${streak.longestStreak} dias',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message:
                'Escudos protegem seu streak — perdeu um dia, um escudo é gasto automaticamente. Renova mensalmente.',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: c.cardAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('🛡️', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '$freezesLeft',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: c.text,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'escudo${freezesLeft == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: c.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int? _nextMilestone(int days) {
    for (final m in const [3, 7, 14, 30, 60]) {
      if (m > days) return m;
    }
    return null;
  }
}

// ── _ProfileCard ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String name;
  final String avatarId;
  final bool isPro;
  final bool isTrial;
  final int trialDaysLeft;
  final VoidCallback onTap;
  const _ProfileCard({
    required this.name,
    required this.avatarId,
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
                    color: c.accent.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: c.accent.withValues(alpha: 0.20),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AvatarImage(id: avatarId, size: 56),
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
                            ? 'Ativo · Sem anúncios · Temas e avatares premium'
                            : 'Sem anúncios · Temas e avatares premium · Estatísticas avançadas'),
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
