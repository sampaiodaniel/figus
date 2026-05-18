import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ads/interstitial_helper.dart';
import '../pro/pro_service.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/figus_colors.dart';
import '../../core/widgets/figus_app_bar.dart';
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
      appBar: FigusAppBar(
        title: 'Coleção',
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
          _HeroStatsCard(),
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
                fillColor: context.fc.cardAlt.withValues(alpha: 0.6),
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
    final filter = ref.watch(albumFilterProvider);
    final countMode = switch (filter) {
      AlbumFilter.all => NationPanelCountMode.progress,
      AlbumFilter.duplicates => NationPanelCountMode.duplicates,
      AlbumFilter.missing => NationPanelCountMode.missing,
    };
    return ListView.builder(
      key: const PageStorageKey('nations-list'),
      controller: _scrollCtrl,
      itemCount: data.length,
      itemBuilder: (_, i) {
        final s = data[i];
        return NationPanel(
          section: s,
          expanded: _expanded.contains(s.key),
          countMode: countMode,
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
              leading: Icon(Icons.percent_rounded, color: context.fc.accent),
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
              leading: Icon(Icons.checklist_rounded, color: context.fc.accent),
              title: const Text('Lista das que me faltam'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _shareList(AlbumFilter.missing, 'Me faltam essas figurinhas:');
              },
            ),
            ListTile(
              leading: Icon(Icons.swap_horiz_rounded, color: context.fc.accent),
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

// ── Hero Stats Card ──────────────────────────────────────────────────────────

class _HeroStatsCard extends ConsumerWidget {
  const _HeroStatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(albumStatsProvider);
    final stats = statsAsync.valueOrNull;

    if (stats == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(height: 110),
      );
    }

    final owned = stats.owned;
    final total = stats.total;
    final missing = stats.missing;
    final pct = total > 0 ? (owned / total * 100).round() : 0;

    final c = context.fc;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c.card, c.cardAlt],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            // Left: circular progress ring
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: pct / 100,
                    strokeWidth: 6,
                    backgroundColor: c.border,
                    valueColor: AlwaysStoppedAnimation<Color>(c.accent),
                  ),
                ),
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COPA 2026',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: c.accent,
                      letterSpacing: 0.12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$owned',
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 28,
                            fontStyle: FontStyle.italic,
                            color: c.text,
                          ),
                        ),
                        TextSpan(
                          text: ' / $total',
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 28,
                            fontStyle: FontStyle.italic,
                            color: c.textMuted.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$missing faltando',
                    style: TextStyle(
                      fontSize: 11,
                      color: c.textMuted,
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
}

// ── Filter Chips ─────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final AlbumFilter current;
  final ValueChanged<AlbumFilter> onChanged;
  const _FilterChips({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final primary = c.accent;
    const items = <(AlbumFilter, String)>[
      // "Repetidas" lives in its own bottom-nav tab with a dedicated UI —
      // duplicating the filter here would make us maintain two identical
      // screens, and the visuals were drifting apart. Coleção now only
      // toggles between full and missing.
      (AlbumFilter.all, 'Todas'),
      (AlbumFilter.missing, 'Me faltam'),
    ];
    // Row of equal-width chips — each takes 1/3 of the width so labels
    // never truncate, and the bar uses minimal vertical space.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 6),
                child: FilterChip(
                  selected: current == items[i].$1,
                  onSelected: (_) => onChanged(items[i].$1),
                  label: SizedBox(
                    width: double.infinity,
                    child: Text(
                      items[i].$2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: current == items[i].$1 ? Colors.white : c.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  selectedColor: primary,
                  backgroundColor: c.cardAlt,
                  showCheckmark: false,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
