// Generates the 11 cartoon avatar SVGs from Claude Design's preview.html.
// Run from the project root:  dart run tools/gen_avatars.dart
//
// Writes assets/avatars/avatar_01.svg ... avatar_11.svg.
import 'dart:io';

const _ns = 'http://www.w3.org/2000/svg';

String _svg(String body) =>
    '<svg xmlns="$_ns" viewBox="0 0 256 256" shape-rendering="geometricPrecision">$body</svg>';

String _eyes(String dark, {String style = 'open'}) {
  if (style == 'closed') {
    return '<path d="M104 117 q6 -5 12 0" stroke="$dark" stroke-width="3" fill="none" stroke-linecap="round"/>'
        '<path d="M140 117 q6 -5 12 0" stroke="$dark" stroke-width="3" fill="none" stroke-linecap="round"/>';
  }
  return '<ellipse cx="110" cy="118" rx="3.6" ry="5" fill="$dark"/>'
      '<ellipse cx="146" cy="118" rx="3.6" ry="5" fill="$dark"/>';
}

String _brows(String color, {int lift = 0}) {
  final y = 104 - lift;
  return '<path d="M101 $y q9 -4 18 0" stroke="$color" stroke-width="3.2" fill="none" stroke-linecap="round"/>'
      '<path d="M137 $y q9 -4 18 0" stroke="$color" stroke-width="3.2" fill="none" stroke-linecap="round"/>';
}

String _nose(String shadow) =>
    '<path d="M126 128 q-3 8 0 12 q3 2 5 0" stroke="$shadow" stroke-width="2" fill="none" stroke-linecap="round"/>';

String _smile([String color = '#3a1f1a']) =>
    '<path d="M116 144 q12 10 24 0" stroke="$color" stroke-width="2.6" fill="none" stroke-linecap="round"/>';

String _neutralMouth([String color = '#3a1f1a']) =>
    '<path d="M118 144 q10 4 20 0" stroke="$color" stroke-width="2.6" fill="none" stroke-linecap="round"/>';

String _cheeks(String color) =>
    '<circle cx="96" cy="138" r="6" fill="$color" opacity="0.55"/>'
    '<circle cx="160" cy="138" r="6" fill="$color" opacity="0.55"/>';

String _bust(String skin, String shadow, String shirt,
    {double headRx = 50, double headRy = 58}) {
  return '<path d="M40 256 C 40 188 84 168 128 168 C 172 168 216 188 216 256 Z" fill="$shirt"/>'
      '<path d="M104 162 q0 16 24 20 q24 -4 24 -20 Z" fill="$shadow"/>'
      '<ellipse cx="128" cy="118" rx="$headRx" ry="$headRy" fill="$skin"/>'
      '<ellipse cx="86" cy="124" rx="5.5" ry="7" fill="$skin"/>'
      '<ellipse cx="170" cy="124" rx="5.5" ry="7" fill="$skin"/>';
}

