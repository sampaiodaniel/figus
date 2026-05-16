import '../../core/country_codes.dart';

enum MatchStatus { scheduled, live, finished }

class CopaTeam {
  final String code;
  final String name;
  const CopaTeam({required this.code, required this.name});
}

class CopaMatch {
  final String id;
  final DateTime kickoff;
  final CopaTeam home;
  final CopaTeam away;
  final int? homeScore;
  final int? awayScore;
  final MatchStatus status;
  final int? liveMinute;
  final String round; // "A", "B", … "R32", "QF", "SF", "F", "3rd"
  final String venue;
  final String city;

  const CopaMatch({
    required this.id,
    required this.kickoff,
    required this.home,
    required this.away,
    this.homeScore,
    this.awayScore,
    required this.status,
    this.liveMinute,
    required this.round,
    required this.venue,
    required this.city,
  });

  bool get isGroup => round.length == 1 && round.compareTo('A') >= 0 && round.compareTo('L') <= 0;
  bool get isKnockout => !isGroup;
  String get displayRound => isGroup ? 'Grupo $round' : _knockoutLabel;
  String get _knockoutLabel => switch (round) {
        'R32' => 'Oitavas',
        'QF' => 'Quartas',
        'SF' => 'Semifinal',
        'F' => 'Final',
        '3rd' => '3° lugar',
        _ => round,
      };

  String get scoreLabel {
    if (status == MatchStatus.scheduled) return 'x';
    return '${homeScore ?? 0}  –  ${awayScore ?? 0}';
  }

  CopaMatch copyWith({
    int? homeScore,
    int? awayScore,
    MatchStatus? status,
    int? liveMinute,
  }) =>
      CopaMatch(
        id: id,
        kickoff: kickoff,
        home: home,
        away: away,
        homeScore: homeScore ?? this.homeScore,
        awayScore: awayScore ?? this.awayScore,
        status: status ?? this.status,
        liveMinute: liveMinute ?? this.liveMinute,
        round: round,
        venue: venue,
        city: city,
      );
}

class CopaStanding {
  final CopaTeam team;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int points;

  const CopaStanding({
    required this.team,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.points,
  });

  int get goalDiff => goalsFor - goalsAgainst;

  static CopaStanding zero(CopaTeam team) => CopaStanding(
        team: team,
        played: 0,
        won: 0,
        drawn: 0,
        lost: 0,
        goalsFor: 0,
        goalsAgainst: 0,
        points: 0,
      );
}

/// Derives group standings from a list of finished/live matches for that group.
List<CopaStanding> computeStandings(List<CopaTeam> teams, List<CopaMatch> matches) {
  final map = {for (final t in teams) t.code: CopaStanding.zero(t)};
  for (final m in matches) {
    if (m.status == MatchStatus.scheduled) continue;
    final h = m.homeScore ?? 0;
    final a = m.awayScore ?? 0;
    final home = map[m.home.code];
    final away = map[m.away.code];
    if (home == null || away == null) continue;

    final homePoints = h > a ? 3 : (h == a ? 1 : 0);
    final awayPoints = a > h ? 3 : (h == a ? 1 : 0);

    map[m.home.code] = CopaStanding(
      team: home.team,
      played: home.played + 1,
      won: home.won + (h > a ? 1 : 0),
      drawn: home.drawn + (h == a ? 1 : 0),
      lost: home.lost + (h < a ? 1 : 0),
      goalsFor: home.goalsFor + h,
      goalsAgainst: home.goalsAgainst + a,
      points: home.points + homePoints,
    );
    map[m.away.code] = CopaStanding(
      team: away.team,
      played: away.played + 1,
      won: away.won + (a > h ? 1 : 0),
      drawn: away.drawn + (h == a ? 1 : 0),
      lost: away.lost + (a < h ? 1 : 0),
      goalsFor: away.goalsFor + a,
      goalsAgainst: away.goalsAgainst + h,
      points: away.points + awayPoints,
    );
  }
  final list = map.values.toList()
    ..sort((a, b) {
      final pts = b.points.compareTo(a.points);
      if (pts != 0) return pts;
      final sg = b.goalDiff.compareTo(a.goalDiff);
      if (sg != 0) return sg;
      return b.goalsFor.compareTo(a.goalsFor);
    });
  return list;
}

/// Returns ISO 3166-1 alpha-2 for a given Panini code (for flag rendering).
String? flagCode(String paniniCode) => paniniToIso2[paniniCode];
