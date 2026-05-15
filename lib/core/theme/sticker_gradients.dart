import 'package:flutter/material.dart';

/// Gradient palette per nation using each team's actual kit colors.
/// Foil stickers get a separate holographic shimmer.
class StickerGradients {
  // Official kit colors per nation code.
  static const Map<String, List<Color>> _nationColors = {
    'MEX': [Color(0xFF006847), Color(0xFFCE1126)],
    'RSA': [Color(0xFF007A4D), Color(0xFFFFB81C)],
    'KOR': [Color(0xFFC60C30), Color(0xFF003478)],
    'CZE': [Color(0xFF11457E), Color(0xFFD7141A)],
    'CAN': [Color(0xFFCC0000), Color(0xFF8B0000)],
    'BIH': [Color(0xFF002395), Color(0xFF1A47A0)],
    'QAT': [Color(0xFF8D153A), Color(0xFF5A0D26)],
    'SUI': [Color(0xFFCC0000), Color(0xFF990000)],
    'BRA': [Color(0xFF009C3B), Color(0xFFCCA800)],
    'MAR': [Color(0xFFC1272D), Color(0xFF006233)],
    'HAI': [Color(0xFF00209F), Color(0xFFD21034)],
    'SCO': [Color(0xFF003078), Color(0xFF1A4792)],
    'USA': [Color(0xFF3C3B6E), Color(0xFFB22234)],
    'PAR': [Color(0xFF0038A8), Color(0xFFD52B1E)],
    'AUS': [Color(0xFF00843D), Color(0xFF8B7000)],
    'TUR': [Color(0xFFE30A17), Color(0xFF8B0000)],
    'GER': [Color(0xFF222222), Color(0xFFBB9900)],
    'CUW': [Color(0xFF002B7F), Color(0xFFB8A800)],
    'CIV': [Color(0xFFF77F00), Color(0xFF009A44)],
    'ECU': [Color(0xFF0072CE), Color(0xFFBB9700)],
    'NED': [Color(0xFFCC5200), Color(0xFFE05000)],
    'JPN': [Color(0xFFBC002D), Color(0xFF7A001D)],
    'SWE': [Color(0xFF006AA7), Color(0xFF8B7200)],
    'TUN': [Color(0xFFCC0010), Color(0xFF8B0008)],
    'BEL': [Color(0xFFEF3340), Color(0xFF1E1E1E)],
    'EGY': [Color(0xFFCE1126), Color(0xFF1A1A1A)],
    'IRN': [Color(0xFF239F40), Color(0xFFB80000)],
    'NZL': [Color(0xFF1A1A1A), Color(0xFF444444)],
    'ESP': [Color(0xFFAA151B), Color(0xFFB88800)],
    'CPV': [Color(0xFF003893), Color(0xFFCF2027)],
    'KSA': [Color(0xFF006C35), Color(0xFF004520)],
    'URU': [Color(0xFF4A8BC4), Color(0xFF0038A8)],
    'FRA': [Color(0xFF002395), Color(0xFFCC1B2C)],
    'SEN': [Color(0xFF00853F), Color(0xFFBB9900)],
    'IRQ': [Color(0xFF1A1A1A), Color(0xFFCC1126)],
    'NOR': [Color(0xFFCC2020), Color(0xFF002868)],
    'ARG': [Color(0xFF5599CC), Color(0xFF3377AA)],
    'ALG': [Color(0xFF006233), Color(0xFFB81026)],
    'AUT': [Color(0xFFCC2030), Color(0xFF880010)],
    'JOR': [Color(0xFF007A3D), Color(0xFFCE1126)],
    'POR': [Color(0xFF006600), Color(0xFFCC0000)],
    'COD': [Color(0xFF0050CC), Color(0xFFCE1126)],
    'UZB': [Color(0xFF1EB53A), Color(0xFF0099B5)],
    'COL': [Color(0xFFAA8800), Color(0xFF003087)],
    'ENG': [Color(0xFFCC0010), Color(0xFF8B000A)],
    'CRO': [Color(0xFFCC0000), Color(0xFF171796)],
    'GHA': [Color(0xFF006B3F), Color(0xFFAA8800)],
    'PAN': [Color(0xFFBB0F14), Color(0xFF074F9D)],
    // Intro specials (FWC00–FWC8) — primary brand blue
    'FWC': [Color(0xFF1F66FF), Color(0xFF7A5BFF)],
    // Legends (FWC9+) — gold
    'FWC9+': [Color(0xFFB8860B), Color(0xFF8B6914)],
  };

  /// Returns a gradient using the nation's actual kit colors.
  static LinearGradient forNation(String nationCode) {
    final colors = _nationColors[nationCode] ?? _nationColors['FWC']!;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  /// Foil/holographic shimmer for special stickers.
  static const LinearGradient foilShimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFD27E),
      Color(0xFFFF93C9),
      Color(0xFF8FB8FF),
      Color(0xFFA0F0CF),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );
}
