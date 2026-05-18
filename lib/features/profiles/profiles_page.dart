import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/figus_colors.dart';
import '../../data/providers.dart';
import '../pro/paywall_sheet.dart';
import '../pro/pro_service.dart';
import 'avatars.dart';

/// Profile page — focused on editing the currently active profile (name +
/// avatar). Other profiles in the family appear below as a switch-list, with
/// a "Novo perfil" CTA (free for the first, Pro for the rest).
class ProfilesPage extends ConsumerWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfiles = ref.watch(profilesListProvider);
    final pro = ref.watch(proProvider);
    final isPro = pro.isActive;
    final c = context.fc;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: asyncProfiles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(child: Text('Nenhum perfil ainda'));
          }
          final active = profiles.firstWhere(
            (p) => p.isActive,
            orElse: () => profiles.first,
          );
          final others = profiles.where((p) => p.id != active.id).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // ── Active profile editor ─────────────────────────────────────
              _ActiveProfileCard(
                name: active.name,
                avatarId: active.avatarEmoji,
                isPro: isPro,
                isTrial: pro.isTrial,
                trialDaysLeft: pro.trialDaysLeft,
                onRename: () => _renameProfile(context, ref, active.id, active.name),
                onTapAvatar: () => context.push('/avatars'),
              ),
              const SizedBox(height: 24),

              // ── Other profiles ────────────────────────────────────────────
              if (others.isNotEmpty) ...[
                _SectionLabel(label: 'OUTROS PERFIS'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    children: [
                      for (var i = 0; i < others.length; i++) ...[
                        _ProfileTile(
                          name: others[i].name,
                          avatarId: others[i].avatarEmoji,
                          onActivate: () async {
                            await ref.read(profileRepoProvider).setActive(others[i].id);
                            ref.read(collectionVersionProvider.notifier).state++;
                          },
                          onRename: () => _renameProfile(
                              context, ref, others[i].id, others[i].name),
                        ),
                        if (i < others.length - 1)
                          Divider(height: 0.5, color: c.border.withValues(alpha: 0.6)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Add new profile ───────────────────────────────────────────
              Builder(builder: (_) {
                final canAddFree = profiles.isEmpty;
                final locked = !isPro && !canAddFree;
                return FilledButton.icon(
                  icon: Icon(
                    locked ? Icons.lock_rounded : Icons.person_add_alt_1_rounded,
                  ),
                  label: Text(locked ? 'Novo perfil (Pro)' : 'Novo perfil'),
                  onPressed: locked
                      ? () => showPaywall(context)
                      : () => _addProfile(context, ref),
                );
              }),
              const SizedBox(height: 16),
              if (!isPro)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.cardAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded,
                          color: c.accent, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'O 1º perfil e o renome são grátis. Perfis extras (família) '
                          'são Pro. Sync na nuvem segue grátis pra todo mundo.',
                          style: TextStyle(
                              color: c.textMuted, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addProfile(BuildContext context, WidgetRef ref) async {
    final name = await _nameDialog(context,
        title: 'Novo perfil', hint: 'Nome (ex.: Filho)');
    if (name == null || name.isEmpty) return;
    await ref.read(profileRepoProvider).create(name);
    ref.read(collectionVersionProvider.notifier).state++;
  }

  Future<void> _renameProfile(
      BuildContext context, WidgetRef ref, int id, String current) async {
    final name = await _nameDialog(context,
        title: 'Renomear perfil', hint: 'Novo nome', initial: current);
    if (name == null || name.isEmpty) return;
    await ref.read(profileRepoProvider).rename(id, name);
    ref.read(collectionVersionProvider.notifier).state++;
  }

  Future<String?> _nameDialog(
    BuildContext context, {
    required String title,
    required String hint,
    String initial = '',
  }) async {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, ctrl.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class _ActiveProfileCard extends StatelessWidget {
  final String name;
  final String avatarId;
  final bool isPro;
  final bool isTrial;
  final int trialDaysLeft;
  final VoidCallback onRename;
  final VoidCallback onTapAvatar;

  const _ActiveProfileCard({
    required this.name,
    required this.avatarId,
    required this.isPro,
    required this.isTrial,
    required this.trialDaysLeft,
    required this.onRename,
    required this.onTapAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          // Big tappable avatar — leads to picker, reflects current selection.
          GestureDetector(
            onTap: onTapAvatar,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: c.accent.withValues(alpha: 0.20),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AvatarImage(id: avatarId, size: 112),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.card, width: 2),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onTapAvatar,
            icon: const Icon(Icons.face_retouching_natural_rounded, size: 16),
            label: const Text('Trocar avatar'),
          ),
          const SizedBox(height: 4),
          // Name with inline edit affordance.
          InkWell(
            onTap: onRename,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.edit_outlined,
                      size: 16, color: c.textMuted.withValues(alpha: 0.7)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isPro ? c.accent : c.text.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String name;
  final String avatarId;
  final VoidCallback onActivate;
  final VoidCallback onRename;

  const _ProfileTile({
    required this.name,
    required this.avatarId,
    required this.onActivate,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return InkWell(
      onTap: onActivate,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.cardAlt,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: AvatarImage(id: avatarId, size: 40),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16),
              tooltip: 'Renomear',
              onPressed: onRename,
            ),
            TextButton(
              onPressed: onActivate,
              child: const Text('Ativar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: context.fc.textMuted,
        ),
      ),
    );
  }
}
