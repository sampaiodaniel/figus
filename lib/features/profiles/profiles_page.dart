import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/figus_colors.dart';
import '../../data/providers.dart';
import '../pro/paywall_sheet.dart';
import '../pro/pro_service.dart';

class ProfilesPage extends ConsumerWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfiles = ref.watch(profilesListProvider);
    final pro = ref.watch(proProvider);
    final isPro = pro.isActive;
    final c = context.fc;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfis')),
      body: asyncProfiles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (profiles) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final p in profiles)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(p.avatarColor),
                    child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isPro ? Icons.edit_outlined : Icons.lock_outline_rounded,
                          size: 18,
                          color: isPro ? null : c.textMuted,
                        ),
                        tooltip: isPro ? 'Renomear' : 'Renomear (Pro)',
                        onPressed: isPro
                            ? () => _renameProfile(context, ref, p.id, p.name)
                            : () => showPaywall(context),
                      ),
                      if (p.isActive)
                        const Chip(
                          label: Text('Ativo'),
                          backgroundColor: Color(0x221F66FF),
                          side: BorderSide.none,
                        )
                      else
                        TextButton(
                          onPressed: () async {
                            await ref.read(profileRepoProvider).setActive(p.id);
                            ref.read(collectionVersionProvider.notifier).state++;
                          },
                          child: const Text('Ativar'),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            // First profile is free; additional profiles require Pro.
            Builder(builder: (_) {
              final canAddFree = profiles.isEmpty;
              final locked = !isPro && !canAddFree;
              return FilledButton.icon(
                icon: Icon(locked ? Icons.lock_rounded : Icons.person_add_alt_1_rounded),
                label: Text(locked ? 'Novo perfil (Pro)' : 'Novo perfil'),
                onPressed: locked
                    ? () => showPaywall(context)
                    : () => _addProfile(context, ref),
              );
            }),
            const SizedBox(height: 24),
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
                    Icon(Icons.workspace_premium_rounded, color: c.accent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Perfis extras e renomear são Pro. O 1º perfil é sempre grátis. '
                        'Sync na nuvem segue grátis pra todo mundo.',
                        style: TextStyle(color: c.textMuted, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addProfile(BuildContext context, WidgetRef ref) async {
    final name = await _nameDialog(context, title: 'Novo perfil', hint: 'Nome (ex.: Filho)');
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
