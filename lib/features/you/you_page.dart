import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../data/repos/sync_repo.dart';
import '../auth/auth_page.dart';
import '../pro/pro_service.dart';

class YouPage extends ConsumerWidget {
  const YouPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profilesListProvider);
    final statsAsync = ref.watch(albumStatsProvider);
    final pro = ref.watch(proProvider);
    final sync = ref.read(syncRepoProvider);

    final profileName = profileAsync.maybeWhen(
      data: (list) => list.firstWhere((p) => p.isActive, orElse: () => list.first).name,
      orElse: () => '...',
    );

    final stats = statsAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Minha conta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(
            profileName: profileName,
            owned: stats?.owned,
            total: stats?.total,
            foilOwned: stats?.foilOwned,
            foilTotal: stats?.foilTotal,
            onProfilesTap: () => context.push('/profiles'),
          ),
          const SizedBox(height: 20),
          _GroupCard(
            title: 'Seu álbum',
            tiles: [
              _Tile(
                icon: Icons.insights_rounded,
                title: 'Estatísticas',
                subtitle: 'Progresso detalhado por seleção e categoria',
                onTap: () => context.push('/progress'),
              ),
              _Tile(
                icon: Icons.palette_rounded,
                title: 'Temas',
                subtitle: 'Personalizar cores do app',
                onTap: () => context.push('/themes'),
              ),
              _Tile(
                icon: Icons.favorite_rounded,
                title: 'Seleções favoritas',
                subtitle: 'Prioridade nas sugestões de troca',
                onTap: () => context.push('/favorites'),
              ),
              _Tile(
                icon: Icons.swap_horiz_rounded,
                title: 'Importar coleção',
                subtitle: 'Cole uma lista de códigos ou foto da tela',
                onTap: () => context.push('/import'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GroupCard(
            title: 'Trocas',
            tiles: [
              _Tile(
                icon: Icons.people_alt_rounded,
                title: 'Comparar com amigo',
                subtitle: 'Sugestões automáticas de troca',
                onTap: () => context.push('/compare'),
              ),
              const _Tile(
                icon: Icons.bluetooth_searching_rounded,
                title: 'Troca por aproximação',
                subtitle: 'Em breve — Bluetooth P2P',
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sync / auth section
          _SyncCard(sync: sync),
          const SizedBox(height: 16),

          // Pro status tile (trial countdown or upgrade banner)
          if (pro.isTrial)
            _TrialBanner(daysLeft: pro.trialDaysLeft, onTap: () => context.push('/upgrade'))
          else if (!pro.isPro)
            _ProBanner(onTap: () => context.push('/upgrade')),
          const SizedBox(height: 16),
          _GroupCard(
            title: 'Sobre o Figus',
            tiles: [
              _Tile(
                icon: Icons.sports_soccer_rounded,
                title: 'Como marcar e trocar',
                onTap: () => _showHowItWorks(context),
              ),
              const _Tile(
                icon: Icons.pix_rounded,
                title: 'Mandar um Pix pro dev',
                subtitle: 'Doação opcional — em breve',
                onTap: null,
              ),
              const _Tile(
                icon: Icons.info_outline_rounded,
                title: 'Versão 0.1.0 beta',
                subtitle: 'Grátis com banner · Pro remove anúncios e desbloqueia temas',
                onTap: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHowItWorks(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Como marcar e trocar',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            SizedBox(height: 16),
            _HowRow(icon: Icons.touch_app_rounded, text: 'Toque → marca como tenho'),
            _HowRow(icon: Icons.touch_app_rounded, text: 'Toque de novo → conta como repetida (+1)'),
            _HowRow(
                icon: Icons.touch_app_rounded,
                text: 'Pressione e segure → remove uma cópia por vez'),
            _HowRow(
                icon: Icons.people_alt_rounded,
                text: 'Trocas: compartilhe seu inventário, o amigo cola no app e vê sugestões automáticas'),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String profileName;
  final int? owned;
  final int? total;
  final int? foilOwned;
  final int? foilTotal;
  final VoidCallback onProfilesTap;

  const _ProfileHeader({
    required this.profileName,
    required this.owned,
    required this.total,
    required this.foilOwned,
    required this.foilTotal,
    required this.onProfilesTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (owned != null && total != null && total! > 0)
        ? (owned! / total! * 100).toStringAsFixed(1)
        : null;

    return InkWell(
      onTap: onProfilesTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.slotSoft.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.seed,
              child: Text(
                profileName.isNotEmpty ? profileName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profileName,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  if (pct != null)
                    Text(
                      '$owned/$total figurinhas · $pct% · ${foilOwned ?? 0}/${foilTotal ?? 0} brilhantes',
                      style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft),
                    )
                  else
                    const Text('toque para trocar de perfil',
                        style: TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.inkSoft),
          ],
        ),
      ),
    );
  }
}

class _TrialBanner extends StatelessWidget {
  final int daysLeft;
  final VoidCallback onTap;
  const _TrialBanner({required this.daysLeft, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF007A5A), Color(0xFF22C58A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trial Pro ativo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      )),
                  Text(
                    '$daysLeft dia${daysLeft == 1 ? '' : 's'} restante${daysLeft == 1 ? '' : 's'} — toque para comprar e manter',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ProBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _ProBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.seed, Color(0xFF7A5BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 32),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Figus Pro — a partir de R\$ 6,90/mês',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      )),
                  SizedBox(height: 2),
                  Text('Sem anúncios · temas · sync · mais barato que Figuritas',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  final SyncRepo sync;
  const _SyncCard({required this.sync});

  @override
  Widget build(BuildContext context) {
    final isSignedIn = sync.isSignedIn;
    final email = sync.userEmail;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSignedIn
                    ? const Color(0xFF22C58A).withValues(alpha: 0.1)
                    : AppTheme.slotSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSignedIn ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                color: isSignedIn ? const Color(0xFF22C58A) : AppTheme.inkSoft,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSignedIn ? 'Sync ativo' : 'Sync desativado',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  Text(
                    isSignedIn
                        ? email ?? 'Conta conectada'
                        : 'Entre para sincronizar entre dispositivos',
                    style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft),
                  ),
                ],
              ),
            ),
            if (isSignedIn)
              TextButton(
                onPressed: () async {
                  await sync.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Conta desconectada')),
                    );
                  }
                },
                child: const Text('Sair'),
              )
            else
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const AuthPage()),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.seed,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Entrar'),
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String title;
  final List<_Tile> tiles;
  const _GroupCard({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
          child: Text(title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkSoft.withValues(alpha: 0.8),
              )),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: tiles),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const _Tile({required this.icon, required this.title, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return ListTile(
      leading: Icon(icon, color: disabled ? AppTheme.slot : AppTheme.seed),
      title: Text(title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: disabled ? AppTheme.inkSoft : null,
          )),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: disabled ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _HowRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HowRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.seed, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}
