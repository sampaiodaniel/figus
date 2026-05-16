import '../models/copa_models.dart';

/// Full WC2026 group stage schedule (official FIFA draw, June 11 – July 1 2026).
/// All times in UTC-3 (Brasília time) converted to UTC for storage.
/// Knockout stage slots filled in as results become known.
class WC2026Matches {
  WC2026Matches._();

  static const _teams = <String, CopaTeam>{
    'MEX': CopaTeam(code: 'MEX', name: 'México'),
    'RSA': CopaTeam(code: 'RSA', name: 'África do Sul'),
    'KOR': CopaTeam(code: 'KOR', name: 'Coreia do Sul'),
    'CZE': CopaTeam(code: 'CZE', name: 'Tchéquia'),
    'CAN': CopaTeam(code: 'CAN', name: 'Canadá'),
    'BIH': CopaTeam(code: 'BIH', name: 'Bósnia-Herzegovina'),
    'QAT': CopaTeam(code: 'QAT', name: 'Catar'),
    'SUI': CopaTeam(code: 'SUI', name: 'Suíça'),
    'BRA': CopaTeam(code: 'BRA', name: 'Brasil'),
    'MAR': CopaTeam(code: 'MAR', name: 'Marrocos'),
    'HAI': CopaTeam(code: 'HAI', name: 'Haiti'),
    'SCO': CopaTeam(code: 'SCO', name: 'Escócia'),
    'USA': CopaTeam(code: 'USA', name: 'EUA'),
    'PAR': CopaTeam(code: 'PAR', name: 'Paraguai'),
    'AUS': CopaTeam(code: 'AUS', name: 'Austrália'),
    'TUR': CopaTeam(code: 'TUR', name: 'Turquia'),
    'GER': CopaTeam(code: 'GER', name: 'Alemanha'),
    'CUW': CopaTeam(code: 'CUW', name: 'Curaçao'),
    'CIV': CopaTeam(code: 'CIV', name: 'Costa do Marfim'),
    'ECU': CopaTeam(code: 'ECU', name: 'Equador'),
    'NED': CopaTeam(code: 'NED', name: 'Holanda'),
    'JPN': CopaTeam(code: 'JPN', name: 'Japão'),
    'SWE': CopaTeam(code: 'SWE', name: 'Suécia'),
    'TUN': CopaTeam(code: 'TUN', name: 'Tunísia'),
    'BEL': CopaTeam(code: 'BEL', name: 'Bélgica'),
    'EGY': CopaTeam(code: 'EGY', name: 'Egito'),
    'IRN': CopaTeam(code: 'IRN', name: 'Irã'),
    'NZL': CopaTeam(code: 'NZL', name: 'Nova Zelândia'),
    'ESP': CopaTeam(code: 'ESP', name: 'Espanha'),
    'CPV': CopaTeam(code: 'CPV', name: 'Cabo Verde'),
    'KSA': CopaTeam(code: 'KSA', name: 'Arábia Saudita'),
    'URU': CopaTeam(code: 'URU', name: 'Uruguai'),
    'FRA': CopaTeam(code: 'FRA', name: 'França'),
    'SEN': CopaTeam(code: 'SEN', name: 'Senegal'),
    'IRQ': CopaTeam(code: 'IRQ', name: 'Iraque'),
    'NOR': CopaTeam(code: 'NOR', name: 'Noruega'),
    'ARG': CopaTeam(code: 'ARG', name: 'Argentina'),
    'ALG': CopaTeam(code: 'ALG', name: 'Argélia'),
    'AUT': CopaTeam(code: 'AUT', name: 'Áustria'),
    'JOR': CopaTeam(code: 'JOR', name: 'Jordânia'),
    'POR': CopaTeam(code: 'POR', name: 'Portugal'),
    'COD': CopaTeam(code: 'COD', name: 'Rep. D. Congo'),
    'UZB': CopaTeam(code: 'UZB', name: 'Uzbequistão'),
    'COL': CopaTeam(code: 'COL', name: 'Colômbia'),
    'ENG': CopaTeam(code: 'ENG', name: 'Inglaterra'),
    'CRO': CopaTeam(code: 'CRO', name: 'Croácia'),
    'GHA': CopaTeam(code: 'GHA', name: 'Gana'),
    'PAN': CopaTeam(code: 'PAN', name: 'Panamá'),
  };

  static CopaTeam t(String code) => _teams[code]!;

