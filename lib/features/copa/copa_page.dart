import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/country_codes.dart';
import '../../core/theme/figus_colors.dart';
import '../../data/models/copa_models.dart';
import '../../data/repos/matches_repo.dart';
import '../../data/seeds/wc2026_matches_seed.dart';
import '../album/nation_detail_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root Copa page
// ─────────────────────────────────────────────────────────────────────────────

class CopaPage extends ConsumerStatefulWidget {
  const CopaPage({super.key});
  @override
  ConsumerState<CopaPage> createState() => _CopaPageState();
}

class _CopaPageState extends ConsumerState<CopaPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Copa do Mundo 2026'),
        bottom: TabBar(
          controller: _tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Grupos'),
            Tab(text: 'Jogos'),
            Tab(text: 'Chaveamento'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _GroupsTab(),
          _MatchesTab(),
          _BracketTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TeamFlag extends StatelessWidget {
  final String code;
  final double size;
  const _TeamFlag({required this.code, this.size = 28});

  Widget _fallback(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.7,
      decoration: BoxDecoration(
        color: context.fc.cardAlt,
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      child: Text(code,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iso = paniniToIso2[code];
    if (iso == null) return _fallback(context);
    // Defensive: CountryFlag has crashed in release on some ARM tablets when
    // its asset lookup fails. Wrap in try/catch + ErrorWidget builder so a
    // single bad flag can't tank the whole Matches list.
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: CountryFlag.fromCountryCode(iso, width: size, height: size * 0.7),
      );
    } catch (_) {
      return _fallback(context);
    }
  }
}

class _LiveBadge extends StatelessWidget {
  final int? minute;
  const _LiveBadge({this.minute});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        minute != null ? 'AO VIVO ${minute}\'' : 'AO VIVO',
        style: const TextStyle(
          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.3),
      ),
    );
  }
}

