import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../scan/ocr_service.dart';
import '../scan/review_detections_sheet.dart';

/// Two import flows for bringing a sticker collection from any source:
///   1. Pick a screenshot → OCR extracts codes (mobile only).
///   2. Paste a text list → regex parses every valid code.
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
          const Text(
            'Sempre mostramos um preview antes de salvar.',
            style: TextStyle(color: AppTheme.inkSoft),
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
            title: 'Colar lista de códigos',
            subtitle: 'Ex.: BRA1, BRA10, MEX5, FWC9 — separados por vírgula, espaço ou linha.',
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _pasteList(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final input = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cole sua lista'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'BRA1, BRA10, MEX5\nFWC9, ARG3, ...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, ctrl.text.trim()),
            child: const Text('Detectar'),
          ),
        ],
      ),
    );
    if (input == null || input.isEmpty) return;
    if (!context.mounted) return;

    final detections = _parseTextToDetections(input);
    if (detections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum código válido encontrado.')),
      );
      return;
    }
    await showReviewDetectionsSheet(context, ref, detections);
  }

  List<StickerDetection> _parseTextToDetections(String text) {
    final regex = RegExp(r'\b([A-Z]{3})\s*[-–]?\s*(\d{1,3})\b');
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
      final code = (sigla == 'FWC' && number == 0) ? 'FWC00' : '$sigla$number';
      if (seen.add(code)) {
        out.add(StickerDetection(code: code, confidence: 1.0, rawText: m.group(0)!));
      }
    }
    return out;
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
        leading: Icon(icon, color: enabled ? AppTheme.seed : AppTheme.slot),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: enabled ? const Icon(Icons.chevron_right) : null,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
