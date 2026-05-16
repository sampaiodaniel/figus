import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/country_codes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../data/seeds/wc2026_matches_seed.dart';
import '../../domain/models/album_view_models.dart';
import 'widgets/sticker_card.dart';

/// Page dedicated to ONE nation, laid out like the printed Panini album:
///
///   Page 1                       Page 2
///   ┌──────────┬──────┬──────┐   ┌──────┬──────┬─────────────┐
///   │  WE ARE  │  #1  │  #2  │   │ #11  │ #12  │   #13 (2x1) │
///   │  BRAZIL  ├──────┴──────┤   ├──────┼──────┼──────┬──────┤
///   │  brasão  │             │   │ #14  │ #15  │ #16  │ #17  │
///   ├──┬───┬───┴──┬───┬──────┤   ├──────┼──────┼──────┼──────┤
///   │#3│#4 │ #5   │#6 │      │   │GROUP │ #18  │ #19  │ #20  │
///   ├──┼───┼──────┼───┤      │   │      │      │      │      │
///   │#7│#8 │ #9   │#10│      │   └──────┴──────┴──────┴──────┘
///   └──┴───┴──────┴───┘
class NationDetailPage extends ConsumerStatefulWidget {
  final String code;
  const NationDetailPage({super.key, required this.code});

  @override
  ConsumerState<NationDetailPage> createState() => _NationDetailPageState();
}

class _NationDetailPageState extends ConsumerState<NationDetailPage> {
  final _scrollCtrl = ScrollController();
  // Cache of the last successfully-loaded section so a tap doesn't show a
  // loading spinner that would also drop the scroll position.
  AlbumSection? _cached;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Derive group letter for this team
  String? get _groupLetter {
    for (final entry in WC2026Matches.groupTeams.entries) {
      if (entry.value.contains(widget.code)) return entry.key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final asyncSection = ref.watch(_nationSectionProvider(widget.code));
    if (asyncSection.hasValue && asyncSection.value != null) {
      _cached = asyncSection.value;
    }
    final section = asyncSection.value ?? _cached;
    final group = _groupLetter;

    return Scaffold(
      appBar: AppBar(
        title: Text(section?.title.split(' - ').last ?? widget.code),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (section != null && section.totalCount > 0)
            _StatsHeader(section: section, group: group),
          Expanded(child: _buildBody(asyncSection, section)),
        ],
      ),
    );
  }

  Widget _buildBody(AsyncValue<AlbumSection?> async, AlbumSection? section) {
    if (section == null || section.totalCount == 0) {
      if (async.isLoading) return const Center(child: CircularProgressIndicator());
      if (async.hasError) return Center(child: Text('Erro: ${async.error}'));
      return const Center(child: Text('Seleção não encontrada'));
    }
    return _PaniniLayout(
      scrollController: _scrollCtrl,
      section: section,
      onTap: (st) async {
        HapticFeedback.lightImpact();
        await ref.read(collectionRepoProvider).tapSticker(st.id);
        ref.read(collectionVersionProvider.notifier).state++;
      },
      onLongPress: (st) async {
        if (st.status == StickerOwnership.missing) return;
        HapticFeedback.mediumImpact();
        await ref.read(collectionRepoProvider).removeSticker(st.id);
        ref.read(collectionVersionProvider.notifier).state++;
      },
    );
  }

}

// ── Stats header ──────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  final AlbumSection section;
  final String? group;
  const _StatsHeader({required this.section, required this.group});

  @override
  Widget build(BuildContext context) {
    final owned = section.ownedCount;
    final total = section.totalCount;
    final missing = total - owned;
    final duplicates = section.stickers
        .where((s) => s.status == StickerOwnership.duplicate)
        .fold(0, (sum, s) => sum + s.duplicateCount);
    final pct = total > 0 ? (owned / total * 100).round() : 0;

    final iso = paniniToIso2[section.key];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        border: const Border(bottom: BorderSide(color: AppTheme.ink4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Flag
          if (iso != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CountryFlag.fromCountryCode(iso, width: 48, height: 34),
            )
          else
            Container(
              width: 48, height: 34,
              decoration: BoxDecoration(
                color: AppTheme.slotSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(section.key,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (group != null)
                  Text('GRUPO $group  ·  $total figurinhas',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.gold,
                        letterSpacing: 0.4,
                      )),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Stat(label: 'TENHO', value: '$owned',
                        color: AppTheme.gold),
                    const SizedBox(width: 16),
                    _Stat(label: 'FALTAM', value: '$missing',
                        color: AppTheme.inkSoft),
                    const SizedBox(width: 16),
                    _Stat(label: 'REPETIDAS', value: '$duplicates',
                        color: const Color(0xFF1F66FF)),
                  ],
                ),
              ],
            ),
          ),
          // Percent circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48, height: 48,
                child: CircularProgressIndicator(
                  value: pct / 100,
                  strokeWidth: 4,
                  backgroundColor: AppTheme.slotSoft,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
                ),
              ),
              Text('$pct%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.gold,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                color: AppTheme.inkSoft, letterSpacing: 0.4)),
      ],
    );
  }
}

