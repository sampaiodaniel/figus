import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/country_codes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/figus_colors.dart';
import '../../data/providers.dart';
import '../import/figuritas_parser.dart';
import 'inventory_codec.dart';
import 'trade_matcher.dart';
import 'trade_rules.dart';

/// "Comparar com amigo" — accepts the friend's inventory (pasted JSON for
/// now; Bluetooth/QR plug in later) and shows the suggested trades.
class CompareFriendPage extends ConsumerStatefulWidget {
  /// Optional pre-loaded friend inventory (already decoded into a
  /// [TradeInventory]) passed in when the user arrives from a QR scan.
  /// When present, the match runs immediately on first frame so the trade
  /// suggestions show up without an extra tap.
  final TradeInventory? initialFriend;
  const CompareFriendPage({super.key, this.initialFriend});
  @override
  ConsumerState<CompareFriendPage> createState() => _CompareFriendPageState();
}

class _CompareFriendPageState extends ConsumerState<CompareFriendPage> {
  List<TradeOffer>? _offers;
  String? _friendName;
  String? _error;
  bool _busy = false;
  // Trades the user has already confirmed (by index in [_offers]). Marked
  // ones render as "✓ Trocada" and stay around for context, but no longer
  // offer the confirm button.
  final Set<int> _confirmedIdx = {};
  // Other offers that share a sticker with a confirmed one — they'd let
  // the user double-give or double-receive the same card, so we grey them
  // out as soon as a conflicting trade is marked done.
  final Set<int> _invalidatedIdx = {};
  // Cached inventories. Kept around so the per-offer "swap this card"
  // sheet can show what alternatives exist (friend's other dupes I'm
  // missing, or my other dupes the friend is missing) without re-running
  // the matcher.
  TradeInventory? _me;
  TradeInventory? _friend;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFriend;
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyFriend(initial));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparar com amigo'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Compartilhar',
            onSelected: (key) {
              if (key == 'trades') {
                _shareSuggestedTrades();
              } else if (key == 'inventory') {
                _shareMyInventory();
              }
            },
            itemBuilder: (ctx) => [
              if (_offers != null && _offers!.isNotEmpty)
                const PopupMenuItem<String>(
                  value: 'trades',
                  child: Row(
                    children: [
                      Icon(Icons.handshake_rounded, size: 18),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Mandar trocas pro amigo (texto)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'inventory',
                child: Row(
                  children: [
                    Icon(Icons.data_object_rounded, size: 18),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Meu inventário (JSON)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Hero(),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.content_paste_rounded),
              label: const Text('Colar inventário do amigo'),
              onPressed: _busy ? null : _pasteInventory,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (_friendName != null) ...[
              const SizedBox(height: 14),
              Text('Trocas com ${_friendName!}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                _offers!.isEmpty
                    ? 'Nenhuma troca direta disponível agora.'
                    : '${_offers!.length} troca(s) sugerida(s)',
                style: TextStyle(color: context.fc.textMuted),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _offers!.length; i++)
                _OfferCard(
                  offer: _offers![i],
                  confirmed: _confirmedIdx.contains(i),
                  invalidated: _invalidatedIdx.contains(i),
                  onConfirm: (_confirmedIdx.contains(i) ||
                          _invalidatedIdx.contains(i))
                      ? null
                      : () => _confirmOffer(i),
                  onSwapReceive: (_confirmedIdx.contains(i) ||
                          _invalidatedIdx.contains(i))
                      ? null
                      : (code) => _swapReceive(i, code),
                  onSwapGive: (_confirmedIdx.contains(i) ||
                          _invalidatedIdx.contains(i))
                      ? null
                      : (code) => _swapGive(i, code),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmOffer(int index) async {
    final offer = _offers![index];
    final messenger = ScaffoldMessenger.of(context);
    // Quick "tem certeza?" — one mis-tap on a long trade list shouldn't
    // mutate the user's whole collection.
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirmar troca'),
        content: Text(
          'Você está confirmando que a troca foi feita.\n\n'
          'Vamos atualizar sua coleção:\n'
          '· Remover ${_describeMap(offer.youGive)} das suas repetidas\n'
          '· Adicionar ${_describeMap(offer.youReceive)} à sua coleção',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final repo = ref.read(collectionRepoProvider);
    final result = await repo.applyTrade(
      youGive: offer.youGive,
      youReceive: offer.youReceive,
    );
    // Bump the version counter so album/stats screens refresh once the
    // user navigates back.
    ref.read(collectionVersionProvider.notifier).state++;
    if (!mounted) return;
    // Invalidate any other suggestion that shares a sticker (give OR
    // receive). After this trade is done, the matcher's siblings would
    // tell the user to give the same dupe twice or receive the same
    // missing twice — which Daniel rightly called out as a bug.
    final giveSet = offer.youGive.keys.toSet();
    final receiveSet = offer.youReceive.keys.toSet();
    for (var i = 0; i < _offers!.length; i++) {
      if (i == index ||
          _confirmedIdx.contains(i) ||
          _invalidatedIdx.contains(i)) continue;
      final other = _offers![i];
      final shares = other.youGive.keys.any(giveSet.contains) ||
          other.youReceive.keys.any(receiveSet.contains);
      if (shares) _invalidatedIdx.add(i);
    }
    setState(() => _confirmedIdx.add(index));
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(
          'Troca registrada · '
          '${result.gaveOk} entregue(s), ${result.receivedOk} recebida(s)',
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF22C58A),
      ));
  }

  String _describeMap(Map<String, int> m) {
    if (m.isEmpty) return 'nada';
    final parts = m.entries.map((e) => e.value > 1 ? '${e.key} ×${e.value}' : e.key);
    return parts.join(', ');
  }

  Future<void> _shareMyInventory() async {
    final db = ref.read(databaseProvider);
    final exported = await InventoryCodec.exportMine(db);
    final json = InventoryCodec.encodeJson(exported);
    await Share.share(json, subject: 'Meu inventário Figus');
  }

  /// Exports the current suggestion list as a WhatsApp-friendly text. Two
  /// sections:
  ///   1. "Você troca / Eu troco por" — straight 1×1 same-type trades,
  ///      same length on both sides because each line pairs by position.
  ///   2. "Trocas 2 por 1" — mixed offers, shown one per line because
  ///      the give/receive sides have different lengths.
  Future<void> _shareSuggestedTrades() async {
    final offers = _offers;
    if (offers == null || offers.isEmpty) return;
    final actionable = <int>[
      for (var i = 0; i < offers.length; i++)
        if (!_confirmedIdx.contains(i) && !_invalidatedIdx.contains(i)) i,
    ];
    if (actionable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nada pra compartilhar — todas as trocas já foram marcadas.'),
        ),
      );
      return;
    }

    final sameOffers = <TradeOffer>[];
    final mixedOffers = <TradeOffer>[];
    for (final i in actionable) {
      final o = offers[i];
      (o.kind == 'mixed' ? mixedOffers : sameOffers).add(o);
    }

    // URL first so WhatsApp/Telegram pick up the og:image preview card
    // (Figus logo + title + description from web/index.html). Putting it
    // at the top maximizes the chance the chat client renders the card
    // above the text instead of inline. The text below is still sent in
    // the same payload — modern WhatsApp shows BOTH preview and body.
    const figusUrl = 'https://sampaiodaniel.github.io/figus/';
    final lines = <String>[
      figusUrl,
      '',
      '🤝 Trocas sugeridas — Figus',
      '',
      'Comparei nossas figurinhas e as possíveis trocas são:',
    ];

    if (sameOffers.isNotEmpty) {
      // Each list is sorted by nation name then numerically so the
      // recipient can flip through the album page-by-page picking out
      // what to bring. The 1×1 pairing-by-position is lost (offers are
      // independent anyway), but findability wins — Daniel: "assim o
      // usuário consegue separar mais facilmente as que precisa pegar".
      final youTrocas = sameOffers.map((o) => o.youReceive.keys.first).toList()
        ..sort(_compareByNationThenNumber);
      final euTrocoPor = sameOffers.map((o) => o.youGive.keys.first).toList()
        ..sort(_compareByNationThenNumber);
      lines
        ..add('')
        ..add('Você troca:')
        ..addAll(youTrocas)
        ..add('')
        ..add('Eu troco por:')
        ..addAll(euTrocoPor);
    }

    if (mixedOffers.isNotEmpty) {
      lines
        ..add('')
        ..add('Trocas brilhante × 2 normais:');
      for (final o in mixedOffers) {
        final give = o.youGive.keys.join(' + ');
        final receive = o.youReceive.keys.join(' + ');
        lines.add('• Você troca $receive  →  eu troco $give');
      }
    }

    lines
      ..add('')
      ..add('O que acha?');

    await Share.share(lines.join('\n'));
  }

  /// "Trocar essa figurinha" — user said their friend already has this
  /// sticker (so the trade wouldn't work for that line). Show all OTHER
  /// dupes the friend has that I'm missing, skip the codes already in
  /// any actionable offer, and let the user pick.
  Future<void> _swapReceive(int offerIndex, String oldCode) async {
    final friend = _friend;
    final me = _me;
    if (friend == null || me == null) return;
    final alreadyUsed = <String>{};
    for (var i = 0; i < _offers!.length; i++) {
      if (_confirmedIdx.contains(i)) continue;
      alreadyUsed.addAll(_offers![i].youReceive.keys);
    }
    final alternatives = friend.dupesByCode.keys
        .where((c) =>
            me.missingCodes.contains(c) &&
            !alreadyUsed.contains(c))
        .toList()
      ..sort(_compareByNationThenNumber);
    final picked = await _showSwapSheet(
      title: 'Trocar $oldCode',
      subtitle: 'Outra figurinha do amigo que você está caçando:',
      options: alternatives,
    );
    if (picked == null) return;
    _applySwapReceive(offerIndex, oldCode, picked);
  }

  /// Same idea on the give side — when the user wants to offer a
  /// different card from their own dupes (e.g. friend doesn't need that
  /// specific one anymore).
  Future<void> _swapGive(int offerIndex, String oldCode) async {
    final friend = _friend;
    final me = _me;
    if (friend == null || me == null) return;
    final alreadyUsed = <String>{};
    for (var i = 0; i < _offers!.length; i++) {
      if (_confirmedIdx.contains(i)) continue;
      alreadyUsed.addAll(_offers![i].youGive.keys);
    }
    final alternatives = me.dupesByCode.keys
        .where((c) =>
            friend.missingCodes.contains(c) &&
            !alreadyUsed.contains(c))
        .toList()
      ..sort(_compareByNationThenNumber);
    final picked = await _showSwapSheet(
      title: 'Trocar $oldCode',
      subtitle: 'Outra repetida sua que o amigo está caçando:',
      options: alternatives,
    );
    if (picked == null) return;
    _applySwapGive(offerIndex, oldCode, picked);
  }

  Future<String?> _showSwapSheet({
    required String title,
    required String subtitle,
    required List<String> options,
  }) async {
    if (!mounted) return null;
    final c = context.fc;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: c.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        if (options.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                Text(
                  'Não tem outra figurinha possível pra trocar agora.',
                  style: TextStyle(color: c.textMuted, height: 1.4),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: const Text('Ok'),
                ),
              ],
            ),
          );
        }
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetCtx).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    subtitle,
                    style: TextStyle(color: c.textMuted, fontSize: 13),
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: c.border),
                    itemBuilder: (_, i) {
                      final code = options[i];
                      return ListTile(
                        title: Text(code,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        trailing: const Icon(Icons.swap_horiz_rounded),
                        onTap: () => Navigator.pop(sheetCtx, code),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _applySwapReceive(int offerIndex, String oldCode, String newCode) {
    final offer = _offers![offerIndex];
    if (!offer.youReceive.containsKey(oldCode)) return;
    final newReceive = Map<String, int>.from(offer.youReceive)
      ..remove(oldCode);
    newReceive[newCode] = 1;
    setState(() {
      _offers![offerIndex] = TradeOffer(
        youGive: offer.youGive,
        youReceive: newReceive,
        kind: offer.kind,
        score: offer.score,
      );
    });
  }

  void _applySwapGive(int offerIndex, String oldCode, String newCode) {
    final offer = _offers![offerIndex];
    if (!offer.youGive.containsKey(oldCode)) return;
    final newGive = Map<String, int>.from(offer.youGive)..remove(oldCode);
    newGive[newCode] = 1;
    setState(() {
      _offers![offerIndex] = TradeOffer(
        youGive: newGive,
        youReceive: offer.youReceive,
        kind: offer.kind,
        score: offer.score,
      );
    });
  }

  /// Sticker order on the shared text: group by nation (alphabetical PT
  /// name) then sort numerically within each nation. So the recipient
  /// reads BIH6 → BIH10 → BIH15 → CPV10 → JOR15 etc. — easy to find on
  /// the printed album because all of one country sits together.
  static int _compareByNationThenNumber(String a, String b) {
    final ra = RegExp(r'^([A-Za-z]+)(\d*)$').firstMatch(a);
    final rb = RegExp(r'^([A-Za-z]+)(\d*)$').firstMatch(b);
    if (ra == null || rb == null) return a.compareTo(b);
    final codeA = ra.group(1)!;
    final codeB = rb.group(1)!;
    final nameA = (nationNamePtByCode[codeA] ?? codeA).toLowerCase();
    final nameB = (nationNamePtByCode[codeB] ?? codeB).toLowerCase();
    final nameCmp = _stripAccents(nameA).compareTo(_stripAccents(nameB));
    if (nameCmp != 0) return nameCmp;
    final na = int.tryParse(ra.group(2) ?? '') ?? 0;
    final nb = int.tryParse(rb.group(2) ?? '') ?? 0;
    return na.compareTo(nb);
  }

  static String _stripAccents(String s) {
    const accents = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const plain = 'aaaaaeeeeiiiiooooouuuuc';
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      final idx = accents.indexOf(ch);
      buf.write(idx >= 0 ? plain[idx] : ch);
    }
    return buf.toString();
  }

  Future<void> _pasteInventory() async {
    final ctrl = TextEditingController();
    final c = context.fc;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bsCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 12, 20,
          MediaQuery.of(bsCtx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Inventário do amigo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Cole o JSON exportado pelo Figus ou a lista de texto '
              'do app Figuritas — os dois formatos funcionam.',
              style: TextStyle(fontSize: 13, color: c.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              minLines: 5,
              maxLines: 10,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              decoration: InputDecoration(
                filled: true,
                fillColor: c.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.border),
                ),
                hintText: 'Cole aqui o JSON do Figus ou a lista do Figuritas',
                hintStyle: TextStyle(color: c.textMuted),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(bsCtx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(bsCtx, ctrl.text.trim()),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Comparar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (result == null || result.isEmpty) return;
    await _applyFriendJson(result);
  }

  Future<void> _applyFriendJson(String raw) async {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      setState(() => _error = 'Cole o inventário ou exportação do amigo.');
      return;
    }

    // Strategy 1 — Figus's own JSON. Detect by leading '{' to avoid trying
    // to parse a Figuritas text dump as JSON (which used to fail with
    // "SyntaxError: Unexpected identifier Figurinhas").
    if (trimmed.startsWith('{')) {
      try {
        final friend = InventoryCodec.decodeAsFriend(trimmed);
        final inventoryWithName = TradeInventory(
          dupesByCode: friend.dupesByCode,
          missingCodes: friend.missingCodes,
          stickersByCode: friend.stickersByCode,
          favoriteNations: friend.favoriteNations,
          profileName: InventoryCodec.profileNameOf(trimmed),
        );
        await _applyFriend(inventoryWithName);
        return;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = 'Não consegui ler o JSON: $e';
        });
        return;
      }
    }

    // Strategy 2 — Figuritas plain-text export. The user can paste the
    // share-as-text output from the Figuritas app directly and we treat
    // their "Repetidas" as the friend's dupes pool.
    if (isFiguritasFormat(trimmed)) {
      try {
        await _applyFiguritasExport(trimmed);
        return;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = 'Não consegui ler o formato Figuritas: $e';
        });
        return;
      }
    }

    setState(() {
      _busy = false;
      _error = 'Formato não reconhecido. Cole o JSON do Figus '
          '(começando com "{") ou a exportação de texto do Figuritas.';
    });
  }

  /// Converts a Figuritas plain-text export into a [TradeInventory] using
  /// the local seed for sticker metadata (foil flag, nation code). The
  /// friend's "missingCodes" is inferred as "everything in the local seed
  /// that isn't in their dupes" — Figuritas doesn't ship that list
  /// explicitly when the user shares only "Repetidas".
  Future<void> _applyFiguritasExport(String text) async {
    final (faltantes, repetidas) = parseFiguritasExport(text);
    final db = ref.read(databaseProvider);
    final localStickers = await db.select(db.stickers).get();
    final localNations = await db.select(db.nations).get();
    final nationCodeById = {for (final n in localNations) n.id: n.code};

    final stickers = <String, TradeSticker>{};
    final allCodes = <String>{};
    for (final s in localStickers) {
      stickers[s.number] = TradeSticker(
        code: s.number,
        nationCode: s.nationId != null ? nationCodeById[s.nationId!] : null,
        isFoil: s.isFoil,
      );
      allCodes.add(s.number);
    }

    // If "Faltantes" was included in the export, use it. Otherwise infer:
    // friend is missing every album sticker that isn't in their dupes.
    final Set<String> missing;
    if (faltantes.isNotEmpty) {
      missing = faltantes;
    } else {
      missing = allCodes.difference(repetidas.keys.toSet());
    }

    final friend = TradeInventory(
      dupesByCode: repetidas,
      missingCodes: missing,
      stickersByCode: stickers,
      favoriteNations: const {},
      profileName: 'amigo do Figuritas',
    );
    await _applyFriend(friend);
  }

  Future<void> _applyFriend(TradeInventory friend) async {
    setState(() {
      _busy = true;
      _error = null;
      _friendName = null;
      _offers = null;
      _confirmedIdx.clear();
      _invalidatedIdx.clear();
    });
    try {
      final me = await InventoryCodec.myInventory(ref.read(databaseProvider));
      // Pull the user's tuned rules — defaults to 1×1 + 1×2 mixed when
      // the user hasn't touched the settings.
      final rules = ref.read(tradeRulesProvider);
      final offers = TradeMatcher.match(me: me, friend: friend, rules: rules);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _me = me;
        _friend = friend;
        _friendName = friend.profileName ?? 'amigo';
        _offers = offers;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Não consegui comparar inventários: $e';
      });
    }
  }
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.accent, c.accent.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cole o inventário do amigo ou escaneie o QR — '
              'as melhores trocas aparecem na hora.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final TradeOffer offer;
  final bool confirmed;
  final bool invalidated;
  final VoidCallback? onConfirm;
  final void Function(String code)? onSwapReceive;
  final void Function(String code)? onSwapGive;

  const _OfferCard({
    required this.offer,
    this.confirmed = false,
    this.invalidated = false,
    this.onConfirm,
    this.onSwapReceive,
    this.onSwapGive,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Opacity(
      // Invalidated offers stay visible (so the user understands the
      // matcher had OTHER options too) but dim out so they read as
      // "not actionable" at a glance.
      opacity: invalidated ? 0.45 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: confirmed ? c.cardAlt.withValues(alpha: 0.4) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: confirmed
                          ? const Color(0xFF22C58A)
                          : invalidated
                              ? c.textMuted
                              : (offer.kind == 'mixed'
                                  ? Colors.orange
                                  : c.accent),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      confirmed
                          ? '✓ Trocada'
                          : invalidated
                              ? '✕ Já usado em outra troca'
                              : (offer.kind == 'mixed'
                                  ? 'Brilhante × 2 normais'
                                  : 'Troca 1×1'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
            ),
            const SizedBox(height: 10),
            _Row(
              label: 'Você dá',
              codes: offer.youGive,
              color: Colors.red.shade300,
              onSwap: onSwapGive,
            ),
            const SizedBox(height: 8),
            _Row(
              label: 'Você recebe',
              codes: offer.youReceive,
              color: Colors.green.shade400,
              onSwap: onSwapReceive,
            ),
            if (!confirmed && onConfirm != null) ...[
              const SizedBox(height: 10),
              // Full-width action button so the user can tap "Marcamos!"
              // right after the swap happens in real life. The app updates
              // both sides of the collection automatically (give = subtract
              // from dupes, receive = add to owned/duplicates).
              FilledButton.icon(
                icon: const Icon(Icons.handshake_rounded, size: 18),
                label: const Text('Marcamos! Atualizar coleção'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF22C58A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(40),
                ),
                onPressed: onConfirm,
              ),
            ],
            if (confirmed) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF22C58A), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Coleção atualizada',
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final Map<String, int> codes;
  final Color color;
  /// Tap the swap icon next to a sticker chip to pick a different one
  /// (friend already had this card, or the user wants to offer another
  /// dupe). Null = no swap action available (offer confirmed/invalidated).
  final void Function(String code)? onSwap;
  const _Row({
    required this.label,
    required this.codes,
    required this.color,
    this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final e in codes.entries)
                _CodeChip(
                  code: e.key,
                  quantity: e.value,
                  onSwap: onSwap == null ? null : () => onSwap!(e.key),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Chip showing one sticker code with an optional swap icon to its right
/// (the user taps to pick a different sticker if the friend already has
/// this one).
class _CodeChip extends StatelessWidget {
  final String code;
  final int quantity;
  final VoidCallback? onSwap;
  const _CodeChip({
    required this.code,
    required this.quantity,
    this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final label = quantity > 1 ? '$code ×$quantity' : code;
    return Container(
      decoration: BoxDecoration(
        color: c.cardAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8, 3, onSwap == null ? 8 : 4, 3),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          if (onSwap != null)
            InkWell(
              onTap: onSwap,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: 14,
                  color: c.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
