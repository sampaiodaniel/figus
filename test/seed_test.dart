import 'package:figus/data/seeds/wc2026_seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // O seed cresceu desde a v1 (CC1-14 e LGD64 entraram nas migrations v5/v6).
  // O total atual é 1058 = 1 logo + 8 intro + 11 legends + 14 CC + 64 LGD
  // + 48×20 nations.
  test('seeds 1058 stickers total', () {
    expect(WC2026Seed.stickers.length, 1058);
  });

  test('seeds 48 nations', () {
    expect(WC2026Seed.nations.length, 48);
  });

  test('every nation has 20 stickers', () {
    for (final n in WC2026Seed.nations) {
      final count = WC2026Seed.stickers.where((s) => s.nationCode == n.code).length;
      expect(count, 20, reason: '${n.code} should have 20 stickers');
    }
  });

  test('specials: logo + intro + legends + CC + LGD all present', () {
    final specials = WC2026Seed.stickers.where((s) => s.nationCode == null).toList();
    expect(specials.where((s) => s.type == 'logo').length, 1);
    expect(specials.where((s) => s.type == 'intro').length, 8);
    expect(specials.where((s) => s.type == 'legend').length, 11);
    // CC + LGD use type=player with specific labels; just confirm the
    // numeric ranges exist.
    final ccCount =
        WC2026Seed.stickers.where((s) => s.number.startsWith('CC')).length;
    final lgdCount =
        WC2026Seed.stickers.where((s) => s.number.startsWith('LGD')).length;
    expect(ccCount, 14, reason: 'CC1-CC14 should be 14 stickers');
    expect(lgdCount, 64,
        reason: 'LGD01-LGD64 (16 players × 4 rarities) should be 64');
  });

  test('foil count matches Panini official: 68 metallized', () {
    final foils = WC2026Seed.stickers.where((s) => s.isFoil).toList();
    // 48 escudos (sticker #1 de cada nation) + FWC00 (Logo Panini) +
    // FWC1-FWC8 (intros) + FWC9-FWC19 (legends) = 48 + 1 + 8 + 11 = 68.
    expect(foils.length, 68);
  });

  test('all sticker numbers are unique', () {
    final numbers = WC2026Seed.stickers.map((s) => s.number).toList();
    expect(numbers.toSet().length, numbers.length);
  });
}