// ── Panini layout ─────────────────────────────────────────────────────────────

class _PaniniLayout extends StatelessWidget {
  final AlbumSection section;
  final ScrollController scrollController;
  final void Function(StickerView) onTap;
  final void Function(StickerView) onLongPress;

  const _PaniniLayout({
    required this.section,
    required this.scrollController,
    required this.onTap,
    required this.onLongPress,
  });

  static const _gap = 8.0;
  static const _hpad = 12.0;

  @override
  Widget build(BuildContext context) {
    final byPosition = {for (final s in section.stickers) s.positionInPage: s};

    return SingleChildScrollView(
      key: const PageStorageKey('nation-detail-scroll'),
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(_hpad, _hpad, _hpad, 24),
      child: LayoutBuilder(builder: (ctx, constraints) {
        final cell = (constraints.maxWidth - 3 * _gap) / 4;
        final cellH = cell * 4 / 3; // portrait

        Widget tile(int idx, {double? width, double? height, bool landscape = false}) {
          final st = byPosition[idx];
          final w = width ?? cell;
          final h = height ?? cellH;
          if (st == null) {
            return SizedBox(width: w, height: h);
          }
          return SizedBox(
            width: w,
            height: h,
            child: StickerCard(
              key: ValueKey('detail-${st.id}'),
              sticker: st,
              onTap: () => onTap(st),
              onLongPress: () => onLongPress(st),
              // aspectRatio null: card fills the SizedBox exactly, no internal
              // AspectRatio that could shrink it by sub-pixel rounding.
            ),
          );
        }

        // Header spans 2 cols × 1 row (same height as a sticker — per WF).
        final headerW = 2 * cell + _gap;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── PÁGINA 1 ─────────────────────────────────────────
            //  ROW: HEADER (2×1)  |  #1  |  #2
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderBlock(
                  width: headerW,
                  height: cellH,
                  section: section,
                ),
                const SizedBox(width: _gap),
                tile(0), // #1
                const SizedBox(width: _gap),
                tile(1), // #2
              ],
            ),
            const SizedBox(height: _gap),
            // ROW: #3 #4 #5 #6
            _rowOf4(tile, 2, _gap),
            const SizedBox(height: _gap),
            // ROW: #7 #8 #9 #10
            _rowOf4(tile, 6, _gap),
            const SizedBox(height: _gap * 2),
            const _PageDivider(),
            const SizedBox(height: _gap * 2),
            // ── PÁGINA 2 ─────────────────────────────────────────
            // ROW: #11 #12 [#13 landscape 2×1]
            Row(
              children: [
                tile(10), // #11
                const SizedBox(width: _gap),
                tile(11), // #12
                const SizedBox(width: _gap),
                tile(12, width: 2 * cell + _gap, height: cellH, landscape: true),
              ],
            ),
            const SizedBox(height: _gap),
            // ROW: #14 #15 #16 #17
            _rowOf4(tile, 13, _gap),
            const SizedBox(height: _gap),
            // ROW: (empty space) #18 #19 #20 — alinhados à direita
            Row(
              children: [
                SizedBox(width: cell + _gap), // espaço vazio à esquerda
                tile(17), // #18
                const SizedBox(width: _gap),
                tile(18), // #19
                const SizedBox(width: _gap),
                tile(19), // #20
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _rowOf4(Widget Function(int) tile, int startPos, double gap) {
    return Row(
      children: [
        tile(startPos),
        SizedBox(width: gap),
        tile(startPos + 1),
        SizedBox(width: gap),
        tile(startPos + 2),
        SizedBox(width: gap),
        tile(startPos + 3),
      ],
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  final double width;
  final double height;
  final AlbumSection section;
  const _HeaderBlock({required this.width, required this.height, required this.section});

  @override
  Widget build(BuildContext context) {
    final iso = paniniToIso2[section.key];
    final name = _nameFromTitle(section.title);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.gold, AppTheme.goldDeep],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text('WE ARE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                  )),
              const Spacer(),
              if (iso != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CountryFlag.fromCountryCode(iso, width: 22, height: 16),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _nameFromTitle(String title) {
    final idx = title.indexOf('-');
    if (idx < 0) return title;
    return title.substring(idx + 1).trim();
  }
}

class _PageDivider extends StatelessWidget {
  const _PageDivider();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('FIFA WORLD CUP 2026',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.4,
                color: AppTheme.inkSoft.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
              )),
        ),
        const Expanded(child: Divider(thickness: 1)),
      ],
    );
  }
}

final _nationSectionProvider =
    FutureProvider.autoDispose.family<AlbumSection?, String>((ref, code) async {
  ref.watch(collectionVersionProvider);
  final repo = ref.watch(albumRepoProvider);
  final sections = await repo.loadSections();
  return sections.firstWhere(
    (s) => s.key == code,
    orElse: () => const AlbumSection(
      key: '',
      title: '',
      flag: null,
      ownedCount: 0,
      totalCount: 0,
      stickers: [],
    ),
  );
});
