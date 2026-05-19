import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How my dupes get prioritized when picking which sticker to give in a
/// pair. The friend's missing list is fixed; this only controls the order
/// in which my candidate dupes are tried.
enum GiveStrategy {
  /// Pick at random — default. Mirrors real-life "shuffle the pile".
  random,

  /// Lowest number first (BRA1 before BRA10). Predictable, easy to grok
  /// when checking the printed album.
  alphabetical,

  /// Same as random, but stickers from nations marked as favorite go to
  /// the back of the line — Daniel: "se eu colo as do meu time, deixo
  /// elas comigo até ter mais opções".
  randomKeepFavorites,
}

/// User-tunable trade ratios. Daniel: "no prédio do meu amigo 1 brilhante
/// vale 3 normais, em outro lugar pode ser 1×2 — preciso conseguir
/// configurar pra fazer trocas em qq lugar".
class TradeRules {
  /// Same-type normal pairing: N normais por M normais.
  /// Default 1×1 — a troca de figurinhas comuns mais natural.
  final int normalGive;
  final int normalReceive;

  /// Same-type foil pairing: N brilhantes por M brilhantes.
  /// Default 1×1.
  final int foilGive;
  final int foilReceive;

  /// Mixed: 1 brilhante vale N normais (ambas direções).
  /// Default 2. Pode virar 3, 4, etc. conforme o "preço" do mercado local.
  final int foilToNormalRatio;

  /// Selection strategy for picking which of my dupes to offer.
  final GiveStrategy giveStrategy;

  /// When true, mixed trades that send my foils run BEFORE same-type
  /// normal-normal pairing — useful when the user wants to clear out
  /// foil dupes even at a cost.
  final bool prioritizeSendFoils;

  /// When true, mixed trades that pull the friend's foils run BEFORE
  /// same-type normal-normal pairing — useful when the user is
  /// chasing missing foils.
  final bool prioritizeReceiveFoils;

  const TradeRules({
    this.normalGive = 1,
    this.normalReceive = 1,
    this.foilGive = 1,
    this.foilReceive = 1,
    this.foilToNormalRatio = 2,
    this.giveStrategy = GiveStrategy.random,
    this.prioritizeSendFoils = false,
    this.prioritizeReceiveFoils = false,
  });

  TradeRules copyWith({
    int? normalGive,
    int? normalReceive,
    int? foilGive,
    int? foilReceive,
    int? foilToNormalRatio,
    GiveStrategy? giveStrategy,
    bool? prioritizeSendFoils,
    bool? prioritizeReceiveFoils,
  }) =>
      TradeRules(
        normalGive: normalGive ?? this.normalGive,
        normalReceive: normalReceive ?? this.normalReceive,
        foilGive: foilGive ?? this.foilGive,
        foilReceive: foilReceive ?? this.foilReceive,
        foilToNormalRatio: foilToNormalRatio ?? this.foilToNormalRatio,
        giveStrategy: giveStrategy ?? this.giveStrategy,
        prioritizeSendFoils: prioritizeSendFoils ?? this.prioritizeSendFoils,
        prioritizeReceiveFoils:
            prioritizeReceiveFoils ?? this.prioritizeReceiveFoils,
      );
}

class TradeRulesNotifier extends StateNotifier<TradeRules> {
  TradeRulesNotifier() : super(const TradeRules()) {
    _load();
  }

  static const _keyNormalGive = 'trade.normal_give';
  static const _keyNormalRecv = 'trade.normal_receive';
  static const _keyFoilGive = 'trade.foil_give';
  static const _keyFoilRecv = 'trade.foil_receive';
  static const _keyFoilNormal = 'trade.foil_normal_ratio';
  static const _keyStrategy = 'trade.give_strategy';
  static const _keyPrioSend = 'trade.prio_send_foils';
  static const _keyPrioRecv = 'trade.prio_recv_foils';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = TradeRules(
      normalGive: p.getInt(_keyNormalGive) ?? 1,
      normalReceive: p.getInt(_keyNormalRecv) ?? 1,
      foilGive: p.getInt(_keyFoilGive) ?? 1,
      foilReceive: p.getInt(_keyFoilRecv) ?? 1,
      foilToNormalRatio: p.getInt(_keyFoilNormal) ?? 2,
      giveStrategy: _strategyFromString(p.getString(_keyStrategy)),
      prioritizeSendFoils: p.getBool(_keyPrioSend) ?? false,
      prioritizeReceiveFoils: p.getBool(_keyPrioRecv) ?? false,
    );
  }

  Future<void> update(TradeRules rules) async {
    state = rules;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyNormalGive, rules.normalGive);
    await p.setInt(_keyNormalRecv, rules.normalReceive);
    await p.setInt(_keyFoilGive, rules.foilGive);
    await p.setInt(_keyFoilRecv, rules.foilReceive);
    await p.setInt(_keyFoilNormal, rules.foilToNormalRatio);
    await p.setString(_keyStrategy, rules.giveStrategy.name);
    await p.setBool(_keyPrioSend, rules.prioritizeSendFoils);
    await p.setBool(_keyPrioRecv, rules.prioritizeReceiveFoils);
  }

  Future<void> reset() => update(const TradeRules());
}

GiveStrategy _strategyFromString(String? s) {
  switch (s) {
    case 'alphabetical':
      return GiveStrategy.alphabetical;
    case 'randomKeepFavorites':
      return GiveStrategy.randomKeepFavorites;
    default:
      return GiveStrategy.random;
  }
}

final tradeRulesProvider =
    StateNotifierProvider<TradeRulesNotifier, TradeRules>(
        (_) => TradeRulesNotifier());
