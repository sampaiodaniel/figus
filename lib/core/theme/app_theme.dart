import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'figus_colors.dart';

class AppTheme {
  // ── Brand palette ───────────────────────────────────────────────────────────
  static const gold     = Color(0xFFE5B14B); // primary accent
  static const goldDeep = Color(0xFFB0813A);
  static const goldSoft = Color(0xFFF2CE7E);
  static const pulp     = Color(0xFFD04A7E); // Figus magenta
  static const pulpDeep = Color(0xFF8A2E5A);
  static const pulpSoft = Color(0xFFF18BAE);
  static const field    = Color(0xFF2E8F4F); // Copa green
  static const sky      = Color(0xFF3F8FE0);
  static const flame    = Color(0xFFE85A3C);

  // ── Dark palette (ink tones) ────────────────────────────────────────────────
  static const inkDeep  = Color(0xFF13100E);
  static const ink      = Color(0xFF1E1916);
  static const ink3     = Color(0xFF2A231D);
  static const ink4     = Color(0xFF3A322A);
  static const cream    = Color(0xFFF5EFE3);
  static const creamSoft= Color(0xFFBFAF9C);

  // ── Light palette (paper tones) ────────────────────────────────────────────
  static const paper    = Color(0xFFFBF7EC);
  static const paper2   = Color(0xFFF0E8D5);
  static const darkText = Color(0xFF13100E);
  static const darkTextSoft = Color(0xFF5C4E43);

  // ── Legacy aliases ──────────────────────────────────────────────────────────
  static const seed     = gold;
  static const inkSoft  = creamSoft;
  static const slot     = ink4;
  static const slotSoft = ink3;

  // ── Theme builders ──────────────────────────────────────────────────────────

  static ThemeData light({Color? overrideSeed, FigusColors? figusColors}) {
    final s = overrideSeed ?? gold;
    final fc = figusColors ?? FigusColors.warmLight;
    final scheme = ColorScheme.fromSeed(seedColor: s, brightness: Brightness.light)
        .copyWith(
          surface:              fc.bg,
          onSurface:            fc.text,
          surfaceContainer:     fc.card,
          surfaceContainerHigh: fc.cardAlt,
        );
    return _base(scheme, isDark: false, fc: fc);
  }

  static ThemeData dark({Color? overrideSeed, FigusColors? figusColors}) {
    final s = overrideSeed ?? gold;
    final fc = figusColors ?? FigusColors.dark;
    final scheme = ColorScheme.fromSeed(seedColor: s, brightness: Brightness.dark)
        .copyWith(
          surface:              fc.bg,
          onSurface:            fc.text,
          surfaceContainer:     fc.card,
          surfaceContainerHigh: fc.cardAlt,
          secondary:    pulp,
          onSecondary:  Colors.white,
        );
    return _base(scheme, isDark: true, fc: fc);
  }

  static ThemeData _base(ColorScheme scheme, {required bool isDark, required FigusColors fc}) {
    final text = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [fc],
      scaffoldBackgroundColor: fc.bg,
      textTheme: text.apply(
        bodyColor:    scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:  fc.cardAlt,
        foregroundColor:  scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: fc.cardAlt,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        showUnselectedLabels: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: fc.cardAlt,
        indicatorColor: scheme.primary.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: fc.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: fc.cardAlt,
        side: BorderSide.none,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: fc.border,
        thickness: 1,
      ),
    );
  }
}
