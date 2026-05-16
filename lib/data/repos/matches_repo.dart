import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/copa_models.dart';
import '../seeds/wc2026_matches_seed.dart';

// ESPN unofficial public API — no auth required
const _espnBase = 'https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world';

class MatchesRepo {
  // Cache TTL: 1 min during live match window, 30 min otherwise
  static const _liveTtlMs = 60 * 1000;
  static const _idleTtlMs = 30 * 60 * 1000;

  // In-memory overlay: live scores from ESPN keyed by match ID
  final Map<String, CopaMatch> _liveOverlay = {};
  DateTime? _lastFetch;

  /// Returns all matches merged: seed schedule + live score overlay.
  List<CopaMatch> allMatches() {
    return WC2026Matches.all.map((m) => _liveOverlay[m.id] ?? m).toList();
  }

  List<CopaMatch> matchesForGroup(String group) =>
      allMatches().where((m) => m.round == group).toList();

  List<CopaMatch> matchesForDate(DateTime date) {
    final d = DateTime.utc(date.year, date.month, date.day);
    final end = d.add(const Duration(days: 1));
    return allMatches()
        .where((m) => m.kickoff.isAfter(d) && m.kickoff.isBefore(end))
        .toList()
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));
  }

  CopaMatch? nextMatch() {
    final now = DateTime.now().toUtc();
    final upcoming = allMatches().where((m) => m.kickoff.isAfter(now)).toList();
    if (upcoming.isEmpty) return null;
    return upcoming.reduce((a, b) => a.kickoff.isBefore(b.kickoff) ? a : b);
  }

  CopaMatch? currentLiveMatch() {
    return _liveOverlay.values
        .where((m) => m.status == MatchStatus.live)
        .firstOrNull;
  }

  List<CopaMatch> liveMatches() =>
      _liveOverlay.values.where((m) => m.status == MatchStatus.live).toList();

  bool get _hasFreshCache {
    if (_lastFetch == null) return false;
    final age = DateTime.now().difference(_lastFetch!).inMilliseconds;
    final hasLive = _liveOverlay.values.any((m) => m.status == MatchStatus.live);
    return age < (hasLive ? _liveTtlMs : _idleTtlMs);
  }

  /// Refresh live scores from ESPN. Silently falls back to seed on any error.
  Future<void> refresh() async {
    if (_hasFreshCache) return;
    if (kIsWeb) return; // ESPN API has CORS issues on web — seed-only there
    try {
      await _fetchFromEspn();
    } catch (_) {
      // Fail silently — seed data is always available
    }
    _lastFetch = DateTime.now();
  }

  Future<void> _fetchFromEspn() async {
    // Fetch today + next 3 days to catch late-night UTC matches
    final now = DateTime.now().toUtc();
    final from = _dateStr(now);
    final to = _dateStr(now.add(const Duration(days: 3)));
    final url = Uri.parse('$_espnBase/scoreboard?limit=50&dates=$from-$to');
    final response = await http.get(url).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final events = (json['events'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final event in events) {
      final match = _parseEspnEvent(event);
      if (match != null) _liveOverlay[match.id] = match;
    }
  }

  CopaMatch? _parseEspnEvent(Map<String, dynamic> event) {
    try {
      final dateStr = event['date'] as String;
      final kickoff = DateTime.parse(dateStr);

      final competitions =
          (event['competitions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (competitions.isEmpty) return null;
      final comp = competitions.first;

      final competitors =
          (comp['competitors'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (competitors.length < 2) return null;

      Map<String, dynamic>? homeData;
      Map<String, dynamic>? awayData;
      for (final c in competitors) {
        if (c['homeAway'] == 'home') homeData = c;
        if (c['homeAway'] == 'away') awayData = c;
      }
      if (homeData == null || awayData == null) return null;

      final homeTeamData = homeData['team'] as Map<String, dynamic>;
      final awayTeamData = awayData['team'] as Map<String, dynamic>;
      final homeCode = _espnAbbrToCode(homeTeamData['abbreviation'] as String? ?? '');
      final awayCode = _espnAbbrToCode(awayTeamData['abbreviation'] as String? ?? '');

      // Match to seed by team codes + approximate date
      final seedMatch = _findSeedMatch(homeCode, awayCode, kickoff);
      if (seedMatch == null) return null;

      final statusObj = event['status'] as Map<String, dynamic>?;
      final statusType = (statusObj?['type'] as Map<String, dynamic>?)?['name'] as String? ?? '';
      final status = switch (statusType) {
        'STATUS_IN_PROGRESS' => MatchStatus.live,
        'STATUS_FINAL' || 'STATUS_FULL_TIME' => MatchStatus.finished,
        _ => MatchStatus.scheduled,
      };

      final liveMinute = statusObj?['displayClock'] != null
          ? int.tryParse(
              (statusObj!['displayClock'] as String).replaceAll(RegExp(r"[^0-9]"), ''))
          : null;

      final homeScore = int.tryParse(homeData['score'] as String? ?? '');
      final awayScore = int.tryParse(awayData['score'] as String? ?? '');

      return seedMatch.copyWith(
        homeScore: homeScore,
        awayScore: awayScore,
        status: status,
        liveMinute: liveMinute,
      );
    } catch (_) {
      return null;
    }
  }

  CopaMatch? _findSeedMatch(String homeCode, String awayCode, DateTime kickoff) {
    final window = const Duration(hours: 6);
    for (final m in WC2026Matches.all) {
      if (m.home.code == homeCode &&
          m.away.code == awayCode &&
          (m.kickoff.difference(kickoff)).abs() < window) {
        return m;
      }
    }
    return null;
  }

  // ESPN uses some non-standard abbreviations — map to Panini codes
  static final _espnMap = <String, String>{
    'MEX': 'MEX', 'RSA': 'RSA', 'KOR': 'KOR', 'CZE': 'CZE',
    'CAN': 'CAN', 'BIH': 'BIH', 'QAT': 'QAT', 'SUI': 'SUI',
    'BRA': 'BRA', 'MAR': 'MAR', 'HAI': 'HAI', 'SCO': 'SCO',
    'USA': 'USA', 'PAR': 'PAR', 'AUS': 'AUS', 'TUR': 'TUR',
    'GER': 'GER', 'CUW': 'CUW', 'CIV': 'CIV', 'ECU': 'ECU',
    'NED': 'NED', 'JPN': 'JPN', 'SWE': 'SWE', 'TUN': 'TUN',
    'BEL': 'BEL', 'EGY': 'EGY', 'IRN': 'IRN', 'NZL': 'NZL',
    'ESP': 'ESP', 'CPV': 'CPV', 'KSA': 'KSA', 'URU': 'URU',
    'FRA': 'FRA', 'SEN': 'SEN', 'IRQ': 'IRQ', 'NOR': 'NOR',
    'ARG': 'ARG', 'ALG': 'ALG', 'AUT': 'AUT', 'JOR': 'JOR',
    'POR': 'POR', 'COD': 'COD', 'UZB': 'UZB', 'COL': 'COL',
    'ENG': 'ENG', 'CRO': 'CRO', 'GHA': 'GHA', 'PAN': 'PAN',
    // ESPN variants
    'CODO': 'COD', 'DRC': 'COD', 'BOI': 'BIH',
    'COIV': 'CIV', 'SKN': 'KOR', 'CTA': 'QAT',
  };

  static String _espnAbbrToCode(String abbr) => _espnMap[abbr.toUpperCase()] ?? abbr;

  static String _dateStr(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

}

final matchesRepoProvider = Provider<MatchesRepo>((_) => MatchesRepo());

final copaMatchesProvider = FutureProvider.autoDispose<List<CopaMatch>>((ref) async {
  final repo = ref.watch(matchesRepoProvider);
  await repo.refresh();
  return repo.allMatches();
});
