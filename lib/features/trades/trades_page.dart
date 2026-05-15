import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../data/repos/album_repo.dart';
import '../../domain/models/album_view_models.dart';

/// Trades hub — placeholder until P2P (v2) lands. Today shows your duplicates
/// (what you can offer) and missing list (what you want).
class TradesPage extends ConsumerWidget {
  const TradesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dupesAsync = ref.watch(_duplicatesProvider);
    final missingAsync = ref.watch(_missingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trocas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => context.push('/compare'),
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Comparar com amigo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Colors.white),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Compartilhe seu inventário (botão ↗ lá dentro), mande pro amigo. '
                      'Ele cola no app e vê as trocas sugeridas automaticamente.',
                      style: TextStyle(color: Colors.white, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Pra trocar',
              subtitle: 'Suas repetidas — leva pra escola, partidas, encontros',
              icon: Icons.outbox_rounded,
            ),
            dupesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Erro: $e'),
              data: (list) => list.isEmpty
                  ? const _EmptyMini(text: 'Você não tem repetidas ainda.')
                  : _ChipList(items: list),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Caçando',
              subtitle: 'Figurinhas que você ainda não tem',
              icon: Icons.radar_rounded,
            ),
            missingAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Erro: $e'),
              data: (list) => list.isEmpty
                  ? const _EmptyMini(text: 'Coleção completa! 🎉')
                  : _ChipList(items: list, missing: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _SectionHeader({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.seed),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipList extends StatelessWidget {
  final List<StickerView> items;
  final bool missing;
  const _ChipList({required this.items, this.missing = false});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final s in items.take(60))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: missing ? AppTheme.slotSoft : AppTheme.seed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: missing ? AppTheme.slot : AppTheme.seed,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.number,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: missing ? AppTheme.inkSoft : AppTheme.seed,
                    )),
                if (s.duplicateCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text('×${s.duplicateCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.seed,
                        )),
                  ),
              ],
            ),
          ),
        if (items.length > 60)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text('+ ${items.length - 60}',
                style: const TextStyle(color: AppTheme.inkSoft, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

class _EmptyMini extends StatelessWidget {
  final String text;
  const _EmptyMini({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: const TextStyle(color: AppTheme.inkSoft)),
    );
  }
}

final _duplicatesProvider = FutureProvider.autoDispose<List<StickerView>>((ref) async {
  ref.watch(collectionVersionProvider);
  final repo = ref.watch(albumRepoProvider);
  final sections = await repo.loadSections(filter: AlbumFilter.duplicates);
  return sections.expand((s) => s.stickers).toList();
});

final _missingProvider = FutureProvider.autoDispose<List<StickerView>>((ref) async {
  ref.watch(collectionVersionProvider);
  final repo = ref.watch(albumRepoProvider);
  final sections = await repo.loadSections(filter: AlbumFilter.missing);
  return sections.expand((s) => s.stickers).toList();
});
