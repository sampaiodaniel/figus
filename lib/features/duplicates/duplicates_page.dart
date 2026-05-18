import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/country_codes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/figus_colors.dart';
import '../../core/widgets/figus_app_bar.dart';
import '../../data/providers.dart';
import '../../data/repos/album_repo.dart';
import '../../domain/models/album_view_models.dart';
import '../share/share_service.dart';

/// Dedicated page for the user's duplicates — what they take to trades.
/// Grouped by nation, each item shows quantity and lets you remove one with a
/// single tap (long-press in the Coleção page also works).
class DuplicatesPage extends ConsumerWidget {
  const DuplicatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(_sectionsProvider);
    return Scaffold(
      appBar: FigusAppBar(
        title: 'Repetidas',
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Compartilhar lista',
            onPressed: () => _share(context, ref),
          ),
        ],
      ),
      body: sectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (sections) {
          if (sections.isEmpty) {
            return const _EmptyState();
          }
          final totalCopies = sections
              .expand((s) => s.stickers)
              .fold<int>(0, (sum, s) => sum + s.duplicateCount);
          return Column(
            children: [
              _Header(
                uniqueCount: sections.fold(0, (sum, s) => sum + s.stickers.length),
                totalCopies: totalCopies,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: sections.length,
                  itemBuilder: (_, i) => _NationGroup(
                    section: sections[i],
                    onRemoveOne: (sticker) async {
                      HapticFeedback.lightImpact();
                      await ref.read(collectionRepoProvider).removeSticker(sticker.id);
                      ref.read(collectionVersionProvider.notifier).state++;
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(SnackBar(
                          content: Text('${sticker.number} removida'),
                          duration: const Duration(seconds: 4),
                          action: SnackBarAction(
                            label: 'Desfazer',
                            onPressed: () async {
                              await ref.read(collectionRepoProvider).tapSticker(sticker.id);
                              ref.read(collectionVersionProvider.notifier).state++;
                            },
                          ),
                        ));
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final sections = await ref.read(albumRepoProvider).loadSections(filter: AlbumFilter.duplicates);
    final flat = sections.expand((s) => s.stickers).toList();
    if (flat.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sem repetidas pra compartilhar.')),
      );
      return;
    }
    await ShareService.shareTextList(
      title: 'Tenho essas repetidas pra trocar:',
      stickers: flat,
    );
  }
}

final _sectionsProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(collectionVersionProvider);
  return ref.watch(albumRepoProvider).loadSections(filter: AlbumFilter.duplicates);
});

class _Header extends StatelessWidget {
  final int uniqueCount;
  final int totalCopies;
  const _Header({required this.uniqueCount, required this.totalCopies});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.copy_all_rounded, color: c.accent),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: c.text, fontSize: 14),
                children: [
                  TextSpan(
                    text: '$uniqueCount ',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  TextSpan(
                    text: uniqueCount == 1
                        ? 'figurinha diferente  ·  '
                        : 'figurinhas diferentes  ·  ',
                  ),
                  TextSpan(
                    text: '$totalCopies ',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  TextSpan(
                    text: totalCopies == 1 ? 'cópia no total' : 'cópias no total',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NationGroup extends StatelessWidget {
  final AlbumSection section;
  final void Function(StickerView) onRemoveOne;
  const _NationGroup({required this.section, required this.onRemoveOne});

  static String _nameOnly(String title) {
    final idx = title.indexOf('-');
    return idx < 0 ? title : title.substring(idx + 1).trim();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final iso = paniniToIso2[section.key];
    final name = _nameOnly(section.title);
    final totalCopies = section.stickers
        .fold<int>(0, (sum, s) => sum + s.duplicateCount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — same style as NationPanel
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                if (iso != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CountryFlag.fromCountryCode(iso, width: 36, height: 26),
                  )
                else
                  Container(
                    width: 36,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      section.key.substring(0, section.key.length.clamp(0, 3)),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: c.text,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                      children: [
                        TextSpan(
                          text: section.key,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: c.textMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const TextSpan(text: '  ·  '),
                        TextSpan(text: name),
                      ],
                    ),
                  ),
                ),
                Text(
                  totalCopies == 1 ? '1 cópia' : '$totalCopies cópias',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: AppTheme.pulpSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in section.stickers)
                  _DuplicateChip(sticker: s, onRemoveOne: () => onRemoveOne(s)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DuplicateChip extends StatelessWidget {
  final StickerView sticker;
  final VoidCallback onRemoveOne;

  const _DuplicateChip({required this.sticker, required this.onRemoveOne});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final num = sticker.number.replaceAll(RegExp(r'^[A-Z]+'), '');
    return Container(
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('#$num',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: c.accent,
                    )),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '×${sticker.duplicateCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Explicit remove button — only this triggers removal
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onRemoveOne();
              },
              borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 10, 8),
                child: Icon(
                  Icons.remove_circle_outline_rounded,
                  size: 18,
                  color: c.textMuted.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 72, color: c.border),
          const SizedBox(height: 16),
          const Text('Nenhuma repetida ainda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Quando você abrir um pacote e tirar uma figurinha que já tem, ela vai aparecer aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
