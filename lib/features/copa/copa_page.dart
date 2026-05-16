import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/country_codes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/copa_models.dart';
import '../../data/repos/matches_repo.dart';
import '../../data/seeds/wc2026_matches_seed.dart';

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

  @override
  Widget build(BuildContext context) {
    final iso = paniniToIso2[code];
    if (iso == null) {
      return Container(
        width: size, height: size * 0.7,
        decoration: BoxDecoration(
          color: AppTheme.slotSoft,
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.center,
        child: Text(code, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: CountryFlag.fromCountryCode(iso, width: size, height: size * 0.7),
    );
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

String _formatKickoff(DateTime utc) {
  final local = utc.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final matchDay = DateTime(local.year, local.month, local.day);
  final diff = matchDay.difference(today).inDays;

  final time = DateFormat('HH:mm').format(local);
  if (diff == 0) return 'Hoje • $time';
  if (diff == 1) return 'Amanhã • $time';
  if (diff == -1) return 'Ontem • $time';
  return '${DateFormat('dd/MM').format(local)} • $time';
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                match.displayRound,
                style: const TextStyle(
                  color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
              ),
              const Spacer(),
              if (isLive) _LiveBadge(minute: match.liveMinute)
              else Text(
                _formatKickoff(match.kickoff),
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
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
                        style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isLive || match.status == MatchStatus.finished
                      ? '${match.homeScore ?? 0}  –  ${match.awayScore ?? 0}'
                      : 'x',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _TeamFlag(code: match.away.code, size: 48),
                    const SizedBox(height: 6),
                    Text(match.away.code,
                        style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${match.venue} · ${match.city}',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
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
    final teamCodes = WC2026Matches.groupTeams[letter]!;
    final teams = teamCodes
        .map((c) => CopaTeam(code: c, name: WC2026Matches.all
            .firstWhere((m) => m.home.code == c || m.away.code == c,
                orElse: () => CopaMatch(
                    id: '', kickoff: DateTime.now(), home: CopaTeam(code: c, name: c),
                    away: CopaTeam(code: c, name: c), status: MatchStatus.scheduled,
                    round: letter, venue: '', city: ''))
            .home.code == c
            ? WC2026Matches.all
                .firstWhere((m) => m.home.code == c && m.round == letter)
                .home.name
            : WC2026Matches.all
                .firstWhere((m) => m.away.code == c && m.round == letter)
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
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
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
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(letter,
                        style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  const SizedBox(width: 6),
                  Text('Grupo $letter',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.inkSoft),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$rank', style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: qualified ? Theme.of(context).colorScheme.primary : AppTheme.inkSoft,
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
                color: qualified ? Theme.of(context).colorScheme.primary : null,
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
    final teamCodes = WC2026Matches.groupTeams[letter]!;
    final teams = teamCodes.map((c) {
      final m = matches.firstWhere(
        (m) => m.home.code == c || m.away.code == c,
        orElse: () => matches.first,
      );
      return m.home.code == c ? m.home : m.away;
    }).toList();
    final standings = computeStandings(teams, matches);
    final played = matches.where((m) => m.status != MatchStatus.scheduled).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Grupo $letter')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Full standings table
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('A classificação',
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      )),
                  const SizedBox(height: 10),
                  // Table header
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
          ),
          const SizedBox(height: 16),

          if (played.isNotEmpty) ...[
            Text('Jogos • ${played.length} de ${matches.length}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.inkSoft)),
            const SizedBox(height: 8),
            for (final m in matches) _MatchRow(match: m),
          ],
        ],
      ),
    );
  }
}

class _StandingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.inkSoft);
    return Row(
      children: const [
        SizedBox(width: 16),
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
    final primary = Theme.of(context).colorScheme.primary;
    final style = TextStyle(
      fontSize: 13,
      fontWeight: qualified ? FontWeight.w700 : FontWeight.w500,
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
                  color: qualified ? primary : AppTheme.inkSoft,
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
                  color: sg > 0 ? const Color(0xFF22C58A) : sg < 0 ? Colors.red : null,
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
                  color: qualified ? primary : null,
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
    final isLive = match.status == MatchStatus.live;
    final isDone = match.status == MatchStatus.finished;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Text(_formatKickoff(match.kickoff),
                style: const TextStyle(fontSize: 11, color: AppTheme.inkSoft, fontWeight: FontWeight.w500)),
            const Spacer(),
            _TeamFlag(code: match.home.code, size: 22),
            const SizedBox(width: 6),
            Text(match.home.code,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            if (isLive || isDone)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLive ? Colors.red.withValues(alpha: 0.1) : AppTheme.slotSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${match.homeScore ?? 0} – ${match.awayScore ?? 0}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isLive ? Colors.red : null,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.slotSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('x', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.inkSoft)),
              ),
            const SizedBox(width: 10),
            Text(match.away.code,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            _TeamFlag(code: match.away.code, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MATCHES TAB
// ─────────────────────────────────────────────────────────────────────────────

enum _DateFilter { today, tomorrow, week, all }

class _MatchesTab extends ConsumerStatefulWidget {
  const _MatchesTab();
  @override
  ConsumerState<_MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends ConsumerState<_MatchesTab> {
  _DateFilter _filter = _DateFilter.today;

  List<CopaMatch> _filtered(List<CopaMatch> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_filter) {
      _DateFilter.today => all
          .where((m) {
            final d = m.kickoff.toLocal();
            return DateTime(d.year, d.month, d.day) == today;
          })
          .toList(),
      _DateFilter.tomorrow => all
          .where((m) {
            final d = m.kickoff.toLocal();
            return DateTime(d.year, d.month, d.day) == today.add(const Duration(days: 1));
          })
          .toList(),
      _DateFilter.week => all
          .where((m) {
            final d = m.kickoff.toLocal();
            final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
            return diff >= 0 && diff < 7;
          })
          .toList(),
      _DateFilter.all => all,
    };
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(copaMatchesProvider);
    final allMatches = matchesAsync.valueOrNull ?? WC2026Matches.all;
    final filtered = _filtered(allMatches)
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));

    return Column(
      children: [
        // Filter bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: [
              for (final (f, label) in [
                (_DateFilter.today, 'Hoje'),
                (_DateFilter.tomorrow, 'Amanhã'),
                (_DateFilter.week, 'Esta semana'),
                (_DateFilter.all, 'Todos'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: _filter == f,
                    label: Text(label),
                    onSelected: (_) => setState(() => _filter = f),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _filter == f ? Colors.white : AppTheme.inkSoft,
                    ),
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: AppTheme.slotSoft,
                    showCheckmark: false,
                    side: BorderSide.none,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sports_soccer_rounded, size: 48, color: AppTheme.slot),
                      SizedBox(height: 12),
                      Text('Nenhum jogo neste período',
                          style: TextStyle(color: AppTheme.inkSoft)),
                    ],
                  ),
                )
              : _GroupedMatchList(matches: filtered),
        ),
      ],
    );
  }
}

class _GroupedMatchList extends StatelessWidget {
  final List<CopaMatch> matches;
  const _GroupedMatchList({required this.matches});

  @override
  Widget build(BuildContext context) {
    // Group by date
    final byDate = <String, List<CopaMatch>>{};
    for (final m in matches) {
      final local = m.kickoff.toLocal();
      final key = DateFormat('EEEE, dd/MM', 'pt_BR').format(local);
      (byDate[key] ??= []).add(m);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      children: [
        for (final entry in byDate.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
            child: Text(
              entry.key.substring(0, 1).toUpperCase() + entry.key.substring(1),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.inkSoft),
            ),
          ),
          for (final m in entry.value) _FullMatchCard(match: m),
        ],
      ],
    );
  }
}