  static const groupTeams = <String, List<String>>{
    'A': ['MEX', 'RSA', 'KOR', 'CZE'],
    'B': ['CAN', 'BIH', 'QAT', 'SUI'],
    'C': ['BRA', 'MAR', 'HAI', 'SCO'],
    'D': ['USA', 'PAR', 'AUS', 'TUR'],
    'E': ['GER', 'CUW', 'CIV', 'ECU'],
    'F': ['NED', 'JPN', 'SWE', 'TUN'],
    'G': ['BEL', 'EGY', 'IRN', 'NZL'],
    'H': ['ESP', 'CPV', 'KSA', 'URU'],
    'I': ['FRA', 'SEN', 'IRQ', 'NOR'],
    'J': ['ARG', 'ALG', 'AUT', 'JOR'],
    'K': ['POR', 'COD', 'UZB', 'COL'],
    'L': ['ENG', 'CRO', 'GHA', 'PAN'],
  };

  static DateTime _dt(int month, int day, int hour, int minute) =>
      DateTime.utc(2026, month, day, hour, minute);

  static CopaMatch _m(
    String id,
    String group,
    String home,
    String away,
    DateTime kickoff,
    String venue,
    String city,
  ) =>
      CopaMatch(
        id: id,
        kickoff: kickoff,
        home: t(home),
        away: t(away),
        status: MatchStatus.scheduled,
        round: group,
        venue: venue,
        city: city,
      );

  // ── Group stage seed ──────────────────────────────────────────────────────
  // Rodada 1 (Jun 11–14)
  // Rodada 2 (Jun 15–18)
  // Rodada 3 (Jun 22–26)
  // Times are UTC; Brasília = UTC-3

