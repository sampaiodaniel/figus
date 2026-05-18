import 'package:flutter/material.dart';

import '../../core/theme/figus_colors.dart';
import 'theme_service.dart';

/// Mini mockup of how the Album screen renders under a given seed — used in
/// the theme picker so users see the actual feel, not just a swatch.
class ThemePreview extends StatelessWidget {
  final AppThemeSeed seed;
  final double width;

  const ThemePreview({super.key, required this.seed, this.width = 100});

  @override
  Widget build(BuildContext context) {
    final fc = seed.figusColors;
    final accent = seed.color;
    final height = width * 1.45;
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: fc.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fc.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // App-bar simulada
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: width * 0.25,
                  height: 5,
                  decoration: BoxDecoration(
                    color: fc.text,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 6,
                  height: 5,
                  decoration: BoxDecoration(
                    color: fc.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Stats pill simulando o card de progresso
            Container(
              height: 14,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: fc.cardAlt,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: width * 0.35,
                    height: 3,
                    decoration: BoxDecoration(
                      color: fc.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Filter chip simulado
            Row(
              children: [
                Container(
                  width: width * 0.22,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 3),
                Container(
                  width: width * 0.18,
                  height: 6,
                  decoration: BoxDecoration(
                    color: fc.cardAlt,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Mini grid de stickers — alternando "tem" (accent) com "falta" (muted)
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                childAspectRatio: 0.85,
                children: [
                  for (final owned in _ownedPattern)
                    Container(
                      decoration: BoxDecoration(
                        gradient: owned
                            ? LinearGradient(
                                colors: [
                                  accent,
                                  Color.lerp(accent, Colors.black, 0.2)!,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: owned ? null : fc.cardAlt,
                        borderRadius: BorderRadius.circular(2),
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

  // Fixed pattern so previews are stable across rebuilds — looks like a real
  // collection in progress.
  static const _ownedPattern = <bool>[
    true,  true,  false, true,
    true,  false, false, true,
    false, true,  true,  false,
  ];
}
