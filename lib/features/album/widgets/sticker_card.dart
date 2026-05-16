import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/sticker_gradients.dart';
import '../../../domain/models/album_view_models.dart';

/// Sticker card — new dark-first design
///
/// missing  → dark ink bg, dashed border, just shows #number in cream
/// owned    → cream/paper bg with vibrant gradient top zone + dark footer
/// dupe     → owned state + magenta ×N badge
/// foil/rare → gold shimmer overlay
class StickerCard extends StatelessWidget {
  final StickerView sticker;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double? aspectRatio;

  const StickerCard({
    super.key,
    required this.sticker,
    required this.onTap,
    required this.onLongPress,
    this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final owned = sticker.status != StickerOwnership.missing;
    final isDupe = sticker.status == StickerOwnership.duplicate;
    final foil   = sticker.isFoil;

    final isLegendary = sticker.type.startsWith('legendary_');
    final isCrest     = sticker.type == 'crest';

    final gradient = owned
        ? (isLegendary
            ? StickerGradients.forLegendary(sticker.type)
            : isCrest
                ? StickerGradients.forCrest(sticker.nationCode ?? 'FWC')
                : foil
                    ? StickerGradients.foilShimmer
                    : StickerGradients.forNation(sticker.nationCode ?? 'FWC'))
        : null;

    final headerText = isLegendary
        ? sticker.type.substring('legendary_'.length).toUpperCase()
        : sticker.nationCode ??
            (sticker.number.startsWith('CC') ? 'CC' : 'FWC');
    final numericPart = sticker.number.replaceAll(RegExp(r'^[A-Z]+'), '');

    Widget card = GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (owned)
            _OwnedCard(
              gradient: gradient!,
              headerText: headerText,
              numericPart: numericPart,
              displayName: sticker.displayName,
              foil: foil,
            )
          else
            _MissingCard(
              headerText: headerText,
              numericPart: numericPart,
            ),
          if (isDupe)
            Positioned(
              top: -7,
              right: -7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.pulp,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.inkDeep, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.pulp.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(minWidth: 24),
                child: Text(
                  '×${sticker.duplicateCount}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (aspectRatio != null) {
      return AspectRatio(aspectRatio: aspectRatio!, child: card);
    }
    return card;
  }
}

class _MissingCard extends StatelessWidget {
  final String headerText;
  final String numericPart;
  const _MissingCard({required this.headerText, required this.numericPart});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      final w = c.maxWidth;
      final numFs = (w * 0.32).clamp(16.0, 26.0);
      final labelFs = (w * 0.11).clamp(8.0, 11.0);
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.inkDeep,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.ink4,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              headerText,
              style: TextStyle(
                fontSize: labelFs,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '#$numericPart',
              style: TextStyle(
                fontSize: numFs,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink4,
                height: 1.0,
              ),
            ),
            SizedBox(height: labelFs),
          ],
        ),
      );
    });
  }
}

class _OwnedCard extends StatelessWidget {
  final LinearGradient gradient;
  final String headerText;
  final String numericPart;
  final String? displayName;
  final bool foil;
  const _OwnedCard({
    required this.gradient,
    required this.headerText,
    required this.numericPart,
    required this.displayName,
    required this.foil,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final numFs = (w * 0.34).clamp(18.0, 28.0);
      final labelFs = (w * 0.10).clamp(8.0, 11.0);
      final footerH = (h * 0.32).clamp(28.0, 44.0);

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Gradient top zone
              Expanded(
                child: Container(
                  decoration: BoxDecoration(gradient: gradient),
                  padding: const EdgeInsets.fromLTRB(6, 7, 6, 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            headerText,
                            style: TextStyle(
                              fontSize: labelFs,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (foil)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '★',
                                style: TextStyle(
                                  fontSize: labelFs - 1,
                                  color: AppTheme.goldSoft,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '#$numericPart',
                        style: TextStyle(
                          fontSize: numFs,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                          shadows: const [
                            Shadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Cream footer with player name
              SizedBox(
                height: footerH,
                child: Container(
                  color: AppTheme.cream,
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  alignment: Alignment.center,
                  child: Text(
                    displayName ?? headerText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: labelFs,
                      height: 1.15,
                      color: AppTheme.darkText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Banner card (landscape) for crest + team photo at top of nation sections.
class StickerBanner extends StatelessWidget {
  final StickerView sticker;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final IconData icon;
  final String displayLabel;

  const StickerBanner({
    super.key,
    required this.sticker,
    required this.onTap,
    required this.onLongPress,
    required this.icon,
    required this.displayLabel,
  });

  @override
  Widget build(BuildContext context) {
    final owned = sticker.status != StickerOwnership.missing;
    final isDupe = sticker.status == StickerOwnership.duplicate;
    final foil   = sticker.isFoil;

    final gradient = owned
        ? (sticker.type.startsWith('legendary_')
            ? StickerGradients.forLegendary(sticker.type)
            : sticker.type == 'crest'
                ? StickerGradients.forCrest(sticker.nationCode ?? 'FWC')
                : foil
                    ? StickerGradients.foilShimmer
                    : StickerGradients.forNation(sticker.nationCode ?? 'FWC'))
        : null;

    final numericPart = sticker.number.replaceAll(RegExp(r'^[A-Z]+'), '');

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: owned ? null : AppTheme.inkDeep,
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              border: owned
                  ? null
                  : Border.all(color: AppTheme.ink4, width: 1.5),
              boxShadow: owned
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, size: 38,
                    color: owned ? Colors.white : AppTheme.ink4),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w700,
                            color: owned
                                ? Colors.white.withValues(alpha: 0.85)
                                : AppTheme.ink4,
                          )),
                      const SizedBox(height: 2),
                      Text('#$numericPart',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: owned ? Colors.white : AppTheme.inkSoft,
                          )),
                    ],
                  ),
                ),
                if (foil)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: owned ? 0.25 : 0.0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: owned ? Colors.white : AppTheme.ink4,
                        width: 1,
                      ),
                    ),
                    child: Text('FOIL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: owned ? Colors.white : AppTheme.inkSoft,
                        )),
                  ),
              ],
            ),
          ),
          if (isDupe)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.pulp,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.inkDeep, width: 2),
                ),
                constraints: const BoxConstraints(minWidth: 26),
                child: Text('×${sticker.duplicateCount}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
        ],
      ),
    );
  }
}
