/// Pure-Dart trade matcher: given two collections (you + a friend), produce
/// a prioritized list of trade suggestions.
///
/// Rules (per user spec):
///  * Same-type pairing (normal↔normal, foil↔foil) is preferred.
///  * Mixed trades use a configurable ratio (default: 1 foil = 2 normais,
///    settable per user in `TradeRules`).
///  * Favorited nations weigh more in the ranking so they bubble up first.
library;

import '../../core/country_codes.dart';
import 'trade_rules.dart';

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

  /// Optional display name of whoever this inventory belongs to. Carried
  /// straight through from the QR/paste payload so the comparison screen
  /// can show "Trocas com X" without a second lookup.
  final String? profileName;

  const TradeInventory({
    required this.dupesByCode,
    required this.missingCodes,
    required this.stickersByCode,
    required this.favoriteNations,
    this.profileName,
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
  /// [rules] lets the user tweak ratios and selection strategy via the
  /// Ajustes → Trocas page (default is 1×1 same-type + 1 foil ↔ 2 normais).
  static List<TradeOffer> match({
    required TradeInventory me,
    required TradeInventory friend,
    TradeRules rules = const TradeRules(),
  }) {
    // Stickers I can hand over (my dupes that the friend is missing). We
    // cap to 1 per code because the friend only needs ONE copy — handing
    // over 3 ESP20 to fill a single missing slot doesn't make sense
    // (Daniel: "A pessoa vai trocar uma dela por uma repetida? Não
    // existe isso"). Any extra dupes I have can go to OTHER friends in
    // separate sessions.
    final iCanGive = <String, int>{
      for (final e in me.dupesByCode.entries)
        if (friend.missingCodes.contains(e.key)) e.key: 1,
    };
    // Stickers I want to receive (friend's dupes I'm missing). Same
    // rule: I only need 1 of each missing sticker.
    final iCanGet = <String, int>{
      for (final e in friend.dupesByCode.entries)
        if (me.missingCodes.contains(e.key)) e.key: 1,
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

    // Foil ↔ foil same-type always runs first — never a downside.
    _pairSameType(
      giveFoil,
      getFoil,
      giveCount: rules.foilGive,
      receiveCount: rules.foilReceive,
      isFoil: true,
      me: me,
      friend: friend,
      offers: offers,
      strategy: rules.giveStrategy,
    );

    // If the user wants to prioritize sending/receiving foils, run those
    // mixed pairings BEFORE consuming normais via normal-normal same-type.
    // Otherwise, normal-normal goes first (default).
    void doMixedSend() => _pairMixed(
          giveFoil,
          getNorm,
          giveCount: 1,
          receiveCount: rules.foilToNormalRatio,
          me: me,
          friend: friend,
          offers: offers,
          strategy: rules.giveStrategy,
          rules: rules,
        );
    void doMixedReceive() => _pairMixed(
          giveNorm,
          getFoil,
          giveCount: rules.foilToNormalRatio,
          receiveCount: 1,
          me: me,
          friend: friend,
          offers: offers,
          strategy: rules.giveStrategy,
          rules: rules,
        );

    if (rules.prioritizeSendFoils) doMixedSend();
    if (rules.prioritizeReceiveFoils) doMixedReceive();

    _pairSameType(
      giveNorm,
      getNorm,
      giveCount: rules.normalGive,
      receiveCount: rules.normalReceive,
      isFoil: false,
      me: me,
      friend: friend,
      offers: offers,
      strategy: rules.giveStrategy,
    );

    if (!rules.prioritizeSendFoils) doMixedSend();
    if (!rules.prioritizeReceiveFoils) doMixedReceive();

    offers.sort((a, b) => b.score.compareTo(a.score));
    return offers;
  }

  static void _pairSameType(
    Map<String, int> give,
    Map<String, int> get, {
    required int giveCount,
    required int receiveCount,
    required bool isFoil,
    required TradeInventory me,
    required TradeInventory friend,
    required List<TradeOffer> offers,
    required GiveStrategy strategy,
  }) {
    final giveList = _expand(give, strategy, me);
    final getList = _expand(get, strategy, friend);
    // We can only build whole offers: each one needs `giveCount` items on
    // the give side and `receiveCount` on the receive side. Stop when
    // either side runs short.
    var gi = 0;
    var ri = 0;
    while (gi + giveCount <= giveList.length &&
        ri + receiveCount <= getList.length) {
      final giveChunk = giveList.sublist(gi, gi + giveCount);
      final getChunk = getList.sublist(ri, ri + receiveCount);
      offers.add(TradeOffer(
        youGive: _combine(giveChunk),
        youReceive: _combine(getChunk),
        kind: 'same',
        score: _score(
            give: giveChunk,
            receive: getChunk,
            me: me,
            friend: friend,
            kind: 'same'),
      ));
      for (final c in giveChunk) {
        give[c] = (give[c] ?? 1) - 1;
      }
      for (final c in getChunk) {
        get[c] = (get[c] ?? 1) - 1;
      }
      gi += giveCount;
      ri += receiveCount;
    }
    give.removeWhere((_, v) => v <= 0);
    get.removeWhere((_, v) => v <= 0);
  }

  static void _pairMixed(
    Map<String, int> giveSide,
    Map<String, int> getSide, {
    required int giveCount,
    required int receiveCount,
    required TradeInventory me,
    required TradeInventory friend,
    required List<TradeOffer> offers,
    required GiveStrategy strategy,
    required TradeRules rules,
  }) {
    final giveList = _expand(giveSide, strategy, me);
    final getList = _expand(getSide, strategy, friend);
    if (giveCount == 1) {
      // 1 foil for N normals (where N = receiveCount, default 2, settable
      // up to whatever the user chose in the rules).
      var gi = 0;
      var ri = 0;
      while (gi < giveList.length && ri + receiveCount <= getList.length) {
        final g = giveList[gi];
        final receivedChunk = getList.sublist(ri, ri + receiveCount);
        offers.add(TradeOffer(
          youGive: {g: 1},
          youReceive: _combine(receivedChunk),
          kind: 'mixed',
          score: _score(
            give: [g],
            receive: receivedChunk,
            me: me,
            friend: friend,
            kind: 'mixed',
            rules: rules,
          ),
        ));
        gi++;
        ri += receiveCount;
      }
    } else {
      // N normals for 1 foil (giveCount = N, receiveCount = 1).
      var gi = 0;
      var ri = 0;
      while (gi + giveCount <= giveList.length && ri < getList.length) {
        final giveChunk = giveList.sublist(gi, gi + giveCount);
        final r = getList[ri];
        offers.add(TradeOffer(
          youGive: _combine(giveChunk),
          youReceive: {r: 1},
          kind: 'mixed',
          score: _score(
            give: giveChunk,
            receive: [r],
            me: me,
            friend: friend,
            kind: 'mixed',
            rules: rules,
          ),
        ));
        gi += giveCount;
        ri++;
      }
    }
  }

  /// Flattens a (code → count) map to a list, ordered per the user's
  /// [strategy]:
  ///   * random — shuffled (good for "spread the love" feel).
  ///   * alphabetical — natural-sort by code (BRA1 before BRA10).
  ///   * randomKeepFavorites — shuffled, but codes from the owner's
  ///     favorite nations sink to the end (we'd rather not give those
  ///     away first).
  static List<String> _expand(
    Map<String, int> m,
    GiveStrategy strategy,
    TradeInventory owner,
  ) {
    final entries = m.entries.toList();
    switch (strategy) {
      case GiveStrategy.random:
        entries.shuffle();
      case GiveStrategy.alphabetical:
        entries.sort((a, b) => _naturalCompare(a.key, b.key));
      case GiveStrategy.randomKeepFavorites:
        entries.shuffle();
        // Stable partition: non-favorites first, favorites last.
        entries.sort((a, b) {
          final aFav = _isFavorite(a.key, owner);
          final bFav = _isFavorite(b.key, owner);
          if (aFav == bFav) return 0;
          return aFav ? 1 : -1;
        });
    }
    final out = <String>[];
    for (final e in entries) {
      for (var i = 0; i < e.value; i++) {
        out.add(e.key);
      }
    }
    return out;
  }

  static bool _isFavorite(String code, TradeInventory owner) {
    final nation = owner.stickersByCode[code]?.nationCode;
    if (nation == null) return false;
    return owner.favoriteNations.contains(nation);
  }

  /// Compare two sticker codes by the Portuguese NAME of their nation
  /// (Alemanha < Brasil < Coreia do Sul), then by sticker number within
  /// the nation (BRA1 < BRA2 < BRA10).
  ///
  /// Falls back to plain code comparison for stickers without a nation
  /// (FWC, LGD, CC, etc.) so they still order deterministically.
  static int _naturalCompare(String a, String b) {
    final ra = RegExp(r'^([A-Za-z]+)(\d*)$').firstMatch(a);
    final rb = RegExp(r'^([A-Za-z]+)(\d*)$').firstMatch(b);
    if (ra == null || rb == null) return a.compareTo(b);
    final codeA = ra.group(1)!;
    final codeB = rb.group(1)!;
    // Prefer the human-readable nation name when available, so a user
    // who picked "alphabetical" actually sees Alemanha < Brasil instead
    // of GER < BRA (G < B in raw code order). Daniel: "Por ordem
    // alfabética de seleções, não de nomes de jogadores".
    final nameA = nationNamePtByCode[codeA] ?? codeA;
    final nameB = nationNamePtByCode[codeB] ?? codeB;
    final nameCmp = _stripDiacritics(nameA)
        .toLowerCase()
        .compareTo(_stripDiacritics(nameB).toLowerCase());
    if (nameCmp != 0) return nameCmp;
    final na = int.tryParse(ra.group(2) ?? '') ?? 0;
    final nb = int.tryParse(rb.group(2) ?? '') ?? 0;
    return na.compareTo(nb);
  }

  /// Quick & dirty diacritic strip so "Áustria" sorts next to "Austrália"
  /// instead of being thrown to the end of the alphabet.
  static String _stripDiacritics(String s) {
    const accents = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
    const plain = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      final idx = accents.indexOf(ch);
      buf.write(idx >= 0 ? plain[idx] : ch);
    }
    return buf.toString();
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
    TradeRules rules = const TradeRules(),
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
    // Big bumps when the user explicitly asked to prioritize foils on
    // either side — these flags exist precisely to override the default
    // "1×1 first, mixed last" ordering for chasers and pile-burners.
    if (rules.prioritizeReceiveFoils) {
      for (final c in receive) {
        final st = friend.stickersByCode[c] ?? me.stickersByCode[c];
        if (st?.isFoil ?? false) score += 100;
      }
    }
    if (rules.prioritizeSendFoils) {
      for (final c in give) {
        final st = me.stickersByCode[c] ?? friend.stickersByCode[c];
        if (st?.isFoil ?? false) score += 100;
      }
    }
    return score;
  }
}
