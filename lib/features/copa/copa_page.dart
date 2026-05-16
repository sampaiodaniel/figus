import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

import '../../core/country_codes.dart';
import '../../core/theme/app_theme.dart';

class CopaPage extends StatelessWidget {
  const CopaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Copa do Mundo 2026'),
          bottom: const TabBar(
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
            indicatorColor: AppTheme.seed,
            labelColor: AppTheme.seed,
            unselectedLabelColor: AppTheme.inkSoft,
            tabs: [
              Tab(text: 'Grupos'),
              Tab(text: 'Chaveamento'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GroupsTab(),
            _BracketTab(),
          ],
        ),
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _Team {
  final String code;
  final String name;
  const _Team(this.code, this.name);
}

class _Group {
  final String letter;
  final List<_Team> teams;
  const _Group(this.letter, this.teams);
}

const _groups = <_Group>[
  _Group('A', [
    _Team('MEX', 'México'),
    _Team('RSA', 'África do Sul'),
    _Team('KOR', 'Coreia do Sul'),
    _Team('CZE', 'Tchéquia'),
  ]),
  _Group('B', [
    _Team('CAN', 'Canadá'),
    _Team('BIH', 'Bósnia e Herzegovina'),
    _Team('QAT', 'Catar'),
    _Team('SUI', 'Suíça'),
  ]),
  _Group('C', [
    _Team('BRA', 'Brasil'),
    _Team('MAR', 'Marrocos'),
    _Team('HAI', 'Haiti'),
    _Team('SCO', 'Escócia'),
  ]),
  _Group('D', [
    _Team('USA', 'EUA'),
    _Team('PAR', 'Paraguai'),
    _Team('AUS', 'Austrália'),
    _Team('TUR', 'Turquia'),
  ]),
  _Group('E', [
    _Team('GER', 'Alemanha'),
    _Team('CUW', 'Curaçao'),
    _Team('CIV', 'Costa do Marfim'),
    _Team('ECU', 'Equador'),
  ]),
  _Group('F', [
    _Team('NED', 'Holanda'),
    _Team('JPN', 'Japão'),
    _Team('SWE', 'Suécia'),
    _Team('TUN', 'Tunísia'),
  ]),
  _Group('G', [
    _Team('BEL', 'Bélgica'),
    _Team('EGY', 'Egito'),
    _Team('IRN', 'Irã'),
    _Team('NZL', 'Nova Zelândia'),
  ]),
  _Group('H', [
    _Team('ESP', 'Espanha'),
    _Team('CPV', 'Cabo Verde'),
    _Team('KSA', 'Arábia Saudita'),
    _Team('URU', 'Uruguai'),
  ]),
  _Group('I', [
    _Team('FRA', 'França'),
    _Team('SEN', 'Senegal'),
    _Team('IRQ', 'Iraque'),
    _Team('NOR', 'Noruega'),
  ]),
  _Group('J', [
    _Team('ARG', 'Argentina'),
    _Team('ALG', 'Argélia'),
    _Team('AUT', 'Áustria'),
    _Team('JOR', 'Jordânia'),
  ]),
  _Group('K', [
    _Team('POR', 'Portugal'),
    _Team('COD', 'Rep. Dem. do Congo'),
    _Team('UZB', 'Uzbequistão'),
    _Team('COL', 'Colômbia'),
  ]),
  _Group('L', [
    _Team('ENG', 'Inglaterra'),
    _Team('CRO', 'Croácia'),
    _Team('GHA', 'Gana'),
    _Team('PAN', 'Panamá'),
  ]),
];

// R32 bracket: 16 matches with labeled slots. Adjacent pairs feed R16.
const _r32 = <(String, String)>[
  ('1° Grupo A', '2° Grupo C'),
  ('1° Grupo C', '2° Grupo A'),
  ('1° Grupo E', '2° Grupo G'),
  ('1° Grupo G', '2° Grupo E'),
  ('1° Grupo I', '2° Grupo K'),
  ('1° Grupo K', '2° Grupo I'),
  ('1° Grupo B', '2° Grupo D'),
  ('1° Grupo D', '2° Grupo B'),
  ('1° Grupo F', '2° Grupo H'),
  ('1° Grupo H', '2° Grupo F'),
  ('1° Grupo J', '2° Grupo L'),
  ('1° Grupo L', '2° Grupo J'),
  ('3° lugar (G1)', '3° lugar (G2)'),
  ('3° lugar (G3)', '3° lugar (G4)'),
  ('3° lugar (G5)', '3° lugar (G6)'),
  ('3° lugar (G7)', '3° lugar (G8)'),
];

// ── Groups tab ────────────────────────────────────────────────────────────────

class _GroupsTab extends StatelessWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: _groups.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _GroupCard(group: _groups[i]),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final _Group group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.seed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    group.letter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Grupo ${group.letter}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            for (final team in group.teams) ...[
              const SizedBox(height: 10),
              _TeamRow(team: team, scheme: scheme),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final _Team team;
  final ColorScheme scheme;
  const _TeamRow({required this.team, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final iso = paniniToIso2[team.code];
    return Row(
      children: [
        SizedBox(
          width: 36,
          height: 26,
          child: iso == null
              ? Container(
                  decoration: BoxDecoration(
                    color: AppTheme.slotSoft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: const Text('?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.inkSoft)),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CountryFlag.fromCountryCode(iso, width: 36, height: 26),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: team.name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface),
                ),
                TextSpan(
                  text: '  (${team.code})',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: scheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bracket tab ───────────────────────────────────────────────────────────────

class _BracketTab extends StatelessWidget {
  const _BracketTab();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          _RoundTabBar(),
          const Expanded(child: _RoundTabBarView()),
        ],
      ),
    );
  }
}

class _RoundTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: const TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        indicatorColor: AppTheme.seed,
        labelColor: AppTheme.seed,
        unselectedLabelColor: AppTheme.inkSoft,
        tabs: [
          Tab(text: 'Oitavas'),
          Tab(text: 'Quartas'),
          Tab(text: 'Semis'),
          Tab(text: 'Final'),
          Tab(text: '3° lugar'),
        ],
      ),
    );
  }
}

class _RoundTabBarView extends StatelessWidget {
  const _RoundTabBarView();

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        _MatchList(
          title: 'Oitavas de final',
          subtitle: '16 jogos • classificados pela fase de grupos',
          matches: [for (final m in _r32) _MatchData(m.$1, m.$2)],
        ),
        const _MatchList(
          title: 'Quartas de final',
          subtitle: '8 jogos',
          matches: [],
          empty: true,
        ),
        const _MatchList(
          title: 'Semifinais',
          subtitle: '4 jogos',
          matches: [],
          empty: true,
        ),
        const _MatchList(
          title: 'Final',
          subtitle: '19 de julho de 2026 • MetLife Stadium, Nova Jersey',
          matches: [_MatchData('A definir', 'A definir')],
        ),
        const _MatchList(
          title: '3° lugar',
          subtitle: '19 de julho de 2026',
          matches: [_MatchData('A definir', 'A definir')],
        ),
      ],
    );
  }
}

