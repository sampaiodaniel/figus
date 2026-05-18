import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/figus_colors.dart';
import '../../data/providers.dart';
import '../pro/paywall_sheet.dart';
import '../pro/pro_service.dart';
import 'avatars.dart';

class AvatarPickerPage extends ConsumerWidget {
  const AvatarPickerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.fc;
    final isPro = ref.watch(proProvider).isActive;
    final profileAsync = ref.watch(profilesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Avatar')),
      body: profileAsync.when(
        data: (profiles) {
          final active = profiles.firstWhere(
            (p) => p.isActive,
            orElse: () => profiles.first,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (!isPro)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.cardAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: c.accent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Avatares com ★ são exclusivos do Pro',
                          style: TextStyle(fontSize: 12, color: c.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              _SectionHeader(title: 'Grátis para todos'),
              const SizedBox(height: 8),
              _AvatarGrid(
                avatars: figusAvatars.where((a) => !a.proOnly).toList(),
                selected: active.avatarEmoji,
                isPro: isPro,
                onPick: (a) => _select(context, ref, a, isPro),
              ),
              const SizedBox(height: 24),
              _SectionHeader(title: 'Pro'),
              const SizedBox(height: 8),
              _AvatarGrid(
                avatars: figusAvatars.where((a) => a.proOnly).toList(),
                selected: active.avatarEmoji,
                isPro: isPro,
                onPick: (a) => _select(context, ref, a, isPro),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  Future<void> _select(
      BuildContext context, WidgetRef ref, FigusAvatar avatar, bool isPro) async {
    if (avatar.proOnly && !isPro) {
      await showPaywall(context, trigger: PaywallContext.theme);
      return;
    }
    await ref.read(profileRepoProvider).setAvatarEmoji(avatar.id);
    ref.read(collectionVersionProvider.notifier).state++;
    ref.invalidate(profilesListProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Avatar trocado: ${avatar.label}')),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: context.fc.textMuted,
        ),
      ),
    );
  }
}

class _AvatarGrid extends StatelessWidget {
  final List<FigusAvatar> avatars;
  final String selected;
  final bool isPro;
  final void Function(FigusAvatar) onPick;

  const _AvatarGrid({
    required this.avatars,
    required this.selected,
    required this.isPro,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.0,
      ),
      itemCount: avatars.length,
      itemBuilder: (_, i) {
        final a = avatars[i];
        final isSelected = selected == a.id;
        final locked = a.proOnly && !isPro;
        return InkWell(
          onTap: () => onPick(a),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected ? c.accent.withValues(alpha: 0.14) : c.cardAlt,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? c.accent : c.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Avatar fills the tile — LayoutBuilder so size scales with
                // available width on every screen.
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: LayoutBuilder(
                    builder: (_, cons) {
                      final size =
                          cons.maxWidth < cons.maxHeight ? cons.maxWidth : cons.maxHeight;
                      return Center(child: AvatarImage(id: a.id, size: size));
                    },
                  ),
                ),
                if (locked)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(Icons.lock_rounded, size: 16, color: Color(0xFFB8860B)),
                  ),
                if (isSelected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(Icons.check_circle_rounded, size: 18, color: c.accent),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
