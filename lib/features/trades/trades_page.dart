import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/country_codes.dart';
import '../../core/theme/figus_colors.dart';
import '../../core/widgets/figus_app_bar.dart';
import '../../data/providers.dart';
import '../../data/repos/album_repo.dart';
import '../../domain/models/album_view_models.dart';

/// Hub of the trade flow — the headline differentiator of the app. Reworked
/// from a wall-of-text into a quick action grid: every entry point (QR,
/// Bluetooth, compare-by-paste, export) is a big tappable icon. The two
/// existing lists ("Pra trocar" / "Caçando") stay below so the user always
/// knows what they can offer and what they want.
class TradesPage extends ConsumerWidget {
  const TradesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dupesAsync = ref.watch(_duplicatesProvider);
    final missingAsync = ref.watch(_missingProvider);
    final c = context.fc;

    return Scaffold(
      appBar: FigusAppBar(
        title: 'Trocas',
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Configurações de trocas',
            onPressed: () => context.push('/trade-rules'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Suggestion section ──────────────────────────────────────────
          _SectionLabel(
            icon: Icons.auto_awesome_rounded,
            label: 'SUGESTÕES DE TROCA',
            accent: c.accent,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  c.accent.withValues(alpha: 0.12),
                  c.accent.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.accent.withValues(alpha: 0.25)),
            ),
            child: Text(
              'Compare com um amigo pra ver trocas sugeridas automaticamente. '
              'Você confirma cada troca antes de marcar — nada é alterado sem '
              'seu OK.',
              style: TextStyle(
                fontSize: 13,
                color: c.text,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── 2x2 action grid ─────────────────────────────────────────────
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            // Tiles are squarer + smaller now so the icon and text fill the
            // available area instead of swimming in white space.
            childAspectRatio: 1.0,
            children: [
              _ActionTile(
                icon: Icons.qr_code_scanner_rounded,
                label: 'QR Code',
                sub: 'Mostre ou escaneie',
                accent: c.accent,
                onTap: () => context.push('/trade-qr'),
              ),
              _ActionTile(
                icon: Icons.bluetooth_searching_rounded,
                label: 'Bluetooth',
                sub: 'Trocar sem internet',
                accent: c.accent,
                onTap: () => context.push('/trade-bt'),
              ),
              _ActionTile(
                icon: Icons.compare_arrows_rounded,
                label: 'Comparar',
                sub: 'Inventário do amigo',
                accent: c.accent,
                onTap: () => context.push('/compare'),
              ),
              dupesAsync.maybeWhen(
                data: (list) => _ActionTile(
                  icon: Icons.ios_share_rounded,
                  label: 'Exportar',
                  sub: list.isEmpty
                      ? 'Sem repetidas'
                      : 'Lista pra WhatsApp',
                  accent: c.accent,
                  disabled: list.isEmpty,
                  onTap: list.isEmpty
                      ? null
                      : () => _shareDuplicatesList(list),
                ),
                orElse: () => _ActionTile(
                  icon: Icons.ios_share_rounded,
                  label: 'Exportar',
                  sub: 'Lista pra WhatsApp',
                  accent: c.accent,
                  disabled: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── My duplicates ───────────────────────────────────────────────
          _SectionLabel(
            icon: Icons.outbox_rounded,
            label: 'PRA TROCAR',
            accent: c.accent,
            subtitle: 'Suas repetidas — leva pra escola, partidas, encontros',
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 28),

          // ── Missing list ────────────────────────────────────────────────
          _SectionLabel(
            icon: Icons.radar_rounded,
            label: 'CAÇANDO',
            accent: c.accent,
            subtitle: 'Figurinhas que você ainda não tem',
          ),
          const SizedBox(height: 10),
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
    );
  }
}

void _shareDuplicatesList(List<StickerView> dupes) {
  // Sort by sticker number for predictability — humans skim lists easier.
  final sorted = List<StickerView>.from(dupes)
    ..sort((a, b) => a.number.compareTo(b.number));
  final lines = <String>[
    '📒 Minhas figurinhas REPETIDAS — Figus · Copa 2026',
    '',
  ];
  for (final s in sorted) {
    final qty = s.duplicateCount > 0 ? ' (×${s.duplicateCount})' : '';
    lines.add('• ${s.number}$qty');
  }
  final total = sorted.fold<int>(
      0, (sum, s) => sum + (s.duplicateCount > 0 ? s.duplicateCount : 1));
  final pluralTotal =
      total == 1 ? '1 figurinha pra trocar' : '$total figurinhas pra trocar';
  lines
    ..add('')
    ..add('Total: $pluralTotal')
    ..add('')
    ..add('Quer trocar? Me chama 👋')
    ..add('Baixe o Figus: https://appfigus.com');
  Share.share(lines.join('\n'),
      subject: 'Minhas figurinhas repetidas — Copa 2026');
}

/// Square action tile with a large icon + 1-line label + 1-line sub. Used
/// in the 2×2 grid at the top of [TradesPage]. Disabled tiles dim and show
/// no chevron; enabled tiles get a small chevron to suggest interactivity.
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color accent;
  final bool disabled;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.accent,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final iconColor = disabled ? c.textMuted : accent;
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: disabled ? c.border : accent.withValues(alpha: 0.45),
            width: disabled ? 1 : 1.5,
          ),
        ),
        // Centered vertical layout: big icon, label below, sub last. Tiles
        // are visually compact but the icon is the dominant element so the
        // action reads at a glance.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 34),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: disabled ? c.text.withValues(alpha: 0.5) : c.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final String? subtitle;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.accent,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: accent,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipList extends StatelessWidget {
  final List<StickerView> items;
  final bool missing;
  const _ChipList({required this.items, this.missing = false});

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
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                  children: [
                    TextSpan(
                      text: section.key,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
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
              section.totalCount == 1 ? '1 falta' : '${section.totalCount} faltam',
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