class _MatchData {
  final String home;
  final String away;
  const _MatchData(this.home, this.away);
}

class _MatchList extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_MatchData> matches;
  final bool empty;
  const _MatchList({
    required this.title,
    required this.subtitle,
    required this.matches,
    this.empty = false,
  });

  @override
  Widget build(BuildContext context) {
    if (empty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule_rounded, size: 48, color: AppTheme.slot),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: AppTheme.inkSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Disponível após as fases anteriores',
              style: TextStyle(fontSize: 12, color: AppTheme.slot),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
            ],
          ),
        ),
        for (var i = 0; i < matches.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _MatchCard(index: i + 1, match: matches[i]),
        ],
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final int index;
  final _MatchData match;
  const _MatchCard({required this.index, required this.match});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPending = match.home == 'A definir' || match.home.startsWith('1°') || match.home.startsWith('2°') || match.home.startsWith('3°');
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.inkSoft,
                ),
              ),
            ),
            Expanded(
              child: Text(
                match.home,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPending ? AppTheme.inkSoft : scheme.onSurface,
                ),
                textAlign: TextAlign.end,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPending ? AppTheme.slotSoft : AppTheme.seed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isPending ? 'x' : '—',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isPending ? AppTheme.slot : AppTheme.seed,
                ),
              ),
            ),
            Expanded(
              child: Text(
                match.away,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPending ? AppTheme.inkSoft : scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
