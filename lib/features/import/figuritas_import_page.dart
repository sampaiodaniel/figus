import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/figus_colors.dart';
import '../../data/providers.dart';
import '../scan/ocr_service.dart';
import '../scan/review_detections_sheet.dart';

/// Two import flows for bringing a sticker collection from any source:
///   1. Pick a screenshot → OCR extracts codes (mobile only).
///   2. Paste a text list → auto-detects Figuritas format OR plain code list.
class FiguritasImportPage extends ConsumerWidget {
  const FiguritasImportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar coleção')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Traga sua coleção de qualquer lugar.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Sempre mostramos um preview antes de salvar.',
            style: TextStyle(color: context.fc.textMuted),
          ),
          const SizedBox(height: 24),
          _ImportTile(
            icon: Icons.image_outlined,
            title: 'Foto ou screenshot',
            subtitle: OcrService.isSupported
                ? 'Tire uma foto ou screenshot mostrando os códigos das figurinhas e a gente lê automaticamente.'
                : 'Disponível apenas no celular.',
            enabled: OcrService.isSupported,
            onTap: () => _pickAndOcr(context, ref),
          ),
          const SizedBox(height: 12),
          _ImportTile(
            icon: Icons.text_fields_outlined,
            title: 'Colar lista (Figuritas ou códigos)',
            subtitle:
                'Cole o texto exportado do Figuritas App, ou uma lista de códigos separados por vírgula (ex: BRA1, MEX5, FWC9).',
            enabled: true,
            onTap: () => _pasteList(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndOcr(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: false,
    );
    if (result == null || result.files.single.path == null) return;
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final detections = await OcrService.recognize(result.files.single.path!);
      if (!context.mounted) return;
      Navigator.pop(context);
      if (detections.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum código encontrado na imagem.')),
        );
        return;
      }
      await showReviewDetectionsSheet(context, ref, detections);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _pasteList(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final c = context.fc;
    final input = await showModalBottomSheet<String>(
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
              'Cole sua lista',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Aceita o texto exportado do Figuritas App ou uma lista de códigos tipo BRA1, MEX5, FWC9.',
              style: TextStyle(fontSize: 13, color: c.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              minLines: 5,
              maxLines: 12,
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
                hintText:
                    'Cole aqui o export do Figuritas ou lista de códigos...',
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
                    child: const Text('Detectar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (input == null || input.isEmpty) return;
    if (!context.mounted) return;

    if (_isFiguritasFormat(input)) {
      await _importFiguritasFormat(context, ref, input);
    } else {
      final detections = _parseTextToDetections(input);
      if (detections.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum código válido encontrado.')),
        );
        return;
      }
      await showReviewDetectionsSheet(context, ref, detections);
    }
  }

  // ── Figuritas format ────────────────────────────────────────────────────────

  static bool _isFiguritasFormat(String text) {
    final lower = text.toLowerCase();
    return lower.contains('faltante') || lower.contains('figurinhas app');
  }

  /// Returns (faltantesSet, repetidas map code→extraCount).
  static (Set<String>, Map<String, int>) _parseFiguritasExport(String text) {
    final faltantes = <String>{};
    final repetidas = <String, int>{};

    var inFaltantes = false;
    var inRepetidas = false;

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final lower = line.toLowerCase();

      if (lower.contains('faltante')) {
        inFaltantes = true;
        inRepetidas = false;
        continue;
      }
      if (lower.contains('repetida')) {
        inFaltantes = false;
        inRepetidas = true;
        continue;
      }
      // Footer / irrelevant lines
      if (lower.contains('baixe') ||
          lower.contains('http') ||
          lower.contains('figurinhas app')) {
        continue;
      }

      if (!inFaltantes && !inRepetidas) continue;

      // Extract team code: first sequence of ASCII letters (2-4 chars)
      final codeMatch = RegExp(r'^([A-Za-z]{2,4})\b').firstMatch(line);
      if (codeMatch == null) continue;
      final teamCode = codeMatch.group(1)!.toUpperCase();

      // Numbers come after ':'
      final colonIdx = line.indexOf(':');
      if (colonIdx < 0) continue;
      final numbersPart = line.substring(colonIdx + 1);

      for (final part in numbersPart.split(',')) {
        final trimmed = part.trim();
        // Handle "N", "N x2", "Nx2", "N(x2)", "N×2" — Figuritas sometimes
        // encodes quantity when you have multiple copies of the same sticker.
        final m = RegExp(r'^(\d+)(?:\s*[x×(]\s*(\d+))?').firstMatch(trimmed);
        if (m == null) continue;
        final n = int.tryParse(m.group(1)!);
        final count = int.tryParse(m.group(2) ?? '1') ?? 1;
        if (n == null || n < 0) continue;
        final code = n == 0 ? '${teamCode}00' : '$teamCode$n';
        if (inFaltantes) {
          faltantes.add(code);
        } else {
          repetidas[code] = (repetidas[code] ?? 0) + count;
        }
      }
    }

    return (faltantes, repetidas);
  }

  Future<void> _importFiguritasFormat(
    BuildContext context,
    WidgetRef ref,
    String text,
  ) async {
    final (faltantes, repetidas) = _parseFiguritasExport(text);

    // Count how many stickers will be owned/duped/missing after import.
    // Only stickers whose prefix appears in the export are touched.
    final db = ref.read(databaseProvider);
    final allStickers = await db.select(db.stickers).get();

    String _prefix(String code) =>
        RegExp(r'^[A-Za-z]+').firstMatch(code)?.group(0)?.toUpperCase() ?? code;
    final knownPrefixes = <String>{
      ...faltantes.map(_prefix),
      ...repetidas.keys.map(_prefix),
    };

    // "Tenho" = unique stickers owned at least once (matches Figuritas display)
    final ownedCount = allStickers.where((s) {
      final pfx = _prefix(s.number);
      return knownPrefixes.contains(pfx) && !faltantes.contains(s.number);
    }).length;
    // "Repetidas" = total extra copies (sum of counts, not unique types)
    final dupesCount = repetidas.values.fold(0, (a, b) => a + b);
    final missingCount = faltantes.length;

    if (!context.mounted) return;

    final fc = context.fc;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: fc.card,
        title: const Text(
          'Importar do Figuritas',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sua coleção atual será substituída pelos dados do Figuritas:',
              style: TextStyle(color: fc.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              color: fc.accent,
              icon: Icons.check_circle_outline_rounded,
              label: 'Tenho',
              value: '$ownedCount figurinhas',
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              color: AppTheme.pulp,
              icon: Icons.copy_all_rounded,
              label: 'Repetidas',
              value: '$dupesCount cópias extras',
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              color: fc.textMuted,
              icon: Icons.radio_button_unchecked_rounded,
              label: 'Faltam',
              value: '$missingCount figurinhas',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.pulp.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.pulp.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppTheme.pulp),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Atenção: o Figuritas exporta cada figurinha repetida só '
                      'uma vez no texto, sem informar a quantidade. Se você tem '
                      '3+ cópias da mesma figurinha, marque manualmente o '
                      'contador depois — abra a figurinha no álbum e toque pra '
                      'incrementar.',
                      style: TextStyle(
                        fontSize: 11,
                        color: fc.text.withValues(alpha: 0.85),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final result = await ref.read(collectionRepoProvider).bulkImportFiguritas(
            faltantes: faltantes,
            repetidas: repetidas,
          );
      ref.read(collectionVersionProvider.notifier).state++;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result['owned']} tenho + ${result['dupes']} repetidas importadas ✓',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao importar: $e')),
      );
    }
  }

  // ── Plain code list ─────────────────────────────────────────────────────────

  List<StickerDetection> _parseTextToDetections(String text) {
    final regex = RegExp(r'\b([A-Z]{2,4})\s*[-–]?\s*(\d{1,3})\b');
    final upper = text.toUpperCase();
    final seen = <String>{};
    final out = <StickerDetection>[];
    for (final m in regex.allMatches(upper)) {
      final sigla = m.group(1)!;
      final number = int.tryParse(m.group(2)!);
      if (number == null) continue;
      if (sigla == 'FWC') {
        if (number > 19) continue;
      } else {
        if (number < 1 || number > 20) continue;
      }
      final code =
          (sigla == 'FWC' && number == 0) ? 'FWC00' : '$sigla$number';
      if (seen.add(code)) {
        out.add(
            StickerDetection(code: code, confidence: 1.0, rawText: m.group(0)!));
      }
    }
    return out;
  }
}

// ── helpers ──────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String value;
  const _SummaryRow({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
              fontWeight: FontWeight.w700, color: color, fontSize: 14),
        ),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: context.fc.text,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
      ],
    );
  }
}

class _ImportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;
  const _ImportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        enabled: enabled,
        leading: Icon(icon, color: enabled ? context.fc.accent : AppTheme.slot),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: enabled ? const Icon(Icons.chevron_right) : null,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
