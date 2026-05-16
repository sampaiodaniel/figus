/// Pure-Dart trade matcher: given two collections (you + a friend), produce
/// a prioritized list of trade suggestions.
///
/// Rules (per user spec):
///  * Foil stickers are worth 2 normals.
///  * Prefer same-type, 1-for-1 (normal↔normal, foil↔foil).
///  * When that's exhausted, mixed trades: 1 foil for 2 normals.
///  * Favorited nations weigh more in the ranking so they bubble up first.
library;

class TradeSticker {
  final String code; // BRA10, FWC9, ...
  final String? nationCode; // BRA, FWC, ...
  final bool isFoil;

  const TradeSticker({
    required this.code,
    required this.nationCode,
    required this.isFoil,
  });
}

class TradeInventory {
  /// Stickers the owner has *extra* (dupes available to give).
  final Map<String, int> dupesByCode;

  /// Stickers the owner is *missing* (would receive in a trade).
  final Set<String> missingCodes;

  /// All known sticker metadata keyed by code.
  final Map<String, TradeSticker> stickersByCode;

  /// Codes whose nation is favorited by the owner.
  final Set<String> favoriteNations;

  const TradeInventory({
    required this.dupesByCode,
    required this.missingCodes,
    required this.stickersByCode,
    required this.favoriteNations,
  });
}

class TradeOffer {
  /// What you give to the friend (codes + quantities).
  final Map<String, int> youGive;

  /// What you receive from the friend.
  final Map<String, int> youReceive;

  /// 'same' = 1-for-1 same type; 'mixed' = foil-for-two-normals.
  final String kind;

  /// Score used to rank suggestions. Higher = better.
  final double score;

  const TradeOffer({
    required this.youGive,
    required this.youReceive,
    required this.kind,
    required this.score,
  });

  int get totalGive => youGive.values.fold(0, (a, b) => a + b);
  int get totalReceive => youReceive.values.fold(0, (a, b) => a + b);
}

class TradeMatcher {
  /// Compute trade suggestions between `me` and `friend`.
  /// Returns a list of [TradeOffer] sorted by descending score.
  static List<TradeOffer> match({
    required TradeInventory me,
    required TradeInventory friend,
  }) {
    // Stickers I can hand over (my dupes that the friend is missing).
    final iCanGive = <String, int>{
      for (final e in me.dupesByCode.entries)
        if (friend.missingCodes.contains(e.key)) e.key: e.value,
    };
    // Stickers I want to receive (friend's dupes I'm missing).
    final iCanGet = <String, int>{
      for (final e in friend.dupesByCode.entries)
        if (me.missingCodes.contains(e.key)) e.key: e.value,
    };

    final giveFoil = <String, int>{};
    final giveNorm = <String, int>{};
    iCanGive.forEach((c, n) {
      final isFoil = me.stickersByCode[c]?.isFoil ?? friend.stickersByCode[c]?.isFoil ?? false;
      (isFoil ? giveFoil : giveNorm)[c] = n;
    });
    final getFoil = <String, int>{};
    final getNorm = <String, int>{};
    iCanGet.forEach((c, n) {
      final isFoil = me.stickersByCode[c]?.isFoil ?? friend.stickersByCode[c]?.isFoil ?? false;
      (isFoil ? getFoil : getNorm)[c] = n;
    });

    final offers = <TradeOffer>[];

    // 1. Same-type 1-for-1 (foil↔foil)
    _pairSameType(giveFoil, getFoil, true, me, friend, offers);
    // 2. Same-type 1-for-1 (normal↔normal)
    _pairSameType(giveNorm, getNorm, false, me, friend, offers);
    // 3. Mixed: I give 1 foil, receive 2 normals.
    _pairMixed(giveFoil, getNorm, giveIsFoil: true, me: me, friend: friend, offers: offers);
    // 4. Mixed: I give 2 normals, receive 1 foil.
    _pairMixed(giveNorm, getFoil, giveIsFoil: false, me: me, friend: friend, offers: offers);

    offers.sort((a, b) => b.score.compareTo(a.score));
    return offers;
  }

