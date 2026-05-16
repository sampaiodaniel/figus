import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/country_codes.dart';
import '../../core/theme/figus_colors.dart';
import '../../data/providers.dart';
import '../../data/repos/album_repo.dart';
import '../../domain/models/album_view_models.dart';

/// Trades hub — placeholder until P2P (v2) lands. Today shows your duplicates
/// (what you can offer) and missing list (what you want).
class TradesPage extends ConsumerWidget {
  const TradesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dupesAsync = ref.watch(_duplicatesProvider);
    final missingAsync = ref.watch(_missingProvider);
    final c = context.fc;

    return Scaffold(
      appBar: AppBar(title: const Text('Trocas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => context.push('/compare'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.accent, c.accent.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Comparar com amigo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Colors.white),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Compartilhe seu inventário (botão ↗ lá dentro), mande pro amigo. '
                      'Ele cola no app e vê as trocas sugeridas automaticamente.',
                      style: TextStyle(color: Colors.white, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Pra trocar',
              subtitle: 'Suas repetidas — leva pra escola, partidas, encontros',
              icon: Icons.outbox_rounded,
            ),
            dupesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Erro: $e'),
              data: (list) => list.isEmpty
                  ? const _EmptyMini(text: 'Você não tem repetidas ainda.')
                  : _ChipList(items: list),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Caçando',
              subtitle: 'Figurinhas que você ainda não tem',
              icon: Icons.radar_rounded,
            ),
            missingAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Erro: $e'),
              data: (sections) => sections.isEmpty
                  ? const _EmptyMini(text: 'Coleção completa! 🎉')
                  : _MissingSections(sections: sections),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _SectionHeader({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: c.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: c.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipList extends StatelessWidget {
  final List<StickerView> items;
  final bool missing;
  const _ChipList({required this.items});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final s in items.take(60))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: missing ? c.cardAlt : c.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: missing ? c.border : c.accent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.number,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: missing ? c.textMuted : c.accent,
                    )),
                if (s.duplicateCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text('×${s.duplicateCount}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: c.accent,
                        )),
                  ),
              ],
            ),
          ),
        if (items.length > 60)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text('+ ${items.length - 60}',
                style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

class _EmptyMini extends StatelessWidget {
  final String text;
  const _EmptyMini({required this.text});
  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: TextStyle(color: c.textMuted)),
    );
  }
}

/// Grouped "Caçando" list — one collapsible section per nation, with real flag.
class _MissingSections extends StatefulWidget {
  final List<AlbumSection> sections;
  const _MissingSections({required this.sections});
  @override
  State<_MissingSections> createState() => _MissingSectionsState();
}

class _MissingSectionsState extends State<_MissingSections> {
  final Set<String> _expanded = {};

  static String _nameOnly(String title) {
    final idx = title.indexOf('-');
    return idx < 0 ? title : title.substring(idx + 1).trim();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in widget.sections) ...[
          _buildHeader(section),
          if (_expanded.contains(section.key)) _buildChips(section),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildHeader(AlbumSection section) {
    final c = context.fc;
    final iso = paniniToIso2[section.key];
    final name = _nameOnly(section.title);
    final isOpen = _expanded.contains(section.key);

    return GestureDetector(
      onTap: () => setState(() {
        if (isOpen) {
          _expanded.remove(section.key);
        } else {
          _expanded.add(section.key);
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            if (iso != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CountryFlag.fromCountryCode(iso, width: 30, height: 22),
              )
            else
              Container(
                width: 30,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  section.key.substring(0, section.key.length.clamp(0, 3)),
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: c.text),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: c.text),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${section.totalCount} faltam',
              style: GoogleFonts.jetBrainsMono(fontSize: 10, color: c.textMuted),
            ),
            const SizedBox(width: 6),
            Icon(
              isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: c.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChips(AlbumSection section) {
    final c = context.fc;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: c.cardAlt,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        border: Border.all(color: c.border),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final s in section.stickers)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border, width: 1),
              ),
              child: Text(
                s.number,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final _duplicatesProvider = FutureProvider.autoDispose<List<StickerView>>((ref) async {
  ref.watch(collectionVersionProvider);
  final repo = ref.watch(albumRepoProvider);
  final sections = await repo.loadSections(filter: AlbumFilter.duplicates);
  return sections.expand((s) => s.stickers).toList();
});

final _missingProvider = FutureProvider.autoDispose<List<AlbumSection>>((ref) async {
  ref.watch(collectionVersionProvider);
  final repo = ref.watch(albumRepoProvider);
  return repo.loadSections(filter: AlbumFilter.missing);
});
