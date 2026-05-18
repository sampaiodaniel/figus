import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Available avatars. Each one is identified by a stable [id] (e.g.
/// `avatar_01`). The legacy emoji avatars from the first MVP keep working
/// because [AvatarImage] falls back to a Text widget for non-asset ids.
class FigusAvatar {
  final String id;
  final String label;
  final bool proOnly;

  const FigusAvatar({
    required this.id,
    required this.label,
    required this.proOnly,
  });

  /// SVG asset path. Only valid for cartoon avatars (id starts with `avatar_`).
  String get assetPath => 'assets/avatars/$id.svg';
}

/// 25 cartoon avatars generated via the DiceBear "avataaars" API (see
/// tool/fetch_avatars.ps1). 5 are free, covering basic ethnicity/gender
/// representation; the remaining 20 are Pro (varied looks + festive themes).
const figusAvatars = <FigusAvatar>[
  // ── free (5) — basic representation ──────────────────────────────────────
  FigusAvatar(id: 'avatar_01', label: 'Loira',        proOnly: false),
  FigusAvatar(id: 'avatar_02', label: 'Castanho',     proOnly: false),
  FigusAvatar(id: 'avatar_03', label: 'Barba',        proOnly: false),
  FigusAvatar(id: 'avatar_04', label: 'Afro',         proOnly: false),
  FigusAvatar(id: 'avatar_05', label: 'Lisa',         proOnly: false),

  // ── pro · classics (7) ───────────────────────────────────────────────────
  FigusAvatar(id: 'avatar_06', label: 'Morena',       proOnly: true),
  FigusAvatar(id: 'avatar_07', label: 'Veterano',     proOnly: true),
  FigusAvatar(id: 'avatar_08', label: 'Ruiva',        proOnly: true),
  FigusAvatar(id: 'avatar_09', label: 'Jovem',        proOnly: true),
  FigusAvatar(id: 'avatar_10', label: 'Oriental',     proOnly: true),
  FigusAvatar(id: 'avatar_11', label: 'Dreads',       proOnly: true),
  FigusAvatar(id: 'avatar_12', label: 'Executiva',    proOnly: true),

  // ── pro · accessories (4) ────────────────────────────────────────────────
  FigusAvatar(id: 'avatar_13', label: 'Óculos',       proOnly: true),
  FigusAvatar(id: 'avatar_14', label: 'Sol',          proOnly: true),
  FigusAvatar(id: 'avatar_15', label: 'Hipster',      proOnly: true),
  FigusAvatar(id: 'avatar_16', label: 'Rosa',         proOnly: true),

  // ── pro · festive (6) ────────────────────────────────────────────────────
  FigusAvatar(id: 'avatar_17', label: 'Brasil A',     proOnly: true),
  FigusAvatar(id: 'avatar_18', label: 'Brasil V',     proOnly: true),
  FigusAvatar(id: 'avatar_19', label: 'Halloween',    proOnly: true),
  FigusAvatar(id: 'avatar_20', label: 'Papai Noel',   proOnly: true),
  FigusAvatar(id: 'avatar_21', label: 'São João',     proOnly: true),
  FigusAvatar(id: 'avatar_22', label: 'Carnaval',     proOnly: true),

  // ── pro · extra (3) ──────────────────────────────────────────────────────
  FigusAvatar(id: 'avatar_23', label: 'Vovô',         proOnly: true),
  FigusAvatar(id: 'avatar_24', label: 'Hijab',        proOnly: true),
  FigusAvatar(id: 'avatar_25', label: 'Turbante',     proOnly: true),
];

/// Default avatar id used for new profiles + existing rows after migration.
const kDefaultAvatarId = 'avatar_01';

/// Renders a stored avatar identifier. If it matches an SVG asset (cartoon
/// avatars), renders the SVG; otherwise falls back to rendering it as plain
/// text — covers the emoji avatars from the previous MVP and any legacy data.
class AvatarImage extends StatelessWidget {
  final String id;
  final double size;
  const AvatarImage({super.key, required this.id, this.size = 48});

  @override
  Widget build(BuildContext context) {
    if (id.startsWith('avatar_')) {
      return SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          'assets/avatars/$id.svg',
          width: size,
          height: size,
          // SVG is round on its own (a filled circle as the bg) — no need
          // to clip.
        ),
      );
    }
    // Legacy emoji avatar — render as text.
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          id,
          style: TextStyle(fontSize: size * 0.7),
        ),
      ),
    );
  }
}
