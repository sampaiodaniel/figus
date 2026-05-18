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

/// 25 cartoon avatars from the Figus v2 pack (curated DiceBear avataaars
/// configurations with named personas). 5 free + 20 Pro split across
/// classics, lifestyles and festive themes. Labels match the pack's
/// config.js so the UI shows the persona name, not a generic descriptor.
const figusAvatars = <FigusAvatar>[
  // ── free (5) — representação básica ──────────────────────────────────────
  FigusAvatar(id: 'avatar_01', label: 'Mariana',      proOnly: false),
  FigusAvatar(id: 'avatar_02', label: 'Amanda',       proOnly: false),
  FigusAvatar(id: 'avatar_03', label: 'Lucas',        proOnly: false),
  FigusAvatar(id: 'avatar_04', label: 'Pedro',        proOnly: false),
  FigusAvatar(id: 'avatar_05', label: 'Sam',          proOnly: false),

  // ── pro · clássicos (8) ──────────────────────────────────────────────────
  FigusAvatar(id: 'avatar_06', label: 'Yuki',         proOnly: true),
  FigusAvatar(id: 'avatar_07', label: 'Isabela',      proOnly: true),
  FigusAvatar(id: 'avatar_08', label: 'Dona Clara',   proOnly: true),
  FigusAvatar(id: 'avatar_09', label: 'Celina',       proOnly: true),
  FigusAvatar(id: 'avatar_10', label: 'Rodrigo',      proOnly: true),
  FigusAvatar(id: 'avatar_11', label: 'Zé',           proOnly: true),
  FigusAvatar(id: 'avatar_12', label: 'Pirí',         proOnly: true),
  FigusAvatar(id: 'avatar_13', label: 'Seu Toninho',  proOnly: true),

  // ── pro · estilos (6) ────────────────────────────────────────────────────
  FigusAvatar(id: 'avatar_14', label: 'Atleta',       proOnly: true),
  FigusAvatar(id: 'avatar_15', label: 'Diretor',      proOnly: true),
  FigusAvatar(id: 'avatar_16', label: 'Kai',          proOnly: true),
  FigusAvatar(id: 'avatar_17', label: 'Punk',         proOnly: true),
  FigusAvatar(id: 'avatar_18', label: 'Flora',        proOnly: true),
  FigusAvatar(id: 'avatar_19', label: 'Gamer',        proOnly: true),

  // ── pro · festivos (6) ───────────────────────────────────────────────────
  FigusAvatar(id: 'avatar_20', label: 'Natal',        proOnly: true),
  FigusAvatar(id: 'avatar_21', label: 'Halloween',    proOnly: true),
  FigusAvatar(id: 'avatar_22', label: 'Carnaval',     proOnly: true),
  FigusAvatar(id: 'avatar_23', label: 'São João',     proOnly: true),
  FigusAvatar(id: 'avatar_24', label: 'Copa Brasil',  proOnly: true),
  FigusAvatar(id: 'avatar_25', label: 'Réveillon',    proOnly: true),
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
      // SVGs in the v3 pack are flattened (we strip the outer wrapper that
      // contained the circular clip-path, because flutter_svg 2.x doesn't
      // support nested <svg> elements). ClipOval reinstates the round look
      // at the widget level.
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: SvgPicture.asset(
            'assets/avatars/$id.svg',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
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
