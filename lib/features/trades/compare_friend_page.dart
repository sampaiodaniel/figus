import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import 'inventory_codec.dart';
import 'trade_matcher.dart';

/// "Comparar com amigo" — accepts the friend's inventory (pasted JSON for
/// now; Bluetooth/QR plug in later) and shows the suggested trades.
class CompareFriendPage extends ConsumerStatefulWidget {
  const CompareFriendPage({super.key});
  @override
  ConsumerState<CompareFriendPage> createState() => _CompareFriendPageState();
}

class _CompareFriendPageState extends ConsumerState<CompareFriendPage> {
  List<TradeOffer>? _offers;
  String? _friendName;
  String? _error;
  bool _busy = false;

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
                style: const TextStyle(color: AppTheme.inkSoft),
              ),
              const SizedBox(height: 8),
              for (final o in _offers!) _OfferCard(offer: o),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _shareMyInventory() async {
    final db = ref.read(databaseProvider);
    final exported = await InventoryCodec.exportMine(db);
    final json = InventoryCodec.encodeJson(exported);
    await Share.share(json, subject: 'Meu inventário Figus');
  }

  Future<void> _pasteInventory() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Inventário do amigo'),
        content: SizedBox(
          width: 500,
          child: TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 10,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Cole aqui o JSON enviado pelo amigo',
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, ctrl.text.trim()),
            child: const Text('Comparar'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _friendName = null;
      _offers = null;
    });
    try {
      final friend = InventoryCodec.decodeAsFriend(result);
      final me = await InventoryCodec.myInventory(ref.read(databaseProvider));
      final offers = TradeMatcher.match(me: me, friend: friend);
      setState(() {
        _busy = false;
        _friendName = InventoryCodec.profileNameOf(result) ?? 'amigo';
        _offers = offers;
      });
    } catch (e) {
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.seed, Color(0xFF7A5BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 26),
              SizedBox(width: 10),
              Text('Sugestões automáticas',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Cruzo minhas repetidas + caça com as do amigo. '
            '1×1 mesmo tipo é prioridade; brilhante vale 2 normais.',
            style: TextStyle(color: Colors.white, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final TradeOffer offer;
  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
                    color: offer.kind == 'same' ? AppTheme.seed : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    offer.kind == 'same' ? '1×1 mesmo tipo' : '1 brilhante × 2 normais',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text('score ${offer.score.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
              ],
            ),
            const SizedBox(height: 10),
            _Row(label: 'Você dá', codes: offer.youGive, color: Colors.red.shade300),
            const SizedBox(height: 8),
            _Row(label: 'Você recebe', codes: offer.youReceive, color: Colors.green.shade400),
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
                    color: AppTheme.slotSoft,
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
