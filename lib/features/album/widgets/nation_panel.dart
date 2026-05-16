import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/country_codes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/figus_colors.dart';
import '../../../data/seeds/wc2026_seed.dart';
import '../../../domain/models/album_view_models.dart';
import 'sticker_card.dart';

/// An expandable panel for a single album section (FWC, FWC9+, nation, …).
/// Tap header → expand inline grid; tap again → collapse.
class NationPanel extends StatelessWidget {
  final AlbumSection section;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(StickerView) onTapSticker;
  final void Function(StickerView) onLongPressSticker;

  const NationPanel({
    super.key,
    required this.section,
    required this.expanded,
    required this.onToggle,
    required this.onTapSticker,
    required this.onLongPressSticker,
  });

  static String _nameFromTitle(String title) {
    final idx = title.indexOf('-');
    if (idx < 0) return title;
    return title.substring(idx + 1).trim();
  }

  @override
  Widget build(BuildContext context) {
    final owned = section.ownedCount;
    final total = section.totalCount;
    final progress = total == 0 ? 0.0 : owned / total;
    final complete = owned == total && total > 0;
    final dupes = section.stickers
        .where((s) => s.status == StickerOwnership.duplicate)
        .fold<int>(0, (sum, s) => sum + s.duplicateCount);

    final iso = paniniToIso2[section.key];
    final nameOnly = _nameFromTitle(section.title);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.ink,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.ink4),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Flag or fallback
                        if (iso != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CountryFlag.fromCountryCode(
                              iso,
                              width: 36,
                              height: 26,
                            ),
                          )
                        else
                          _SpecialThumb(code: section.key),

                        const SizedBox(width: 14),