// Locale-free helpers — no intl dependency needed
String _hhmm(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

String _ddmm(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';

const _weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

String _formatKickoff(DateTime utc) {
  final local = utc.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final matchDay = DateTime(local.year, local.month, local.day);
  final diff = matchDay.difference(today).inDays;
  final time = _hhmm(local);
  if (diff == 0) return 'Hoje • $time';
  if (diff == 1) return 'Amanhã • $time';
  if (diff == -1) return 'Ontem • $time';
  return '${_ddmm(local)} • $time';
}

/// Group header key: "Qui, 11/06" style — no locale required
String _groupKey(DateTime local) {
  final wd = _weekdays[local.weekday - 1];
  return '$wd, ${_ddmm(local)}';
}

// ─────────────────────────────────────────────────────────────────────────────
// GROUPS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _GroupsTab extends ConsumerWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(copaMatchesProvider);
    final matches = matchesAsync.valueOrNull ?? WC2026Matches.all;

    final nextMatch = ref.read(matchesRepoProvider).nextMatch();
    final liveMatches = ref.read(matchesRepoProvider).liveMatches();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(copaMatchesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          // Featured: live game or next upcoming match
          if (liveMatches.isNotEmpty)
            _FeaturedMatch(match: liveMatches.first, isLive: true)
          else if (nextMatch != null)
            _FeaturedMatch(match: nextMatch, isLive: false),
          const SizedBox(height: 16),

          // Group grid 2 columns
          for (var i = 0; i < WC2026Matches.groupTeams.length; i += 2) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _GroupCard(
                    letter: WC2026Matches.groupTeams.keys.elementAt(i),
                    matches: matches,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _GroupCard(
                    letter: WC2026Matches.groupTeams.keys.elementAt(i + 1),
                    matches: matches,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _FeaturedMatch extends StatelessWidget {
  final CopaMatch match;
  final bool isLive;
  const _FeaturedMatch({required this.match, required this.isLive});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.card, c.cardAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.accent.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: c.accent.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                match.displayRound,
                style: TextStyle(
                    color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
              ),
              const Spacer(),
              if (isLive) _LiveBadge(minute: match.liveMinute)
              else Text(
                _formatKickoff(match.kickoff),
                style: TextStyle(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _TeamFlag(code: match.home.code, size: 48),
                    const SizedBox(height: 6),
                    Text(match.home.code,
                        style: TextStyle(
                          color: c.text, fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  isLive || match.status == MatchStatus.finished
                      ? '${match.homeScore ?? 0}  –  ${match.awayScore ?? 0}'
                      : 'x',
                  style: TextStyle(
                      color: c.text, fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _TeamFlag(code: match.away.code, size: 48),
                    const SizedBox(height: 6),
                    Text(match.away.code,
                        style: TextStyle(
                          color: c.text, fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${match.venue} · ${match.city}',
              style: TextStyle(color: c.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String letter;
  final List<CopaMatch> matches;
  const _GroupCard({required this.letter, required this.matches});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final teamCodes = WC2026Matches.groupTeams[letter]!;
    final teams = teamCodes
        .map((cc) => CopaTeam(code: cc, name: WC2026Matches.all
            .firstWhere((m) => m.home.code == cc || m.away.code == cc,
                orElse: () => CopaMatch(
                    id: '', kickoff: DateTime.now(), home: CopaTeam(code: cc, name: cc),
                    away: CopaTeam(code: cc, name: cc), status: MatchStatus.scheduled,
                    round: letter, venue: '', city: ''))
            .home.code == cc
            ? WC2026Matches.all
                .firstWhere((m) => m.home.code == cc && m.round == letter)
                .home.name
            : WC2026Matches.all
                .firstWhere((m) => m.away.code == cc && m.round == letter)
                .away.name))
        .toList();
    final groupMatches = matches.where((m) => m.round == letter).toList();
    final standings = computeStandings(teams, groupMatches);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => GroupDetailPage(letter: letter, matches: groupMatches),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 24, height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(letter,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w800, fontSize: 12)),
                ),
                const SizedBox(width: 6),
                Text('Grupo $letter',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: c.text)),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, size: 16, color: c.textMuted),
              ],
            ),
              const SizedBox(height: 8),
              // Mini standings
              for (var i = 0; i < standings.length; i++)
                _MiniStandingRow(
                  rank: i + 1,
                  standing: standings[i],
                  qualified: i < 2,
                ),
            ],
          ),
        ),
    );
  }
}

class _MiniStandingRow extends StatelessWidget {
  final int rank;
  final CopaStanding standing;
  final bool qualified;
  const _MiniStandingRow({required this.rank, required this.standing, required this.qualified});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$rank', style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: qualified ? c.accent : c.textMuted,
          )),
          const SizedBox(width: 4),
          _TeamFlag(code: standing.team.code, size: 18),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              standing.team.code,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('${standing.points}',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: qualified ? c.accent : null,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GROUP DETAIL PAGE
// ─────────────────────────────────────────────────────────────────────────────

class GroupDetailPage extends StatelessWidget {
  final String letter;
  final List<CopaMatch> matches;
  const GroupDetailPage({super.key, required this.letter, required this.matches});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final teamCodes = WC2026Matches.groupTeams[letter]!;
    final teams = teamCodes.map((cc) {
      final m = matches.firstWhere(
        (m) => m.home.code == cc || m.away.code == cc,
        orElse: () => matches.first,
      );
      return m.home.code == cc ? m.home : m.away;
    }).toList();
    final standings = computeStandings(teams, matches);
    final played = matches.where((m) => m.status != MatchStatus.scheduled).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Grupo $letter')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Team tiles — tap to see stickers ──────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('SELEÇÕES',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: c.textMuted.withValues(alpha: 0.8),
                )),
          ),
          Row(
            children: [
              for (final team in teams) ...[
                if (teams.indexOf(team) > 0) const SizedBox(width: 8),
                Expanded(child: _TeamTile(team: team)),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Full standings table
          Container(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text('A classificação',
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w800,
                        color: c.accent,
                      )),
                  const SizedBox(height: 10),
                  _StandingHeader(),
                  const Divider(height: 12),
                  for (var i = 0; i < standings.length; i++)
                    _StandingRow(
                      rank: i + 1,
                      standing: standings[i],
                      qualified: i < 2,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          if (played.isNotEmpty) ...[
            Text('Jogos • ${played.length} de ${matches.length}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textMuted)),
            const SizedBox(height: 8),
            for (final m in matches) _MatchRow(match: m),
          ],
        ],
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  final CopaTeam team;
  const _TeamTile({required this.team});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => NationDetailPage(code: team.code),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TeamFlag(code: team.code, size: 36),
            const SizedBox(height: 6),
            Text(
              team.code,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.text),
            ),
            const SizedBox(height: 2),
            Text(
              team.name,
              style: TextStyle(fontSize: 9, color: c.textMuted),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StandingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.fc.textMuted);
    return Row(
      children: [
        const SizedBox(width: 16),
        Expanded(child: Text('TIME', style: style)),
        SizedBox(width: 24, child: Center(child: Text('P', style: style))),
        SizedBox(width: 24, child: Center(child: Text('G', style: style))),
        SizedBox(width: 24, child: Center(child: Text('E', style: style))),
        SizedBox(width: 24, child: Center(child: Text('D', style: style))),
        SizedBox(width: 28, child: Center(child: Text('SG', style: style))),
        SizedBox(width: 28, child: Center(child: Text('PTS', style: style))),
      ],
    );
  }
}

class _StandingRow extends StatelessWidget {
  final int rank;
  final CopaStanding standing;
  final bool qualified;
  const _StandingRow({required this.rank, required this.standing, required this.qualified});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final textColor = qualified ? c.text : c.textMuted;
    final style = TextStyle(
      fontSize: 13,
      fontWeight: qualified ? FontWeight.w700 : FontWeight.w500,
      color: textColor,
    );
    final sg = standing.goalDiff;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text('$rank',
                style: style.copyWith(
                  color: qualified ? c.accent : c.textMuted,
                  fontSize: 12,
                )),
          ),
          Expanded(
            child: Row(
              children: [
                _TeamFlag(code: standing.team.code, size: 22),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(standing.team.name,
                      style: style, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          SizedBox(width: 24, child: Center(child: Text('${standing.played}', style: style))),
          SizedBox(width: 24, child: Center(child: Text('${standing.won}', style: style))),
          SizedBox(width: 24, child: Center(child: Text('${standing.drawn}', style: style))),
          SizedBox(width: 24, child: Center(child: Text('${standing.lost}', style: style))),
          SizedBox(
            width: 28,
            child: Center(
              child: Text(
                sg >= 0 ? '+$sg' : '$sg',
                style: style.copyWith(
                  color: sg > 0 ? const Color(0xFF2E8F4F) : sg < 0 ? const Color(0xFFE85A3C) : c.textMuted,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Center(
              child: Text(
                '${standing.points}',
                style: style.copyWith(
                  color: qualified ? c.accent : c.textMuted,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  final CopaMatch match;
  const _MatchRow({required this.match});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isLive = match.status == MatchStatus.live;
    final isDone = match.status == MatchStatus.finished;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Text(_formatKickoff(match.kickoff),
              style: TextStyle(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w500)),
          const Spacer(),
          _TeamFlag(code: match.home.code, size: 22),
          const SizedBox(width: 6),
          Text(match.home.code,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isLive
                  ? Colors.red.withValues(alpha: 0.15)
                  : isDone
                      ? c.accent.withValues(alpha: 0.12)
                      : c.cardAlt,
              borderRadius: BorderRadius.circular(6),
              border: isLive
                  ? Border.all(color: Colors.red.withValues(alpha: 0.4))
                  : null,
            ),
            child: Text(
              (isLive || isDone)
                  ? '${match.homeScore ?? 0} – ${match.awayScore ?? 0}'
                  : 'x',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isLive ? Colors.red : isDone ? c.accent : c.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(match.away.code,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
          const SizedBox(width: 6),
          _TeamFlag(code: match.away.code, size: 22),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MATCHES TAB
// ─────────────────────────────────────────────────────────────────────────────

enum _DateFilter { today, tomorrow, week, all }

class _MatchesTab extends StatefulWidget {
  const _MatchesTab();
  @override
  State<_MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends State<_MatchesTab> {
  _DateFilter _filter = _DateFilter.all;

  List<CopaMatch> _filtered() {
    final source = List<CopaMatch>.from(WC2026Matches.all)
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
    if (_filter == _DateFilter.all) return source;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return source.where((m) {
      final d = m.kickoff.toLocal();
      final day = DateTime(d.year, d.month, d.day);
      return switch (_filter) {
        _DateFilter.today    => day == today,
        _DateFilter.tomorrow => day == today.add(const Duration(days: 1)),
        _DateFilter.week     => day.difference(today).inDays >= 0 &&
                                day.difference(today).inDays < 7,
        _DateFilter.all      => true,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final filtered = _filtered();
    final primary = c.accent;

    // Build a flat list of widgets and feed ListView.builder — the previous
    // implementation passed all 73 match cards (with 2 flags each, ~150
    // sub-widgets) as `children` of a non-lazy ListView. On older ARM
    // tablets the eager inflation could OOM, taking the whole app down
    // and leaving SQLite mid-write. The .builder path only inflates
    // visible rows.
    final items = <Widget>[];

    items.add(_buildFilterBar(c, primary));

    if (filtered.isEmpty) {
      items.add(_buildEmpty(c));
    } else {
      String? lastKey;
      for (final m in filtered) {
        final key = _groupKey(m.kickoff.toLocal());
        if (key != lastKey) {
          items.add(_buildDayHeader(key, primary));
          lastKey = key;
        }
        items.add(_FullMatchCard(match: m));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  Widget _buildFilterBar(FigusColors c, Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final entry in const [
              (_DateFilter.today,    'Hoje'),
              (_DateFilter.tomorrow, 'Amanhã'),
              (_DateFilter.week,     'Esta semana'),
              (_DateFilter.all,      'Todos'),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filter = entry.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _filter == entry.$1 ? primary : c.cardAlt,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      entry.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _filter == entry.$1 ? Colors.white : c.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(FigusColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_soccer_rounded, size: 48, color: c.border),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Nenhum jogo neste período',
              style: TextStyle(color: c.textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'A Copa começa em 11 de junho de 2026',
              style: TextStyle(color: c.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeader(String key, Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
      child: Text(
        key,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: primary.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _FullMatchCard extends StatelessWidget {
  final CopaMatch match;
  const _FullMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isLive = match.status == MatchStatus.live;
    final isDone = match.status == MatchStatus.finished;
    final timeStr = _hhmm(match.kickoff.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Time column
          SizedBox(
            width: 44,
            child: Column(
              children: [
                if (isLive)
                  _LiveBadge(minute: match.liveMinute)
                else
                  Text(timeStr,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
                const SizedBox(height: 2),
                Text(match.displayRound,
                    style: TextStyle(fontSize: 9, color: c.textMuted),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Home team
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(match.home.name,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDone && (match.homeScore ?? 0) > (match.awayScore ?? 0)
                            ? c.accent
                            : c.text,
                      ),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 6),
                _TeamFlag(code: match.home.code, size: 26),
              ],
            ),
          ),
          // Score
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isLive
                  ? Colors.red.withValues(alpha: 0.15)
                  : isDone
                      ? c.accent.withValues(alpha: 0.12)
                      : c.cardAlt,
              borderRadius: BorderRadius.circular(8),
              border: isLive
                  ? Border.all(color: Colors.red.withValues(alpha: 0.4))
                  : isDone
                      ? Border.all(color: c.accent.withValues(alpha: 0.3))
                      : null,
            ),
            child: Text(
              isLive || isDone
                  ? '${match.homeScore ?? 0} – ${match.awayScore ?? 0}'
                  : 'x',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isLive ? Colors.red : isDone ? c.accent : c.textMuted,
              ),
            ),
          ),
          // Away team
          Expanded(
            child: Row(
              children: [
                _TeamFlag(code: match.away.code, size: 26),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(match.away.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDone && (match.awayScore ?? 0) > (match.homeScore ?? 0)
                            ? c.accent
                            : c.text,
                      ),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BRACKET TAB (simplified)
// ─────────────────────────────────────────────────────────────────────────────

class _BracketTab extends StatelessWidget {
  const _BracketTab();

  static const _r32 = <(String, String)>[
    ('1° Grupo A', '2° Grupo C'), ('1° Grupo C', '2° Grupo A'),
    ('1° Grupo E', '2° Grupo G'), ('1° Grupo G', '2° Grupo E'),
    ('1° Grupo I', '2° Grupo K'), ('1° Grupo K', '2° Grupo I'),
    ('1° Grupo B', '2° Grupo D'), ('1° Grupo D', '2° Grupo B'),
    ('1° Grupo F', '2° Grupo H'), ('1° Grupo H', '2° Grupo F'),
    ('1° Grupo J', '2° Grupo L'), ('1° Grupo L', '2° Grupo J'),
    ('3° lugar (G1)', '3° lugar (G2)'), ('3° lugar (G3)', '3° lugar (G4)'),
    ('3° lugar (G5)', '3° lugar (G6)'), ('3° lugar (G7)', '3° lugar (G8)'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
      children: [
        _RoundSection(
          title: 'Oitavas de final',
          subtitle: '4–8 jul • 16 jogos',
          matches: [for (final m in _r32) _BracketMatch(home: m.$1, away: m.$2)],
        ),
        const SizedBox(height: 16),
        _RoundSection(
          title: 'Quartas de final',
          subtitle: '11–12 jul • 8 jogos',
          matches: List.generate(8, (i) => const _BracketMatch(home: 'A definir', away: 'A definir')),
          pending: true,
        ),
        const SizedBox(height: 16),
        _RoundSection(
          title: 'Semifinais',
          subtitle: '15–16 jul • 4 jogos',
          matches: List.generate(4, (i) => const _BracketMatch(home: 'A definir', away: 'A definir')),
          pending: true,
        ),
        const SizedBox(height: 16),
        _RoundSection(
          title: 'Final',
          subtitle: '19 jul • MetLife Stadium, Nova Jersey',
          matches: const [_BracketMatch(home: 'A definir', away: 'A definir')],
          pending: true,
        ),
      ],
    );
  }
}

class _BracketMatch {
  final String home;
  final String away;
  const _BracketMatch({required this.home, required this.away});
}

class _RoundSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_BracketMatch> matches;
  final bool pending;
  const _RoundSection({
    required this.title,
    required this.subtitle,
    required this.matches,
    this.pending = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        Text(subtitle, style: TextStyle(fontSize: 12, color: c.textMuted)),
        const SizedBox(height: 8),
        for (var i = 0; i < matches.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _BracketCard(index: i + 1, match: matches[i], pending: pending),
        ],
      ],
    );
  }
}

class _BracketCard extends StatelessWidget {
  final int index;
  final _BracketMatch match;
  final bool pending;
  const _BracketCard({required this.index, required this.match, required this.pending});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isPending = pending || match.home == 'A definir' || match.home.startsWith('1°') || match.home.startsWith('2°') || match.home.startsWith('3°');
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text('$index',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.textMuted)),
            ),
            Expanded(
              child: Text(match.home,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isPending ? c.textMuted : scheme.onSurface,
                  ),
                  textAlign: TextAlign.end),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPending ? c.cardAlt : scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isPending ? 'x' : '–',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isPending ? c.textMuted : scheme.primary,
                ),
              ),
            ),
            Expanded(
              child: Text(match.away,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isPending ? c.textMuted : scheme.onSurface,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
