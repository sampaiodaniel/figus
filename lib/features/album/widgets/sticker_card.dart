import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/sticker_gradients.dart';
import '../../../domain/models/album_view_models.dart';

/// Vertical card matching the user's reference screenshots:
/// - missing: neutral grey
/// - owned:   vibrant gradient
/// - duplicate: vibrant gradient + blue badge with count
/// - foil: holographic shimmer overlay
class StickerCard extends StatelessWidget {
  final StickerView sticker;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  // When non-null the card wraps itself in an AspectRatio. When null (the
  // default in callers that already provide a fixed SizedBox) the card fills
  // its parent so no extra rounding shrinks the slot.
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
    final foil = sticker.isFoil;

    final isLegendary = sticker.type.startsWith('legendary_');
    final isCrest = sticker.type == 'crest';
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

    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: owned ? null : AppTheme.slotSoft,
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              border: owned
                  ? null
                  : Border.all(color: AppTheme.slot.withValues(alpha: 0.4), width: 1),
              boxShadow: owned
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: LayoutBuilder(builder: (ctx, c) {
              final w = c.maxWidth;
              final headerFs = (w * 0.13).clamp(8.0, 12.0);
              final numFs = (w * 0.34).clamp(18.0, 28.0);
              final labelFs = (w * 0.10).clamp(8.0, 11.0);
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    headerText,
                    style: TextStyle(
                      fontSize: headerFs,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                      color: owned
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppTheme.inkSoft,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '#$numericPart',
                    style: TextStyle(
                      fontSize: numFs,
                      fontWeight: FontWeight.w800,
                      color: owned ? Colors.white : AppTheme.ink,
                      shadows: owned
                          ? [const Shadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1))]
                          : null,
                    ),
                  ),
                  if (sticker.displayName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        sticker.displayName!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: labelFs,
                          height: 1.1,
                          color: owned
                              ? Colors.white.withValues(alpha: 0.95)
                              : AppTheme.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    SizedBox(height: labelFs + 2),
                ],
              );
            }),
          ),
        ),
        if (sticker.status == StickerOwnership.duplicate)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.seed,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 26),
              child: Text(
                '${sticker.duplicateCount}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );

    final card = GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      child: stack,
    );

    // Caller may not constrain us (e.g. inside a GridView): wrap with the
    // requested AspectRatio in that case. When the parent does constrain us
    // (NationDetailPage uses fixed SizedBoxes), skip AspectRatio so sub-pixel
    // rounding never shrinks one cell vs another.
    if (aspectRatio != null) {
      return AspectRatio(aspectRatio: aspectRatio!, child: card);
    }
    return card;
  }
}

/// Banner-style card used for the crest + team-photo on the top of each nation
/// section, mimicking the physical Panini album layout.
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
    final foil = sticker.isFoil;

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
              color: owned ? null : AppTheme.slotSoft,
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              border: owned
                  ? null
                  : Border.all(color: AppTheme.slot.withValues(alpha: 0.4), width: 1),
              boxShadow: owned
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon,
                    size: 38,
                    color: owned ? Colors.white : AppTheme.inkSoft),
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
                                : AppTheme.inkSoft,
                          )),
                      const SizedBox(height: 2),
                      Text('#$numericPart',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: owned ? Colors.white : AppTheme.ink,
                            shadows: owned
                                ? [
                                    const Shadow(
                                      color: Color(0x33000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ]
                                : null,
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
                        color: owned ? Colors.white : AppTheme.slot,
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
          if (sticker.status == StickerOwnership.duplicate)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.seed,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                constraints: const BoxConstraints(minWidth: 26),
                child: Text('${sticker.duplicateCount}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
