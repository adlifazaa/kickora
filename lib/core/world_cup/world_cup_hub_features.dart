import '../../data/models/match_model.dart';
import '../../data/models/team_model.dart';
import 'world_cup_hub_loader.dart';
import 'world_cup_stadiums.dart';

/// Target Arab nations for World Cup Hub (shown only when present in data).
class WorldCupArabTeams {
  WorldCupArabTeams._();

  static const _targets = [
    _ArabTarget(key: 'jordan', codes: ['JO'], names: ['jordan', 'الأردن']),
    _ArabTarget(
      key: 'saudi',
      codes: ['SA'],
      names: ['saudi', 'saudi arabia', 'السعود', 'المملكة'],
    ),
    _ArabTarget(
      key: 'morocco',
      codes: ['MA'],
      names: ['morocco', 'المغرب'],
    ),
    _ArabTarget(
      key: 'algeria',
      codes: ['DZ'],
      names: ['algeria', 'الجزائر'],
    ),
    _ArabTarget(
      key: 'egypt',
      codes: ['EG'],
      names: ['egypt', 'مصر'],
    ),
    _ArabTarget(
      key: 'tunisia',
      codes: ['TN'],
      names: ['tunisia', 'تونس'],
    ),
    _ArabTarget(
      key: 'iraq',
      codes: ['IQ'],
      names: ['iraq', 'العراق'],
    ),
    _ArabTarget(
      key: 'qatar',
      codes: ['QA'],
      names: ['qatar', 'قطر'],
    ),
  ];

  /// All unique teams from loaded hub data.
  static List<TeamModel> allTeams(WorldCupHubLoader loader) => _allTeams(loader);

  /// Arab teams that appear in loaded World Cup fixtures / standings / teams.
  static List<TeamModel> fromLoader(WorldCupHubLoader loader) {
    final pool = _allTeams(loader);
    final matched = <TeamModel>[];
    for (final team in pool) {
      if (isArabTeam(team)) matched.add(team);
    }
    matched.sort((a, b) => a.name.compareTo(b.name));
    return matched;
  }

  static bool isArabTeam(TeamModel team) {
    final code = team.countryCode.trim().toUpperCase();
    final name = team.name.toLowerCase();
    final country = team.countryName.toLowerCase();
    for (final t in _targets) {
      if (code.isNotEmpty && t.codes.contains(code)) return true;
      for (final token in t.names) {
        if (name.contains(token) || country.contains(token)) return true;
      }
    }
    return false;
  }

  static List<TeamModel> _allTeams(WorldCupHubLoader loader) {
    final byId = <int, TeamModel>{};
    for (final t in loader.teams) {
      byId[t.id] = t;
    }
    for (final g in loader.groups) {
      for (final row in g.rows) {
        byId[row.team.id] = row.team;
      }
    }
    for (final m in loader.matches) {
      byId[m.homeTeam.id] = m.homeTeam;
      byId[m.awayTeam.id] = m.awayTeam;
    }
    return byId.values.toList();
  }

  static MatchModel? nextMatch(WorldCupHubLoader loader, int teamId) {
    final list = loader
        .matchesForTeam(teamId)
        .where((m) => m.status == MatchStatus.upcoming || m.status == MatchStatus.live)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list.isEmpty ? null : list.first;
  }

  static MatchModel? lastFinished(WorldCupHubLoader loader, int teamId) {
    final list = loader
        .matchesForTeam(teamId)
        .where((m) => m.status == MatchStatus.finished)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list.isEmpty ? null : list.first;
  }
}

class _ArabTarget {
  const _ArabTarget({
    required this.key,
    required this.codes,
    required this.names,
  });

  final String key;
  final List<String> codes;
  final List<String> names;
}

enum WorldCupSearchKind { team, match, stadium, player }

class WorldCupSearchResult {
  const WorldCupSearchResult({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.payload,
  });

  final WorldCupSearchKind kind;
  final String title;
  final String subtitle;
  final Object payload;
}

/// In-memory search over World Cup Hub data (no per-keystroke API calls).
class WorldCupHubSearch {
  WorldCupHubSearch._();

  static String _norm(String value) => value.trim().toLowerCase();

  static List<WorldCupSearchResult> search(
    WorldCupHubLoader loader,
    String query,
  ) {
    final q = _norm(query);
    if (q.isEmpty) return const [];

    final teams = _searchTeams(loader, q);
    final matches = _searchMatches(loader, q);
    final stadiums = _searchStadiums(loader, q);
    final players = _searchPlayers(loader, q);

    return [...teams, ...matches, ...stadiums, ...players];
  }

  static List<WorldCupSearchResult> grouped(
    WorldCupHubLoader loader,
    String query,
  ) {
    final all = search(loader, query);
    final order = WorldCupSearchKind.values;
    all.sort((a, b) {
      final ki = order.indexOf(a.kind).compareTo(order.indexOf(b.kind));
      if (ki != 0) return ki;
      return a.title.compareTo(b.title);
    });
    return all;
  }

  static List<WorldCupSearchResult> _searchTeams(
    WorldCupHubLoader loader,
    String q,
  ) {
    final allTeams = WorldCupArabTeams.allTeams(loader);

    return allTeams
        .where((t) =>
            _norm(t.name).contains(q) ||
            _norm(t.countryName).contains(q) ||
            _norm(t.shortName).contains(q))
        .map(
          (t) => WorldCupSearchResult(
            kind: WorldCupSearchKind.team,
            title: t.name,
            subtitle: loader.groupNameForTeam(t.id) ?? t.countryName,
            payload: t,
          ),
        )
        .toList();
  }

  static List<WorldCupSearchResult> _searchMatches(
    WorldCupHubLoader loader,
    String q,
  ) {
    return loader.matches
        .where((m) =>
            _norm(m.homeTeam.name).contains(q) ||
            _norm(m.awayTeam.name).contains(q) ||
            _norm(m.stadium).contains(q) ||
            _norm(m.round).contains(q))
        .map(
          (m) => WorldCupSearchResult(
            kind: WorldCupSearchKind.match,
            title: '${m.homeTeam.name} vs ${m.awayTeam.name}',
            subtitle: m.stadium.isNotEmpty ? m.stadium : m.round,
            payload: m,
          ),
        )
        .toList();
  }

  static List<WorldCupSearchResult> _searchStadiums(
    WorldCupHubLoader loader,
    String q,
  ) {
    return WorldCupStadiums.venues
        .where((s) =>
            _norm(s.name).contains(q) ||
            _norm(s.city).contains(q) ||
            _norm(s.country).contains(q))
        .map(
          (s) => WorldCupSearchResult(
            kind: WorldCupSearchKind.stadium,
            title: s.name,
            subtitle: '${s.city}, ${s.country}',
            payload: s,
          ),
        )
        .toList();
  }

  static List<WorldCupSearchResult> _searchPlayers(
    WorldCupHubLoader loader,
    String q,
  ) {
    return loader.scorers
        .where((p) =>
            _norm(p.name).contains(q) || _norm(p.team).contains(q))
        .map(
          (p) => WorldCupSearchResult(
            kind: WorldCupSearchKind.player,
            title: p.name,
            subtitle: p.team,
            payload: p,
          ),
        )
        .toList();
  }
}
