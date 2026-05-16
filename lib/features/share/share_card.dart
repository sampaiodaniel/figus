import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/album_view_models.dart';

/// Visual card (1080×1080) used for WhatsApp / social sharing.
/// Rendered off-screen, captured to PNG by ShareService.
class ShareCard extends StatelessWidget {
  final AlbumStats stats;
  final String albumName;
  final String profileName;
  final Uint8List? iconBytes;

  const ShareCard({
    super.key,
    required this.stats,
    required this.albumName,
    required this.profileName,
    this.iconBytes,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (stats.percentComplete * 100).round();

    return Container(
      width: 1080,
      height: 1080,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E0B09), Color(0xFF1E1916), Color(0xFF2A1F10)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Subtle gold glow top-right
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 480,
              height: 480,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.gold.withValues(alpha: 0.14),
                    AppTheme.gold.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Logo ──────────────────────────────────────────────────
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: iconBytes != null
                          ? Image.memory(iconBytes!,
                              width: 80, height: 80, fit: BoxFit.cover)
                          : Container(
                              width: 80,
                              height: 80,
                              color: AppTheme.gold,
                              alignment: Alignment.center,
                              child: Text(
                                'F',
                                style: GoogleFonts.inter(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.inkDeep,
                                  height: 1,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 22),
                    Text(
                      'FIGUS',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.gold,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 56),

                // ── Album name + profile ──────────────────────────────────
                Text(
                  albumName,
                  style: GoogleFonts.inter(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.cream,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'por $profileName',
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 30,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.creamSoft,
                  ),
                ),

                const SizedBox(height: 56),

                // ── Big percentage ────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 40),
                  decoration: BoxDecoration(
                    color: AppTheme.ink3,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                        color: AppTheme.gold.withValues(alpha: 0.30),
                        width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$pct',
                        style: GoogleFonts.inter(
                          fontSize: 160,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.gold,
                          height: 0.9,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18, left: 8),
                        child: Text(
                          '%',
                          style: GoogleFonts.inter(
                            fontSize: 64,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.gold.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'completo',
                            style: GoogleFonts.inter(
                              fontSize: 38,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.creamSoft,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Stats 2×2 grid ────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                        child: _StatBox(
                            label: 'TENHO',
                            value: '${stats.owned}',
                            color: AppTheme.cream)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _StatBox(
                            label: 'FALTAM',
                            value: '${stats.missing}',
                            color: AppTheme.pulpSoft)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _StatBox(
                            label: 'REPETIDAS',
                            value: '${stats.duplicates}',
                            color: AppTheme.creamSoft)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _StatBox(
                            label: 'BRILHANTES',
                            value:
                                '${stats.foilOwned}/${stats.foilTotal}',
                            color: AppTheme.gold)),
                  ],
                ),

                const Spacer(),

                // ── Footer CTA ────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.gold,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz_rounded,
                              color: AppTheme.inkDeep, size: 32),
                          const SizedBox(width: 10),
                          Text(
                            'Vamos trocar?',
                            style: GoogleFonts.inter(
                              color: AppTheme.inkDeep,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'figus.app',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 24,
                        color: AppTheme.creamSoft.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: color.withValues(alpha: 0.22), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