  static void _pairSameType(
    Map<String, int> give,
    Map<String, int> get,
    bool isFoil,
    TradeInventory me,
    TradeInventory friend,
    List<TradeOffer> offers,
  ) {
    final giveList = _expand(give);
    final getList = _expand(get);
    final n = giveList.length < getList.length ? giveList.length : getList.length;
    for (var i = 0; i < n; i++) {
      final g = giveList[i];
      final r = getList[i];
      offers.add(TradeOffer(
        youGive: {g: 1},
        youReceive: {r: 1},
        kind: 'same',
        score: _score(give: [g], receive: [r], me: me, friend: friend, kind: 'same'),
      ));
      give[g] = (give[g] ?? 1) - 1;
      get[r] = (get[r] ?? 1) - 1;
    }
    give.removeWhere((_, v) => v <= 0);
    get.removeWhere((_, v) => v <= 0);
  }

  static void _pairMixed(
    Map<String, int> giveSide,
    Map<String, int> getSide, {
    required bool giveIsFoil,
    required TradeInventory me,
    required TradeInventory friend,
    required List<TradeOffer> offers,
  }) {
    final giveList = _expand(giveSide);
    final getList = _expand(getSide);
    if (giveIsFoil) {
      // 1 foil for 2 normals.
      var gi = 0;
      var ri = 0;
      while (gi < giveList.length && ri + 1 < getList.length) {
        final g = giveList[gi];
        final r1 = getList[ri];
        final r2 = getList[ri + 1];
        offers.add(TradeOffer(
          youGive: {g: 1},
          youReceive: _combine([r1, r2]),
          kind: 'mixed',
          score: _score(
            give: [g],
            receive: [r1, r2],
            me: me,
            friend: friend,
            kind: 'mixed',
          ),
        ));
        gi++;
        ri += 2;
      }
    } else {
      // 2 normals for 1 foil.
      var gi = 0;
      var ri = 0;
      while (gi + 1 < giveList.length && ri < getList.length) {
        final g1 = giveList[gi];
        final g2 = giveList[gi + 1];
        final r = getList[ri];
        offers.add(TradeOffer(
          youGive: _combine([g1, g2]),
          youReceive: {r: 1},
          kind: 'mixed',
          score: _score(
            give: [g1, g2],
            receive: [r],
            me: me,
            friend: friend,
            kind: 'mixed',
          ),
        ));
        gi += 2;
        ri++;
      }
    }
  }

  // Expand map to flat list, highest-duplicate codes first.
  // Stickers with more copies are prioritised for 1×1 pairing so the user
  // gets rid of their biggest pile first.
  static List<String> _expand(Map<String, int> m) {
    final entries = m.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final out = <String>[];
    for (final e in entries) {
      for (var i = 0; i < e.value; i++) {
        out.add(e.key);
      }
    }
    return out;
  }

  static Map<String, int> _combine(List<String> codes) {
    final out = <String, int>{};
    for (final c in codes) {
      out[c] = (out[c] ?? 0) + 1;
    }
    return out;
  }

  static double _score({
    required List<String> give,
    required List<String> receive,
    required TradeInventory me,
    required TradeInventory friend,
    required String kind,
  }) {
    // Base: same-type 1-for-1 is the cleanest, score 100.
    // Mixed is less ideal, base 60.
    var score = kind == 'same' ? 100.0 : 60.0;
    // +20 per favorited nation among what *I* receive (I want those most).
    for (final c in receive) {
      final st = friend.stickersByCode[c] ?? me.stickersByCode[c];
      final nation = st?.nationCode;
      if (nation != null && me.favoriteNations.contains(nation)) score += 20;
    }
    // +10 per foil received.
    for (final c in receive) {
      final st = friend.stickersByCode[c] ?? me.stickersByCode[c];
      if (st?.isFoil ?? false) score += 10;
    }
    // Bonus for giving away highly-duplicated stickers (burning big piles is a priority).
    for (final c in give) {
      final myCount = me.dupesByCode[c] ?? 0;
      if (myCount >= 3) {
        score += 15;
      } else if (myCount >= 2) {
        score += 8;
      }
    }
    // -5 per foil I give away (mild penalty so they don't drain to commons).
    for (final c in give) {
      final st = me.stickersByCode[c] ?? friend.stickersByCode[c];
      if (st?.isFoil ?? false) score -= 5;
    }
    return score;
  }
}
