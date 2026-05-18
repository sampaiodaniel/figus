import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/figus_colors.dart';
import '../../data/providers.dart';
import 'inventory_codec.dart';
import 'trade_matcher.dart';

/// "Comparar com amigo" — accepts the friend's inventory (pasted JSON for
/// now; Bluetooth/QR plug in later) and shows the suggested trades.
class CompareFriendPage extends ConsumerStatefulWidget {
  /// Optional pre-loaded friend inventory (already-decoded JSON map) passed
  /// in when the user arrives from a QR scan instead of pasting JSON
  /// manually. When present, [_CompareFriendPageState.initState] runs the
  /// match immediately so the trades show up without an extra tap.
  final Map<dynamic, dynamic>? initialFriendJson;
  const CompareFriendPage({super.key, this.initialFriendJson});
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

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFriendJson;
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyFriendJson(
            jsonEncode(initial.cast<String, dynamic>()),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparar com amigo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Compartilhar meu inventário',
            onPressed: _shareMyInventory,
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
                  onConfirm: _confirmedIdx.contains(i)
                      ? null
                      : () => _confirmOffer(i),
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
              'Peça pro amigo compartilhar o inventário (botão ↗) e cole aqui.',
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
                hintText: 'Cole o JSON aqui...',
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

  Future<void> _applyFriendJson(String json) async {
    setState(() {
      _busy = true;
      _error = null;
      _friendName = null;
      _offers = null;
      _confirmedIdx.clear();
    });
    try {
      final friend = InventoryCodec.decodeAsFriend(json);
      final me = await InventoryCodec.myInventory(ref.read(databaseProvider));
      final offers = TradeMatcher.match(me: me, friend: friend);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _friendName = InventoryCodec.profileNameOf(json) ?? 'amigo';
        _offers = offers;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Não consegui ler o inventário: $e';
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
  final VoidCallback? onConfirm;

  const _OfferCard({
    required this.offer,
    this.confirmed = false,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      // When the trade is confirmed, dim the card so the user can see at a
      // glance which suggestions have already been actioned.
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
                        : (offer.kind == 'same' ? c.accent : Colors.orange),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    confirmed
                        ? '✓ Trocada'
                        : (offer.kind == 'same'
                            ? '1×1 mesmo tipo'
                            : '1 brilhante × 2 normais'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text('score ${offer.score.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 11, color: c.textMuted)),
              ],
            ),
            const SizedBox(height: 10),
            _Row(label: 'Você dá', codes: offer.youGive, color: Colors.red.shade300),
            const SizedBox(height: 8),
            _Row(label: 'Você recebe', codes: offer.youReceive, color: Colors.green.shade400),
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
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final Map<String, int> codes;
  final Color color;
  const _Row({required this.label, required this.codes, required this.color});

  @override
  Widget build(BuildContext context) {
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.fc.cardAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    e.value > 1 ? '${e.key} ×${e.value}' : e.key,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