class _FullMatchCard extends StatelessWidget {
  final CopaMatch match;
  const _FullMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final isLive = match.status == MatchStatus.live;
    final isDone = match.status == MatchStatus.finished;
    final timeStr = DateFormat('HH:mm').format(match.kickoff.toLocal());
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
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
                        style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.inkSoft)),
                  const SizedBox(height: 2),
                  Text(match.displayRound,
                      style: const TextStyle(fontSize: 9, color: AppTheme.inkSoft),
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
                              ? scheme.primary
                              : null,
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
                    ? Colors.red.withValues(alpha: 0.1)
                    : isDone
                        ? scheme.primary.withValues(alpha: 0.1)
                        : AppTheme.slotSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isLive || isDone
                    ? '${match.homeScore ?? 0} – ${match.awayScore ?? 0}'
                    : 'x',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isLive
                      ? Colors.red
                      : isDone
                          ? scheme.primary
                          : AppTheme.inkSoft,
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
                              ? scheme.primary
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
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
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.inkSoft)),
            ),
            Expanded(
              child: Text(match.home,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isPending ? AppTheme.inkSoft : scheme.onSurface,
                  ),
                  textAlign: TextAlign.end),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPending ? AppTheme.slotSoft : scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isPending ? 'x' : '–',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isPending ? AppTheme.inkSoft : scheme.primary,
                ),
              ),
            ),
            Expanded(
              child: Text(match.away,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isPending ? AppTheme.inkSoft : scheme.onSurface,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
