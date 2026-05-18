import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/figus_colors.dart';
import '../../data/providers.dart';
import 'ocr_service.dart';

/// Confirmation sheet — user reviews detected codes and toggles before saving.
/// "Never mark silently" = the explicit anti-pitfall vs competitor apps.
Future<void> showReviewDetectionsSheet(
  BuildContext context,
  WidgetRef ref,
  List<StickerDetection> detections,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ReviewDetectionsSheet(detections: detections, ref: ref),
  );
}

class _ReviewDetectionsSheet extends StatefulWidget {
  final List<StickerDetection> detections;
  final WidgetRef ref;
  const _ReviewDetectionsSheet({required this.detections, required this.ref});

  @override
  State<_ReviewDetectionsSheet> createState() => _ReviewDetectionsSheetState();
}

class _ReviewDetectionsSheetState extends State<_ReviewDetectionsSheet> {
  late final Map<String, bool> _selected = {
    for (final d in widget.detections) d.code: true,
  };

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selected.values.where((v) => v).length;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Text('${widget.detections.length} figurinhas detectadas',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Toque pra desmarcar as que estão erradas',
                style: TextStyle(color: context.fc.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: widget.detections.length,
                itemBuilder: (_, i) {
                  final d = widget.detections[i];
                  final on = _selected[d.code] ?? true;
                  return CheckboxListTile(
                    value: on,
                    onChanged: (v) => setState(() => _selected[d.code] = v ?? false),
                    title: Text(d.code,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    subtitle: Text('"${d.rawText}"',
                        style: TextStyle(color: context.fc.textMuted, fontSize: 12)),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 8),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_rounded),
                        label: Text('Marcar $selectedCount como tenho'),
                        onPressed: selectedCount == 0 ? null : _commit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _commit() async {
    final repo = widget.ref.read(collectionRepoProvider);
    final db = widget.ref.read(databaseProvider);
    final codes = _selected.entries.where((e) => e.value).map((e) => e.key).toList();

    // Look up sticker IDs by number
    final all = await db.select(db.stickers).get();
    final byNumber = {for (final s in all) s.number: s};

    var marked = 0;
    for (final code in codes) {
      final s = byNumber[code];
      if (s == null) continue;
      await repo.tapSticker(s.id);
      marked++;
    }
    widget.ref.read(collectionVersionProvider.notifier).state++;

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(marked == 1
            ? '1 figurinha marcada ✓'
            : '$marked figurinhas marcadas ✓'),
      ),
    );
  }
}