// Each avatar returns the inner SVG body string.
final avatars = <String Function()>[
  // 01 — F · branca · ondulado
  () {
    const skin = '#f4c9a8', sh = '#d9a784', shirt = '#3a4f6b';
    return _svg(
      '<circle cx="128" cy="128" r="128" fill="#FF5C5C"/>'
      '<path d="M70 120 q-4 -50 58 -62 q62 12 58 62 q4 50 -8 90 l-30 -10 q-20 -50 -20 -80 q0 30 -20 80 l-30 10 q-12 -40 -8 -90 Z" fill="#5a3a22"/>'
      '${_bust(skin, sh, shirt)}'
      '<path d="M78 102 q6 -38 50 -42 q44 4 50 42 q4 18 -2 26 q-6 -18 -22 -22 q-8 18 -28 18 q-22 0 -32 -10 q-12 4 -16 14 q-4 -10 0 -26 Z" fill="#5a3a22"/>'
      '${_brows("#4a2c18")}'
      '${_eyes("#1f1a16")}'
      '${_nose(sh)}'
      '${_cheeks("#ff8a7a")}'
      '${_smile()}'
      '<circle cx="84" cy="138" r="3" fill="#e8c46a"/>'
      '<circle cx="172" cy="138" r="3" fill="#e8c46a"/>',
    );
  },

  // 02 — M · negro · barba
  () {
    const skin = '#7a4a30', sh = '#5d3924', shirt = '#2a8a5f';
    return _svg(
      '<circle cx="128" cy="128" r="128" fill="#FF9F40"/>'
      '${_bust(skin, sh, shirt)}'
      '<path d="M86 130 q4 36 42 42 q38 -6 42 -42 q-6 22 -42 24 q-36 -2 -42 -24 Z" fill="#1f1612"/>'
      '<path d="M82 96 q-4 -30 16 -38 q6 -8 18 -6 q10 -8 24 -4 q14 -6 24 4 q14 -2 18 8 q18 10 14 36 q-2 8 -8 12 q-4 -10 -14 -12 q-6 -8 -16 -6 q-10 -10 -22 -6 q-12 -6 -22 4 q-12 -2 -18 6 q-8 2 -14 12 q-8 -4 -10 -10 Z" fill="#1f1612"/>'
      '<circle cx="92" cy="84" r="6" fill="#1f1612"/>'
      '<circle cx="108" cy="74" r="6" fill="#1f1612"/>'
      '<circle cx="128" cy="72" r="7" fill="#1f1612"/>'
      '<circle cx="148" cy="74" r="6" fill="#1f1612"/>'
      '<circle cx="164" cy="84" r="6" fill="#1f1612"/>'
      '${_brows("#1f1612")}'
      '${_eyes("#1f1a16")}'
      '${_nose(sh)}'
      '${_smile("#2a1812")}',
    );
  },

  // 03 — F · asiática · franja
  () {
    const skin = '#f2c99b', sh = '#d4a878', shirt = '#b8423a';
    return _svg(
      '<circle cx="128" cy="128" r="128" fill="#FFC542"/>'
      '<path d="M68 130 q-2 -56 60 -68 q62 12 60 68 q2 70 -4 126 l-40 0 q-2 -60 -16 -90 q-14 30 -16 90 l-40 0 q-6 -56 -4 -126 Z" fill="#1a1310"/>'
      '${_bust(skin, sh, shirt)}'
      '<path d="M78 96 q4 -28 50 -32 q46 4 50 32 q-2 18 -10 26 q-8 -16 -22 -18 q-2 14 -18 16 q-16 -2 -18 -16 q-14 2 -22 18 q-8 -8 -10 -26 Z" fill="#1a1310"/>'
      '${_brows("#1a1310")}'
      '${_eyes("#1a1310")}'
      '${_nose(sh)}'
      '${_cheeks("#ff9a85")}'
      '${_smile()}',
    );
  },

  // 04 — M · branco · óculos
  () {
    const skin = '#f4c9a8', sh = '#d9a784', shirt = '#3a4250';
    return _svg(
      '<circle cx="128" cy="128" r="128" fill="#6BCB77"/>'
      '${_bust(skin, sh, shirt)}'
      '<path d="M80 100 q4 -34 48 -38 q44 4 48 38 q-2 14 -10 18 q-8 -14 -22 -16 q-10 -10 -28 -6 q-18 4 -24 14 q-8 0 -12 8 q-2 -8 0 -18 Z" fill="#6b3f24"/>'
      '${_brows("#4a2c18")}'
      '${_eyes("#1f1a16")}'
      '${_nose(sh)}'
      '${_neutralMouth()}'
      '<circle cx="110" cy="118" r="12" fill="none" stroke="#1f1a16" stroke-width="2.5"/>'
      '<circle cx="146" cy="118" r="12" fill="none" stroke="#1f1a16" stroke-width="2.5"/>'
      '<path d="M122 118 h12" stroke="#1f1a16" stroke-width="2.5"/>',
    );
  },

  // 05 — F · parda · headband
  () {
    const skin = '#c68b5e', sh = '#a06a44', shirt = '#e88a3a';
    return _svg(
      '<circle cx="128" cy="128" r="128" fill="#4DD0E1"/>'
      '<path d="M62 124 q-4 -48 66 -64 q70 16 66 64 q4 44 -10 84 l-28 -4 q-18 -40 -28 -76 q-10 36 -28 76 l-28 4 q-14 -40 -10 -84 Z" fill="#3a2418"/>'
      '<circle cx="74" cy="120" r="10" fill="#3a2418"/>'
      '<circle cx="68" cy="98" r="9" fill="#3a2418"/>'
      '<circle cx="80" cy="80" r="9" fill="#3a2418"/>'
      '<circle cx="182" cy="120" r="10" fill="#3a2418"/>'
      '<circle cx="188" cy="98" r="9" fill="#3a2418"/>'
      '<circle cx="176" cy="80" r="9" fill="#3a2418"/>'
      '${_bust(skin, sh, shirt)}'
      '<path d="M82 96 q6 -30 46 -34 q40 4 46 34 q-2 14 -8 20 q-8 -14 -20 -14 q-6 -10 -18 -8 q-14 -2 -20 8 q-12 0 -20 14 q-6 -6 -6 -20 Z" fill="#3a2418"/>'
      '<path d="M76 92 q52 -22 104 0 l0 8 q-52 -18 -104 0 Z" fill="#e88a3a"/>'
      '<circle cx="128" cy="92" r="4" fill="#fff3d4"/>'
      '${_brows("#2a1810")}'
      '${_eyes("#1f1a16")}'
      '${_nose(sh)}'
      '${_cheeks("#d96a4a")}'
      '${_smile()}',
    );
  },

  // 06 — M · indígena · bandana
  () {
    const skin = '#b07a50', sh = '#8a5a36', shirt = '#3a8a5a';
    return _svg(
      '<circle cx="128" cy="128" r="128" fill="#5B8DEF"/>'
      '<path d="M72 124 q-4 -52 56 -64 q60 12 56 64 q6 60 0 132 l-32 0 q-4 -50 -10 -80 q-6 30 -10 80 l-32 0 q-6 -72 0 -132 Z" fill="#181210"/>'
      '${_bust(skin, sh, shirt)}'
      '<path d="M74 92 q54 -16 108 0 l-2 14 q-52 -14 -104 0 Z" fill="#d94a3a"/>'
      '<path d="M74 92 q54 -16 108 0" stroke="#a8311f" stroke-width="2" fill="none"/>'
      '<circle cx="100" cy="92" r="2.6" fill="#fff3d4"/>'
      '<circle cx="128" cy="88" r="2.6" fill="#fff3d4"/>'
      '<circle cx="156" cy="92" r="2.6" fill="#fff3d4"/>'
      '${_brows("#181210")}'
      '${_eyes("#181210")}'
      '${_nose(sh)}'
      '${_smile("#2a1610")}',
    );
  },

  // 07 — F · negra · afro
  () {
    const skin = '#6b4028', sh = '#4d2c1b', shirt = '#e9c14a';
    return _svg(
      '<circle cx="128" cy="128" r="128" fill="#7B7BFF"/>'
      '<circle cx="128" cy="100" r="74" fill="#1a1310"/>'
      '<circle cx="68" cy="92" r="14" fill="#1a1310"/>'
      '<circle cx="80" cy="58" r="14" fill="#1a1310"/>'
      '<circle cx="112" cy="42" r="14" fill="#1a1310"/>'
      '<circle cx="146" cy="42" r="14" fill="#1a1310"/>'
      '<circle cx="178" cy="58" r="14" fill="#1a1310"/>'
      '<circle cx="190" cy="92" r="14" fill="#1a1310"/>'
      '${_bust(skin, sh, shirt)}'
      '<path d="M84 100 q4 -22 44 -26 q40 4 44 26 q-2 12 -8 16 q-8 -14 -20 -14 q-8 -8 -16 -6 q-12 -2 -16 6 q-12 0 -20 14 q-6 -4 -8 -16 Z" fill="#1a1310"/>'
      '${_brows("#1a1310")}'
      '${_eyes("#1f1a16")}'
      '${_nose(sh)}'
      '${_cheeks("#c95642")}'
      '${_smile("#2a1610")}'
      '<circle cx="84" cy="140" r="6" fill="none" stroke="#e9c14a" stroke-width="2.5"/>'
      '<circle cx="172" cy="140" r="6" fill="none" stroke="#e9c14a" stroke-width="2.5"/>',
    );
  },

  // 08 — M · idoso · barba branca
  () {
    const skin = '#e8b894', sh = '#c89072', shirt = '#3a4a6a';
    return _svg(
      '<circle cx="128" cy="128" r="128" fill="#B574E5"/>'
      '${_bust(skin, sh, shirt)}'
      '<path d="M82 124 q4 46 46 56 q42 -10 46 -56 q-8 26 -46 28 q-38 -2 -46 -28 Z" fill="#f1ece4"/>'
      '<path d="M108 138 q10 -4 20 0 q10 -4 20 0 q-4 8 -20 8 q-16 0 -20 -8 Z" fill="#f1ece4"/>'
      '<path d="M80 102 q4 -34 48 -38 q44 4 48 38 q-2 14 -8 18 q-10 -14 -24 -16 q-12 -10 -28 -6 q-14 4 -22 14 q-8 0 -12 8 q-2 -8 -2 -18 Z" fill="#f1ece4"/>'
      '<path d="M92 130 q4 -2 8 0" stroke="$sh" stroke-width="1.5" fill="none" stroke-linecap="round"/>'
      '<path d="M156 130 q4 -2 8 0" stroke="$sh" stroke-width="1.5" fill="none" stroke-linecap="round"/>'
      '${_brows("#d4cec2")}'
      '${_eyes("#1f1a16")}'
      '<path d="M118 148 q10 4 20 0" stroke="#3a1f1a" stroke-width="2.4" fill="none" stroke-linecap="round"/>',
    );
  },

  // 09 — F · criança · maria-chiquinha
  () {
    const skin = '#d09870', sh = '#a87248', shirt = '#7a5fdf';
    return _svg(
      '<circle cx="128" cy="128" r="128" fill="#FF77AB"/>'
      '<ellipse cx="58" cy="138" rx="18" ry="26" fill="#3a2418"/>'
      '<ellipse cx="198" cy="138" rx="18" ry="26" fill="#3a2418"/>'
      '<circle cx="58" cy="116" r="6" fill="#ffd24a"/>'
      '<circle cx="198" cy="116" r="6" fill="#ffd24a"/>'
      '${_bust(skin, sh, shirt, headRx: 48, headRy: 54)}'
      '<path d="M78 102 q4 -34 50 -38 q46 4 50 38 q-2 18 -10 22 q-8 -16 -24 -18 q-2 -2 -16 0 q-14 -2 -16 0 q-16 2 -24 18 q-8 -4 -10 -22 Z" fill="#3a2418"/>'
      '<path d="M88 108 q12 -10 30 -6 q4 8 0 12 q-22 -2 -30 -6 Z" fill="#3a2418"/>'
      '${_brows("#2a1810")}'
      '<ellipse cx="110" cy="120" rx="4.5" ry="6" fill="#1f1a16"/>'
      '<ellipse cx="146" cy="120" rx="4.5" ry="6" fill="#1f1a16"/>'
      '<circle cx="111.5" cy="118" r="1.4" fill="#fff"/>'
      '<circle cx="147.5" cy="118" r="1.4" fill="#fff"/>'
      '${_nose(sh)}'
      '${_cheeks("#e26a4a")}'
      '<path d="M114 144 q14 12 28 0" stroke="#3a1f1a" stroke-width="2.6" fill="none" stroke-linecap="round"/>',
    );
  },

  // 10 — M · asiático · careca
  () {
    const skin = '#f2c99b', sh = '#d4a878', shirt = '#2a6a8a';
    return _svg(
      '<circle cx="128" cy="128" r="128" fill="#8C5E3B"/>'
      '${_bust(skin, sh, shirt)}'
      '<path d="M82 130 q-2 -16 4 -22 q4 18 8 22 Z" fill="#2a1f18"/>'
      '<path d="M174 130 q2 -16 -4 -22 q-4 18 -8 22 Z" fill="#2a1f18"/>'
      '<path d="M88 86 q8 -16 40 -18 q32 2 40 18 q-2 -2 -40 -2 q-38 0 -40 2 Z" fill="$sh" opacity="0.35"/>'
      '${_brows("#1f1a14")}'
      '${_eyes("#1f1a14")}'
      '${_nose(sh)}'
      '${_neutralMouth()}'
      '<rect x="96" y="108" width="28" height="20" rx="4" fill="none" stroke="#1f1a16" stroke-width="2.5"/>'
      '<rect x="132" y="108" width="28" height="20" rx="4" fill="none" stroke="#1f1a16" stroke-width="2.5"/>'
      '<path d="M124 118 h8" stroke="#1f1a16" stroke-width="2.5"/>',
    );
  },

  // 11 — Andrógino · neutro
  () {
    const skin = '#6b4028', sh = '#4d2c1b', shirt = '#1a1a1a';
    return _svg(
      '<circle cx="128" cy="128" r="128" fill="#607D8B"/>'
      '${_bust(skin, sh, shirt)}'
      '<path d="M80 100 q4 -34 48 -38 q44 4 48 38 q-2 8 -6 12 q-12 -10 -42 -10 q-30 0 -42 10 q-4 -4 -6 -12 Z" fill="#1a1310"/>'
      '<circle cx="84" cy="138" r="2.4" fill="#cfc7b8"/>'
      '${_brows("#1a1310")}'
      '${_eyes("#1f1a16")}'
      '${_nose(sh)}'
      '${_neutralMouth("#2a1610")}',
    );
  },
];

void main() {
  final outDir = Directory('assets/avatars');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  for (var i = 0; i < avatars.length; i++) {
    final n = (i + 1).toString().padLeft(2, '0');
    final file = File('${outDir.path}/avatar_$n.svg');
    file.writeAsStringSync(avatars[i]());
    print('wrote ${file.path} (${file.lengthSync()} bytes)');
  }
}