                        // Name + complete badge
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  nameOnly,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.cream,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (complete)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.gold,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'COMPLETO',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9,
                                        color: AppTheme.inkDeep,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Count + dupes
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$owned/$total',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.cream,
                              ),
                            ),
                            if (dupes > 0)
                              Text(
                                '+$dupes rep',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9,
                                  color: AppTheme.pulpSoft,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(width: 4),

                        Icon(
                          expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: AppTheme.creamSoft,
                          size: 18,
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Progress bar
                    Builder(builder: (ctx) {
                      final ac = ctx.fc.accent;
                      return LayoutBuilder(
                        builder: (ctx2, constraints) => Container(
                          height: 4,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.ink4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 4,
                              width: constraints.maxWidth * progress,
                              decoration: BoxDecoration(
                                color: complete
                                    ? ac
                                    : ac.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Expanded sticker grid ────────────────────────────────────────────
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: _PaniniGrid(
              section: section,
              onTap: onTapSticker,
              onLongPress: onLongPressSticker,
            ),
          ),
      ],
    );
  }
}

// ── Special thumb for non-country keys (FWC, FWC9+, CC, LGD) ────────────────

class _SpecialThumb extends StatelessWidget {
  final String code;
  const _SpecialThumb({required this.code});

  @override
  Widget build(BuildContext context) {
    return switch (code) {
      'FWC' => _thumb(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F66FF), Color(0xFF7A5BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          child: const Icon(Icons.emoji_events_rounded,
              color: Colors.amber, size: 20),
        ),
      'FWC9+' => _thumb(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB8860B), Color(0xFF8B6914)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          child: const Icon(Icons.star_rounded, color: Colors.white, size: 18),
        ),
      'CC' => _thumb(
          decoration: const BoxDecoration(
            color: Color(0xFFCC0000),
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          child: const Text(
            'CC',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1),
          ),
        ),
      'LGD' => _thumb(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF40CCFF), Color(0xFF8840FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          child:
              const Icon(Icons.stars_rounded, color: Colors.white, size: 18),
        ),
      _ => _thumb(
          decoration: const BoxDecoration(
            color: AppTheme.ink4,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          child: Text(code,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.cream)),
        ),
    };
  }

  static Widget _thumb(
      {required BoxDecoration decoration, required Widget child}) {
    return Container(
      width: 36,
      height: 26,
      alignment: Alignment.center,
      decoration: decoration,
      child: child,
    );
  }
}

/// Same physical-album layout used before, but rendered inline (no AppBar /
/// scaffolding) for the accordion expansion.
class _PaniniGrid extends StatelessWidget {
  final AlbumSection section;
  final void Function(StickerView) onTap;
  final void Function(StickerView) onLongPress;

  const _PaniniGrid({
    required this.section,
    required this.onTap,
    required this.onLongPress,
  });

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    final byPosition = {for (final s in section.stickers) s.positionInPage: s};
    final isNation = section.key != 'FWC' &&
        section.key != 'FWC9+' &&
        section.key != 'CC' &&
        section.key != 'LGD';

    return LayoutBuilder(builder: (ctx, c) {
      final cell = (c.maxWidth - 3 * _gap) / 4;
      final cellH = cell * 4 / 3;

      Widget tile(int idx, {double? width, double? height}) {
        final st = byPosition[idx];
        final w = width ?? cell;
        final h = height ?? cellH;
        if (st == null) return SizedBox(width: w, height: h);
        return SizedBox(
          width: w,
          height: h,
          child: StickerCard(
            key: ValueKey('sticker-${st.id}'),
            sticker: st,
            onTap: () => onTap(st),
            onLongPress: () => onLongPress(st),
          ),
        );
      }

      if (!isNation) {
        // Specials: simple uniform 4-col grid.
        final stickers = [...section.stickers]
          ..sort((a, b) => a.positionInPage.compareTo(b.positionInPage));
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final st in stickers)
              SizedBox(
                width: cell,
                height: cellH,
                child: StickerCard(
                  key: ValueKey('sticker-${st.id}'),
                  sticker: st,
                  onTap: () => onTap(st),
                  onLongPress: () => onLongPress(st),
                ),
              ),
          ],
        );
      }

      // Per-nation layout matches the printed album page (header occupies
      // 2x1, #13 is landscape, last row aligned right).
      final headerW = 2 * cell + _gap;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page 1
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderBlock(width: headerW, height: cellH, section: section),
              const SizedBox(width: _gap),
              tile(0),
              const SizedBox(width: _gap),
              tile(1),
            ],
          ),
          const SizedBox(height: _gap),
          _row4(tile, 2),
          const SizedBox(height: _gap),
          _row4(tile, 6),
          const SizedBox(height: _gap * 2),
          const _PageDivider(),
          const SizedBox(height: _gap * 2),
          // Page 2
          Row(
            children: [
              tile(10),
              const SizedBox(width: _gap),
              tile(11),
              const SizedBox(width: _gap),
              tile(12, width: 2 * cell + _gap, height: cellH),
            ],
          ),
          const SizedBox(height: _gap),
          _row4(tile, 13),
          const SizedBox(height: _gap),
          Row(
            children: [
              SizedBox(width: cell + _gap),
              tile(17),
              const SizedBox(width: _gap),
              tile(18),
              const SizedBox(width: _gap),
              tile(19),
            ],
          ),
        ],
      );
    });
  }

  Widget _row4(Widget Function(int) tile, int start) => Row(
        children: [
          tile(start),
          const SizedBox(width: _gap),
          tile(start + 1),
          const SizedBox(width: _gap),
          tile(start + 2),
          const SizedBox(width: _gap),
          tile(start + 3),
        ],
      );
}

class _HeaderBlock extends StatelessWidget {
  final double width;
  final double height;
  final AlbumSection section;
  const _HeaderBlock(
      {required this.width, required this.height, required this.section});

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
          colors: [AppTheme.seed, AppTheme.seed.withValues(alpha: 0.7)],
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
                  child:
                      CountryFlag.fromCountryCode(iso, width: 22, height: 16),
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