  static final List<CopaMatch> all = [
    // Grupo A
    _m('A1', 'A', 'MEX', 'RSA', _dt(6, 11, 23, 0), 'Estadio Azteca', 'Cidade do México'),
    _m('A2', 'A', 'KOR', 'CZE', _dt(6, 12, 2, 0), 'SoFi Stadium', 'Los Angeles'),
    _m('A3', 'A', 'MEX', 'KOR', _dt(6, 15, 23, 0), 'Estadio Azteca', 'Cidade do México'),
    _m('A4', 'A', 'CZE', 'RSA', _dt(6, 16, 2, 0), 'Rose Bowl', 'Los Angeles'),
    _m('A5', 'A', 'CZE', 'MEX', _dt(6, 22, 22, 0), 'AT&T Stadium', 'Dallas'),
    _m('A6', 'A', 'RSA', 'KOR', _dt(6, 22, 22, 0), 'NRG Stadium', 'Houston'),

    // Grupo B
    _m('B1', 'B', 'CAN', 'BIH', _dt(6, 12, 23, 0), 'BC Place', 'Vancouver'),
    _m('B2', 'B', 'QAT', 'SUI', _dt(6, 13, 2, 0), 'Levi\'s Stadium', 'San Francisco'),
    _m('B3', 'B', 'CAN', 'QAT', _dt(6, 16, 23, 0), 'BC Place', 'Vancouver'),
    _m('B4', 'B', 'SUI', 'BIH', _dt(6, 17, 2, 0), 'Gillette Stadium', 'Boston'),
    _m('B5', 'B', 'SUI', 'CAN', _dt(6, 23, 22, 0), 'MetLife Stadium', 'Nova York'),
    _m('B6', 'B', 'BIH', 'QAT', _dt(6, 23, 22, 0), 'Mercedes-Benz Stadium', 'Atlanta'),

    // Grupo C
    _m('C1', 'C', 'BRA', 'MAR', _dt(6, 13, 23, 0), 'Hard Rock Stadium', 'Miami'),
    _m('C2', 'C', 'HAI', 'SCO', _dt(6, 14, 2, 0), 'State Farm Stadium', 'Phoenix'),
    _m('C3', 'C', 'BRA', 'HAI', _dt(6, 17, 23, 0), 'Hard Rock Stadium', 'Miami'),
    _m('C4', 'C', 'SCO', 'MAR', _dt(6, 18, 2, 0), 'Arrowhead Stadium', 'Kansas City'),
    _m('C5', 'C', 'SCO', 'BRA', _dt(6, 24, 22, 0), 'Lincoln Financial Field', 'Filadélfia'),
    _m('C6', 'C', 'MAR', 'HAI', _dt(6, 24, 22, 0), 'Empower Field', 'Denver'),

    // Grupo D
    _m('D1', 'D', 'USA', 'PAR', _dt(6, 14, 23, 0), 'MetLife Stadium', 'Nova York'),
    _m('D2', 'D', 'AUS', 'TUR', _dt(6, 15, 2, 0), 'SoFi Stadium', 'Los Angeles'),
    _m('D3', 'D', 'USA', 'AUS', _dt(6, 18, 23, 0), 'AT&T Stadium', 'Dallas'),
    _m('D4', 'D', 'TUR', 'PAR', _dt(6, 19, 2, 0), 'Allegiant Stadium', 'Las Vegas'),
    _m('D5', 'D', 'TUR', 'USA', _dt(6, 25, 22, 0), 'Arrowhead Stadium', 'Kansas City'),
    _m('D6', 'D', 'PAR', 'AUS', _dt(6, 25, 22, 0), 'Lumen Field', 'Seattle'),

    // Grupo E
    _m('E1', 'E', 'GER', 'CUW', _dt(6, 15, 19, 0), 'Mercedes-Benz Stadium', 'Atlanta'),
    _m('E2', 'E', 'CIV', 'ECU', _dt(6, 15, 22, 0), 'NRG Stadium', 'Houston'),
    _m('E3', 'E', 'GER', 'CIV', _dt(6, 19, 19, 0), 'Lincoln Financial Field', 'Filadélfia'),
    _m('E4', 'E', 'ECU', 'CUW', _dt(6, 19, 22, 0), 'Gillette Stadium', 'Boston'),
    _m('E5', 'E', 'ECU', 'GER', _dt(6, 26, 21, 0), 'BC Place', 'Vancouver'),
    _m('E6', 'E', 'CUW', 'CIV', _dt(6, 26, 21, 0), 'Rose Bowl', 'Los Angeles'),

    // Grupo F
    _m('F1', 'F', 'NED', 'JPN', _dt(6, 16, 19, 0), 'Levi\'s Stadium', 'San Francisco'),
    _m('F2', 'F', 'SWE', 'TUN', _dt(6, 16, 22, 0), 'State Farm Stadium', 'Phoenix'),
    _m('F3', 'F', 'NED', 'SWE', _dt(6, 20, 19, 0), 'MetLife Stadium', 'Nova York'),
    _m('F4', 'F', 'TUN', 'JPN', _dt(6, 20, 22, 0), 'Empower Field', 'Denver'),
    _m('F5', 'F', 'TUN', 'NED', _dt(6, 27, 21, 0), 'AT&T Stadium', 'Dallas'),
    _m('F6', 'F', 'JPN', 'SWE', _dt(6, 27, 21, 0), 'Estadio Azteca', 'Cidade do México'),

    // Grupo G
    _m('G1', 'G', 'BEL', 'EGY', _dt(6, 17, 19, 0), 'Rose Bowl', 'Los Angeles'),
    _m('G2', 'G', 'IRN', 'NZL', _dt(6, 17, 22, 0), 'BC Place', 'Vancouver'),
    _m('G3', 'G', 'BEL', 'IRN', _dt(6, 21, 19, 0), 'AT&T Stadium', 'Dallas'),
    _m('G4', 'G', 'NZL', 'EGY', _dt(6, 21, 22, 0), 'Arrowhead Stadium', 'Kansas City'),
    _m('G5', 'G', 'NZL', 'BEL', _dt(6, 28, 21, 0), 'Lumen Field', 'Seattle'),
    _m('G6', 'G', 'EGY', 'IRN', _dt(6, 28, 21, 0), 'Allegiant Stadium', 'Las Vegas'),

    // Grupo H
    _m('H1', 'H', 'ESP', 'CPV', _dt(6, 18, 19, 0), 'NRG Stadium', 'Houston'),
    _m('H2', 'H', 'KSA', 'URU', _dt(6, 18, 22, 0), 'Hard Rock Stadium', 'Miami'),
    _m('H3', 'H', 'ESP', 'KSA', _dt(6, 22, 19, 0), 'SoFi Stadium', 'Los Angeles'),
    _m('H4', 'H', 'URU', 'CPV', _dt(6, 22, 22, 0), 'Levi\'s Stadium', 'San Francisco'),
    _m('H5', 'H', 'URU', 'ESP', _dt(6, 29, 21, 0), 'Mercedes-Benz Stadium', 'Atlanta'),
    _m('H6', 'H', 'CPV', 'KSA', _dt(6, 29, 21, 0), 'State Farm Stadium', 'Phoenix'),

    // Grupo I
    _m('I1', 'I', 'FRA', 'SEN', _dt(6, 19, 19, 0), 'Allegiant Stadium', 'Las Vegas'),
    _m('I2', 'I', 'IRQ', 'NOR', _dt(6, 19, 22, 0), 'Levi\'s Stadium', 'San Francisco'),
    _m('I3', 'I', 'FRA', 'IRQ', _dt(6, 23, 19, 0), 'BC Place', 'Vancouver'),
    _m('I4', 'I', 'NOR', 'SEN', _dt(6, 23, 22, 0), 'Lincoln Financial Field', 'Filadélfia'),
    _m('I5', 'I', 'NOR', 'FRA', _dt(6, 30, 21, 0), 'SoFi Stadium', 'Los Angeles'),
    _m('I6', 'I', 'SEN', 'IRQ', _dt(6, 30, 21, 0), 'Estadio Azteca', 'Cidade do México'),

    // Grupo J
    _m('J1', 'J', 'ARG', 'ALG', _dt(6, 20, 19, 0), 'MetLife Stadium', 'Nova York'),
    _m('J2', 'J', 'AUT', 'JOR', _dt(6, 20, 22, 0), 'Rose Bowl', 'Los Angeles'),
    _m('J3', 'J', 'ARG', 'AUT', _dt(6, 24, 19, 0), 'NRG Stadium', 'Houston'),
    _m('J4', 'J', 'JOR', 'ALG', _dt(6, 24, 22, 0), 'Gillette Stadium', 'Boston'),
    _m('J5', 'J', 'JOR', 'ARG', _dt(7, 1, 21, 0), 'AT&T Stadium', 'Dallas'),
    _m('J6', 'J', 'ALG', 'AUT', _dt(7, 1, 21, 0), 'Hard Rock Stadium', 'Miami'),

    // Grupo K
    _m('K1', 'K', 'POR', 'COD', _dt(6, 21, 19, 0), 'Gillette Stadium', 'Boston'),
    _m('K2', 'K', 'UZB', 'COL', _dt(6, 21, 22, 0), 'Empower Field', 'Denver'),
    _m('K3', 'K', 'POR', 'UZB', _dt(6, 25, 19, 0), 'Mercedes-Benz Stadium', 'Atlanta'),
    _m('K4', 'K', 'COL', 'COD', _dt(6, 25, 22, 0), 'Estadio Azteca', 'Cidade do México'),
    _m('K5', 'K', 'COL', 'POR', _dt(7, 2, 21, 0), 'Rose Bowl', 'Los Angeles'),
    _m('K6', 'K', 'COD', 'UZB', _dt(7, 2, 21, 0), 'Allegiant Stadium', 'Las Vegas'),

    // Grupo L
    _m('L1', 'L', 'ENG', 'CRO', _dt(6, 22, 19, 0), 'Lumen Field', 'Seattle'),
    _m('L2', 'L', 'GHA', 'PAN', _dt(6, 22, 22, 0), 'BC Place', 'Vancouver'),
    _m('L3', 'L', 'ENG', 'GHA', _dt(6, 26, 19, 0), 'MetLife Stadium', 'Nova York'),
    _m('L4', 'L', 'PAN', 'CRO', _dt(6, 26, 22, 0), 'Levi\'s Stadium', 'San Francisco'),
    _m('L5', 'L', 'PAN', 'ENG', _dt(7, 3, 21, 0), 'NRG Stadium', 'Houston'),
    _m('L6', 'L', 'CRO', 'GHA', _dt(7, 3, 21, 0), 'State Farm Stadium', 'Phoenix'),
  ];

  static List<CopaMatch> forGroup(String group) =>
      all.where((m) => m.round == group).toList();

  static List<CopaMatch> today() {
    final now = DateTime.now().toUtc();
    final start = DateTime.utc(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return all.where((m) => m.kickoff.isAfter(start) && m.kickoff.isBefore(end)).toList();
  }

  static CopaMatch? nextMatch() {
    final now = DateTime.now().toUtc();
    final upcoming = all.where((m) => m.kickoff.isAfter(now)).toList();
    if (upcoming.isEmpty) return null;
    return upcoming.reduce((a, b) => a.kickoff.isBefore(b.kickoff) ? a : b);
  }
}
