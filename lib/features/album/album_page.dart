import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/interstitial_helper.dart';
import '../pro/pro_service.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../data/repos/album_repo.dart';
import '../../domain/models/album_view_models.dart';
import '../share/share_service.dart';
import 'widgets/nation_panel.dart';

/// Coleção — list of accordions (FWC + 48 nations + FWC9+ legends + CC).
/// Tapping a header expands its sticker grid inline, tap again collapses.
class AlbumPage extends ConsumerStatefulWidget {
  const AlbumPage({super.key});
  @override
  ConsumerState<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends ConsumerState<AlbumPage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _expanded = <String>{};
  List<AlbumSection>? _cached;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(albumSectionsProvider);
    final filter = ref.watch(albumFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coleção'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Compartilhar',
            onPressed: _showShareSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterChips(
            current: filter,
            onChanged: (f) => ref.read(albumFilterProvider.notifier).state = f,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => ref.read(albumSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Buscar seleção, jogador ou número',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(albumSearchProvider.notifier).state = '';
                          setState(() {});
                        },
                      ),
                filled: true,
                fillColor: AppTheme.slotSoft.withValues(alpha: 0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildList(sectionsAsync)),
        ],
      ),
    );
  }

  Widget _buildList(AsyncValue<List<AlbumSection>> async) {
    final data = async.value ?? _cached;
    if (async.hasValue) _cached = async.value;
    if (data == null) {
      return async.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(child: Text('Erro: ${async.error}'));
    }
    if (data.isEmpty) {
      return const Center(child: Text('Nenhuma seleção encontrada'));
    }
    return ListView.builder(
      key: const PageStorageKey('nations-list'),
      controller: _scrollCtrl,
      itemCount: data.length,
      itemBuilder: (_, i) {
        final s = data[i];
        return NationPanel(
          section: s,
          expanded: _expanded.contains(s.key),
          onToggle: () => setState(() {
            if (!_expanded.add(s.key)) _expanded.remove(s.key);
          }),
          onTapSticker: _onTapSticker,
          onLongPressSticker: _onLongPressSticker,
        );
      },
    );
  }

  Future<void> _onTapSticker(StickerView s) async {
    HapticFeedback.lightImpact();
    await ref.read(collectionRepoProvider).tapSticker(s.id);
    ref.read(collectionVersionProvider.notifier).state++;
    final isPro = ref.read(proProvider).isActive;
    InterstitialHelper.onStickerTap(isPro: isPro);
  }

  Future<void> _onLongPressSticker(StickerView s) async {
    if (s.status == StickerOwnership.missing) return;
    HapticFeedback.mediumImpact();
    await ref.read(collectionRepoProvider).removeSticker(s.id);
    ref.read(collectionVersionProvider.notifier).state++;
  }

  void _showShareSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.percent_rounded, color: AppTheme.seed),
              title: const Text('Meu progresso (cartão visual)'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                final stats = await ref.read(albumRepoProvider).loadStats();
                final profile = await ref.read(profileRepoProvider).active();
                if (!mounted) return;
                await ShareService.shareProgressCard(
                  context,
                  stats: stats,
                  albumName: 'Copa do Mundo FIFA 2026',
                  profileName: profile.name,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist_rounded, color: AppTheme.seed),
              title: const Text('Lista das que me faltam'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _shareList(AlbumFilter.missing, 'Me faltam essas figurinhas:');
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded, color: AppTheme.seed),
              title: const Text('Lista das repetidas'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _shareList(AlbumFilter.duplicates, 'Tenho essas repetidas pra trocar:');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _shareList(AlbumFilter filter, String title) async {
    final sections = await ref.read(albumRepoProvider).loadSections(filter: filter);
    final flat = sections.expand((s) => s.stickers).toList();
    if (flat.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma figurinha nessa categoria')),
      );
      return;
    }
    await ShareService.shareTextList(title: title, stickers: flat);
  }
}

class _FilterChips extends StatelessWidget {
  final AlbumFilter current;
  final ValueChanged<AlbumFilter> onChanged;
  const _FilterChips({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const items = <(AlbumFilter, String, IconData)>[
      (AlbumFilter.all, 'Todas', Icons.apps_rounded),
      (AlbumFilter.missing, 'Me faltam', Icons.radar_rounded),
      (AlbumFilter.duplicates, 'Repetidas', Icons.copy_all_rounded),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          for (final (f, label, icon) in items)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: current == f,
                onSelected: (_) => onChanged(f),
                avatar: Icon(icon,
                    size: 16,
                    color: current == f ? Colors.white : AppTheme.inkSoft),
                label: Text(label),
                labelStyle: TextStyle(
                  color: current == f ? Colors.white : AppTheme.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
                selectedColor: primary,
                backgroundColor: AppTheme.slotSoft,
                showCheckmark: false,
                side: BorderSide.none,
              ),
            ),
        ],
      ),
    );
  }
}

