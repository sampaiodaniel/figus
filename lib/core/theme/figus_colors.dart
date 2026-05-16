import 'package:flutter/material.dart';

/// Adaptive surface palette — injected as ThemeExtension so every screen
/// picks up the right colors for the active seed (dark or light).
class FigusColors extends ThemeExtension<FigusColors> {
  final Color bg;        // scaffold background
  final Color card;      // primary card / container
  final Color cardAlt;   // appBar / secondary container (slightly different)
  final Color border;    // dividers / borders
  final Color text;      // primary text
  final Color textMuted; // secondary / hint text

  const FigusColors({
    required this.bg,
    required this.card,
    required this.cardAlt,
    required this.border,
    required this.text,
    required this.textMuted,
  });

  // ── Palettes ─────────────────────────────────────────────────────────────────

  static const dark = FigusColors(
    bg:        Color(0xFF13100E),
    card:      Color(0xFF2A231D),
    cardAlt:   Color(0xFF1E1916),
    border:    Color(0xFF3A322A),
    text:      Color(0xFFF5EFE3),
    textMuted: Color(0xFFBFAF9C),
  );

  /// Warm cream — used for Copa (emerald) light theme.
  static const warmLight = FigusColors(
    bg:        Color(0xFFFBF7EC),
    card:      Color(0xFFF0E8D5),
    cardAlt:   Color(0xFFE8DFC8),
    border:    Color(0xFFD4C9B0),
    text:      Color(0xFF13100E),
    textMuted: Color(0xFF5C4E43),
  );

  /// Cool lavender — used for Papel (violet) light theme.
  static const coolLight = FigusColors(
    bg:        Color(0xFFF4F0FF),
    card:      Color(0xFFEDE5FF),
    cardAlt:   Color(0xFFDDD0FF),
    border:    Color(0xFFCFBEF5),
    text:      Color(0xFF1A0E3A),
    textMuted: Color(0xFF6B5F8A),
  );

  // ── ThemeExtension boilerplate ────────────────────────────────────────────────

  @override
  FigusColors copyWith({
    Color? bg, Color? card, Color? cardAlt,
    Color? border, Color? text, Color? textMuted,
  }) =>
      FigusColors(
        bg:        bg        ?? this.bg,
        card:      card      ?? this.card,
        cardAlt:   cardAlt   ?? this.cardAlt,
        border:    border    ?? this.border,
        text:      text      ?? this.text,
        textMuted: textMuted ?? this.textMuted,
      );

  @override
  FigusColors lerp(FigusColors? other, double t) {
    if (other == null) return this;
    return FigusColors(
      bg:        Color.lerp(bg,        other.bg,        t)!,
      card:      Color.lerp(card,      other.card,      t)!,
      cardAlt:   Color.lerp(cardAlt,   other.cardAlt,   t)!,
      border:    Color.lerp(border,    other.border,    t)!,
      text:      Color.lerp(text,      other.text,      t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

/// Convenience accessor: `context.fc`.
extension FigusColorsX on BuildContext {
  FigusColors get fc =>
      Theme.of(this).extension<FigusColors>() ?? FigusColors.dark;
}
