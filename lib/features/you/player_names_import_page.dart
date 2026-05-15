import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';

/// Bulk import of player names from a CSV/TSV the user pastes:
///
///   BRA1,Alisson
///   BRA2,Marquinhos
///   ARG10,Lionel Messi
///   ...
///
/// Any line that doesn't match a known sticker code is silently skipped.
class PlayerNamesImportPage extends ConsumerStatefulWidget {
  const PlayerNamesImportPage({super.key});
  @override
  ConsumerState<PlayerNamesImportPage> createState() => _PlayerNamesImportPageState();
}

class _PlayerNamesImportPageState extends ConsumerState<PlayerNamesImportPage> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _summary;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar nomes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.slotSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Cole uma lista no formato CÓDIGO,NOME (uma por linha).\n'
                'Exemplo:\n\n'
                'BRA1,Alisson\n'
                'BRA2,Marquinhos\n'
                'ARG10,Lionel Messi\n\n'
                'Vírgula, ponto-e-vírgula ou tab funcionam como separador.',
                style: TextStyle(height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _ctrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'BRA1,Alisson\nBRA2,Marquinhos\n...',
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.save_rounded),
              label: Text(_busy ? 'Importando...' : 'Salvar nomes'),
              onPressed: _busy ? null : _import,
            ),
            if (_summary != null) ...[
              const SizedBox(height: 10),
              Text(_summary!, style: const TextStyle(color: AppTheme.seed)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _import() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    try {
      final map = <String, String>{};
      for (final raw in text.split('\n')) {
        final line = raw.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final parts = line.split(RegExp(r'[,\t;]'));
        if (parts.length < 2) continue;
        final code = parts[0].trim().toUpperCase();
        final name = parts.sublist(1).join(' ').trim();
        if (code.isEmpty || name.isEmpty) continue;
        map[code] = name;
      }
      final updated = await ref.read(collectionRepoProvider).bulkSetPlayerNames(map);
      ref.read(collectionVersionProvider.notifier).state++;
      setState(() {
        _summary = '$updated nome(s) atualizado(s) de ${map.length} linha(s) lida(s).';
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _summary = 'Erro: $e';
        _busy = false;
      });
    }
  }
}
