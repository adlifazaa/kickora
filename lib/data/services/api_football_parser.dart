import '../models/competition_model.dart';
import '../models/formation_model.dart';
import '../models/lineup_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/standing_model.dart';
import '../models/team_model.dart';

/// Maps API-Football (`api-sports.io` v3) JSON into Kickora domain models.
class ApiFootballParser {
  const ApiFootballParser._();

  static List<T> responseList<T>(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) map,
  ) {
    final raw = body['response'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => map(Map<String, dynamic>.from(e)))
        .toList();
  }

  // --- Fixtures / matches ---

  static List<MatchModel> parseFixtures(Map<String, dynamic> body) =>
      responseList(body, parseFixture);

  static MatchModel parseFixture(Map<String, dynamic> json) {
    final fixture = _map(json['fixture']);
    final league = _map(json['league']);
    final teams = _map(json['teams']);
    final goals = _map(json['goals']);
    final score = _map(json['score']);

    final homeTeamJson = _map(teams['home']);
    final awayTeamJson = _map(teams['away']);
    final leagueCountry = _parseCountry(league['country']);
    final statusShort =
        _map(fixture['status'])['short']?.toString() ?? 'NS';
    final elapsed = _map(fixture['status'])['elapsed'];

    final homeScore = _goalCount(goals['home'], score, 'home');
    final awayScore = _goalCount(goals['away'], score, 'away');

    final fixtureId = _int(fixture['id']);
    return MatchModel(
      id: fixtureId,
      fixtureId: fixtureId,
      homeTeam: _teamFromFixtureSide(
        homeTeamJson,
        leagueCountry: leagueCountry,
      ),
      awayTeam: _teamFromFixtureSide(
        awayTeamJson,
        leagueCountry: leagueCountry,
      ),
      homeScore: homeScore,
      awayScore: awayScore,
      status: parseApiFootballStatus(statusShort),
      timeLabel: _timeLabel(
        statusShort,
        elapsed,
        kickoff: DateTime.tryParse(fixture['date']?.toString() ?? ''),
      ),
      competition: CompetitionModel(
        id: _int(league['id']),
        name: league['name']?.toString() ?? '',
        region: leagueCountry.name,
        logo: league['logo']?.toString() ?? '',
        isFeatured: false,
      ),
      date: DateTime.tryParse(fixture['date']?.toString() ?? '') ??
          DateTime.now(),
      stadium: _map(fixture['venue'])['name']?.toString() ?? '',
    );
  }

  static MatchStatus parseApiFootballStatus(String short) {
    switch (short.toUpperCase()) {
      case '1H':
      case 'HT':
      case '2H':
      case 'ET':
      case 'BT':
      case 'P':
      case 'LIVE':
      case 'INPLAY':
      case 'INT':
        return MatchStatus.live;
      case 'FT':
      case 'AET':
      case 'PEN':
      case 'AWD':
      case 'WO':
        return MatchStatus.finished;
      default:
        return MatchStatus.upcoming;
    }
  }

  static String _timeLabel(String short, Object? elapsed, {DateTime? kickoff}) {
    if (short == 'HT') return 'HT';
    if (short == 'FT' || short == 'AET' || short == 'PEN') return 'FT';
    if (elapsed != null) {
      final min = _int(elapsed);
      if (min > 0) return "$min'";
    }
    if (kickoff != null) {
      final h = kickoff.hour.toString().padLeft(2, '0');
      final m = kickoff.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return short;
  }

  static int _goalCount(Object? goals, Map<String, dynamic> score, String side) {
    if (goals != null && goals is num) return goals.toInt();
    if (goals != null && goals is String) return int.tryParse(goals) ?? 0;
    final fulltime = _map(score['fulltime']);
    final halftime = _map(score['halftime']);
    final val = fulltime[side] ?? halftime[side];
    if (val == null) return 0;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }

  static TeamModel _teamFromFixtureSide(
    Map<String, dynamic> json, {
    _CountryFields leagueCountry = const _CountryFields(),
  }) {
    final name = json['name']?.toString() ?? '';
    final code = json['code']?.toString();
    final sideCountry = _parseCountry(json['country']);
    final countryName = sideCountry.name.isNotEmpty
        ? sideCountry.name
        : leagueCountry.name;
    final countryCode = sideCountry.code.isNotEmpty
        ? sideCountry.code
        : leagueCountry.code;
    var flagUrl = json['flagUrl']?.toString() ?? '';
    if (flagUrl.isEmpty) {
      flagUrl = sideCountry.flagUrl.isNotEmpty
          ? sideCountry.flagUrl
          : leagueCountry.flagUrl;
    }
    if (flagUrl.isEmpty && countryCode.isNotEmpty) {
      flagUrl = flagUrlFromCountryCode(countryCode);
    }

    return TeamModel(
      id: _int(json['id']),
      name: name,
      shortName: (code != null && code.isNotEmpty)
          ? code
          : _abbrev(name),
      logo: json['logoUrl']?.toString() ?? json['logo']?.toString() ?? '',
      countryName: countryName,
      countryCode: countryCode,
      flagUrl: flagUrl,
    );
  }

  // --- Events ---

  static List<MatchEventModel> parseEvents(
    Map<String, dynamic> body, {
    int? homeTeamId,
    int? awayTeamId,
  }) {
    return responseList(body, (json) {
      final team = _map(json['team']);
      final player = _map(json['player']);
      final assist = _map(json['assist']);
      final time = _map(json['time']);
      final elapsed = _int(time['elapsed']);
      final extra = _int(time['extra']);
      final minute = extra > 0 ? "$elapsed+$extra'" : "$elapsed'";

      final teamId = _int(team['id']);
      final isHome = homeTeamId != null
          ? teamId == homeTeamId
          : (json['isHome'] as bool? ?? false);

      final typeRaw = json['type']?.toString() ?? '';
      final detailRaw = json['detail']?.toString() ?? '';
      final eventType = _parseEventType(typeRaw, detailRaw);
      final playerIn = player['name']?.toString() ?? '';
      final playerOut = assist['name']?.toString();
      final description = eventType == MatchEventType.substitution &&
              playerOut != null &&
              playerOut.isNotEmpty
          ? 'Replaces $playerOut'
          : detailRaw;

      return MatchEventModel(
        minute: minute,
        type: eventType,
        playerName: playerIn,
        assistName: playerOut,
        description: description,
        isHome: isHome,
      );
    });
  }

  static MatchEventType _parseEventType(String type, String detail) {
    final t = type.toLowerCase();
    final d = detail.toLowerCase();
    if (t.contains('subst') || d.contains('substitution')) {
      return MatchEventType.substitution;
    }
    if (t.contains('var') || d.contains('var')) {
      return MatchEventType.varDecision;
    }
    if (t.contains('card') || d.contains('card')) {
      if (d.contains('red') || d.contains('second yellow')) {
        return MatchEventType.redCard;
      }
      return MatchEventType.yellowCard;
    }
    if (t.contains('goal') || d.contains('goal')) {
      if (d.contains('own')) return MatchEventType.ownGoal;
      if (d.contains('penalty')) return MatchEventType.penalty;
      return MatchEventType.goal;
    }
    return MatchEventType.varDecision;
  }

  // --- Statistics ---

  static List<MatchStatisticModel> parseStatistics(
    Map<String, dynamic> body, {
    int? homeTeamId,
  }) {
    final teams = body['response'];
    if (teams is! List || teams.isEmpty) return const [];

    Map<String, dynamic>? homeEntry;
    Map<String, dynamic>? awayEntry;

    for (final raw in teams) {
      if (raw is! Map) continue;
      final entry = Map<String, dynamic>.from(raw);
      final teamId = _int(_map(entry['team'])['id']);
      if (homeTeamId != null && teamId == homeTeamId) {
        homeEntry = entry;
      } else if (awayEntry == null ||
          (homeTeamId != null && teamId != homeTeamId)) {
        awayEntry = entry;
      }
    }

    homeEntry ??=
        teams.isNotEmpty ? Map<String, dynamic>.from(teams[0] as Map) : null;
    awayEntry ??= teams.length > 1
        ? Map<String, dynamic>.from(teams[1] as Map)
        : null;

    if (homeEntry == null || awayEntry == null) return const [];
    final homeStats = _statisticsMap(homeEntry);
    final awayStats = _statisticsMap(awayEntry);

    final titles = <String>{...homeStats.keys, ...awayStats.keys};
    final out = <MatchStatisticModel>[];

    for (final title in titles) {
      final homeRaw = homeStats[title];
      final awayRaw = awayStats[title];
      final homeNum = _statNumeric(homeRaw);
      final awayNum = _statNumeric(awayRaw);
      out.add(
        MatchStatisticModel(
          title: title,
          home: homeNum,
          away: awayNum,
          homeValue: _statDisplay(homeRaw),
          awayValue: _statDisplay(awayRaw),
        ),
      );
    }
    return out;
  }

  static Map<String, Object?> _statisticsMap(Map<String, dynamic> entry) {
    final list = entry['statistics'];
    if (list is! List) return {};
    final map = <String, Object?>{};
    for (final item in list) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final type = m['type']?.toString();
      if (type != null) map[type] = m['value'];
    }
    return map;
  }

  static double _statNumeric(Object? raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    final s = raw.toString().replaceAll('%', '').trim();
    return double.tryParse(s) ?? 0;
  }

  static String _statDisplay(Object? raw) {
    if (raw == null) return '0';
    return raw.toString();
  }

  // --- Lineups ---

  static ({LineupModel? home, LineupModel? away}) parseLineups(
    Map<String, dynamic> body, {
    int? homeTeamId,
    int? awayTeamId,
  }) {
    final entries = body['response'];
    if (entries is! List || entries.isEmpty) {
      return (home: null, away: null);
    }

    LineupModel? home;
    LineupModel? away;

    for (final raw in entries) {
      if (raw is! Map) continue;
      final entry = Map<String, dynamic>.from(raw);
      final lineup = _parseLineupEntry(entry);
      final teamId = _int(_map(entry['team'])['id']);

      if (homeTeamId != null && teamId == homeTeamId) {
        home = lineup;
      } else if (awayTeamId != null && teamId == awayTeamId) {
        away = lineup;
      } else if (home == null) {
        home = lineup;
      } else {
        away = lineup;
      }
    }

    return (home: home, away: away);
  }

  static LineupModel _parseLineupEntry(Map<String, dynamic> json) {
    final formation = json['formation']?.toString() ?? '';
    final coach = _map(json['coach'])['name']?.toString() ?? '';
    final startXi = (json['startXI'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final subs = json['substitutes'] as List? ?? const [];

    final substitutePlayers = <PlayerModel>[];
    for (final slot in subs) {
      if (slot is! Map) continue;
      final player = _map(_map(slot)['player']);
      substitutePlayers.add(_lineupPlayer(player));
    }

    return LineupModel(
      formation: formation,
      coach: coach,
      lines: _buildLinesFromStartXi(startXi, formation),
      substitutes: substitutePlayers,
      formationDetail: FormationModel.fromName(formation),
    );
  }

  static PlayerModel _lineupPlayer(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';
    final id = _int(json['id']);
    return PlayerModel(
      id: id,
      name: name,
      shortName: _abbrev(name),
      number: _int(json['number']),
      nationality: '',
      age: 0,
      height: 0,
      position: _lineupPosition(json['pos']?.toString()),
      team: '',
      appearances: 0,
      goals: 0,
      assists: 0,
      yellowCards: 0,
      redCards: 0,
      photoUrl: resolvePlayerPhotoUrl(json),
    );
  }

  static List<List<PlayerModel>> _buildLinesFromStartXi(
    List<Map<String, dynamic>> startXi,
    String formation,
  ) {
    final rows = <int, List<({int col, PlayerModel player})>>{};

    for (final slot in startXi) {
      final playerMap = _map(slot['player']);
      final grid = playerMap['grid']?.toString() ?? '';
      final parts = grid.split(':');
      final row = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
      final col = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      rows
          .putIfAbsent(row, () => [])
          .add((col: col, player: _lineupPlayer(playerMap)));
    }

    if (rows.isNotEmpty) {
      final sortedRows = rows.keys.toList()..sort();
      return sortedRows.map((r) {
        final line = rows[r]!..sort((a, b) => a.col.compareTo(b.col));
        return line.map((e) => e.player).toList();
      }).toList();
    }

    final starters = startXi
        .map((s) => _lineupPlayer(_map(s['player'])))
        .toList();
    return _splitByFormation(starters, formation);
  }

  static List<List<PlayerModel>> _splitByFormation(
    List<PlayerModel> starters,
    String formation,
  ) {
    if (starters.isEmpty) return const [];

    final parts = formation
        .split('-')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((n) => n > 0)
        .toList();

    if (parts.isEmpty) return [starters];

    final lines = <List<PlayerModel>>[];
    var index = 0;
    for (final count in parts) {
      final line = <PlayerModel>[];
      for (var c = 0; c < count && index < starters.length; c++) {
        line.add(starters[index++]);
      }
      if (line.isNotEmpty) lines.add(line);
    }
    if (index < starters.length) {
      lines.add(starters.sublist(index));
    }
    return lines;
  }

  // --- Leagues / competitions ---

  static List<CompetitionModel> parseLeagues(Map<String, dynamic> body) =>
      responseList(body, parseLeague);

  static CompetitionModel parseLeague(Map<String, dynamic> json) {
    final league = _map(json['league']);
    final country = _map(json['country']);
    return CompetitionModel(
      id: _int(league['id']),
      name: league['name']?.toString() ?? '',
      region: country['name']?.toString() ?? '',
      logo: league['logo']?.toString() ?? '',
      isFeatured: _int(league['id']) == 1,
      teamCount: 0,
      matchesToday: 0,
    );
  }

  // --- Standings ---

  static List<StandingModel> parseStandings(Map<String, dynamic> body) {
    final response = body['response'];
    if (response is! List || response.isEmpty) return const [];

    final first = Map<String, dynamic>.from(response.first as Map);
    final groups = first['league'] != null
        ? _map(first['league'])['standings']
        : first['standings'];

    if (groups is! List || groups.isEmpty) return const [];

    final table = groups.first;
    if (table is! List) return const [];

    return table
        .whereType<Map>()
        .map((e) => _parseStandingRow(Map<String, dynamic>.from(e)))
        .toList();
  }

  static StandingModel _parseStandingRow(Map<String, dynamic> json) {
    final teamJson = _map(json['team']);
    final all = _map(json['all']);
    return StandingModel(
      position: _int(json['rank']),
      team: _teamFromStandingJson(teamJson),
      played: _int(all['played']),
      wins: _int(all['win']),
      draws: _int(all['draw']),
      losses: _int(all['lose']),
      goalDifference: _int(json['goalsDiff']),
      points: _int(json['points']),
    );
  }

  // --- Teams ---

  static List<TeamModel> parseTeams(Map<String, dynamic> body) =>
      responseList(body, parseTeam);

  static TeamModel parseTeam(Map<String, dynamic> json) {
    final team = _map(json['team']);
    final venue = _map(json['venue']);
    final country = _parseCountry(team['country']);
    final countryName = country.name.isNotEmpty
        ? country.name
        : venue['city']?.toString() ?? '';
    var flagUrl = country.flagUrl;
    if (flagUrl.isEmpty && country.code.isNotEmpty) {
      flagUrl = flagUrlFromCountryCode(country.code);
    }
    return TeamModel(
      id: _int(team['id']),
      name: team['name']?.toString() ?? '',
      shortName: (team['code']?.toString().isNotEmpty == true)
          ? team['code'].toString()
          : _abbrev(team['name']?.toString() ?? ''),
      logo: team['logo']?.toString() ?? '',
      countryName: countryName,
      countryCode: country.code,
      flagUrl: flagUrl,
    );
  }

  static TeamModel _teamFromStandingJson(Map<String, dynamic> teamJson) {
    final country = _parseCountry(teamJson['country']);
    var flagUrl = country.flagUrl;
    if (flagUrl.isEmpty && country.code.isNotEmpty) {
      flagUrl = flagUrlFromCountryCode(country.code);
    }
    return TeamModel(
      id: _int(teamJson['id']),
      name: teamJson['name']?.toString() ?? '',
      shortName: teamJson['code']?.toString().isNotEmpty == true
          ? teamJson['code'].toString()
          : _abbrev(teamJson['name']?.toString() ?? ''),
      logo: teamJson['logo']?.toString() ?? '',
      countryName: country.name,
      countryCode: country.code,
      flagUrl: flagUrl,
    );
  }

  // --- Players ---

  static List<PlayerModel> parseTopScorers(Map<String, dynamic> body) =>
      responseList(body, parseTopScorer);

  static PlayerModel parseTopScorer(Map<String, dynamic> json) {
    final player = _map(json['player']);
    final statsList = json['statistics'] as List? ?? const [];
    final stats = statsList.isNotEmpty ? _map(statsList.first) : <String, dynamic>{};
    final team = _map(stats['team']);
    final goals = _map(stats['goals']);
    final games = _map(stats['games']);

    return PlayerModel(
      id: _int(player['id']),
      name: player['name']?.toString() ?? '',
      shortName: _abbrev(player['name']?.toString() ?? ''),
      number: 0,
      nationality: player['nationality']?.toString() ?? '',
      age: _int(player['age']),
      height: 0,
      position: games['position']?.toString() ?? '',
      team: team['name']?.toString() ?? '',
      teamLogoShort: team['code']?.toString().isNotEmpty == true
          ? team['code'].toString()
          : _abbrev(team['name']?.toString() ?? ''),
      teamLogoUrl: team['logo']?.toString() ?? '',
      appearances: _int(games['appearences'] ?? games['appearances']),
      goals: _int(goals['total']),
      assists: 0,
      yellowCards: 0,
      redCards: 0,
      seasonRating: '7.5',
      photoUrl: resolvePlayerPhotoUrl(player),
    );
  }

  static PlayerModel? parsePlayer(Map<String, dynamic> body) {
    final list = body['response'];
    if (list is! List || list.isEmpty) return null;
    final entry = Map<String, dynamic>.from(list.first as Map);
    return parseTopScorer(entry);
  }

  // --- Helpers ---

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  static int _int(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static String _lineupPosition(String? pos) {
    switch (pos?.toUpperCase()) {
      case 'G':
      case 'GK':
        return 'GK';
      default:
        return pos ?? '';
    }
  }

  static String _abbrev(String name) {
    if (name.isEmpty) return '---';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return name.length >= 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase();
    }
    return parts.map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase();
  }

  static _CountryFields _parseCountry(Object? raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final code = map['code']?.toString() ?? '';
      var flag = map['flag']?.toString() ?? '';
      if (flag.isEmpty && code.isNotEmpty) {
        flag = flagUrlFromCountryCode(code);
      }
      return _CountryFields(
        name: map['name']?.toString() ?? '',
        code: code,
        flagUrl: flag,
      );
    }
    if (raw is String && raw.isNotEmpty) {
      return _CountryFields(name: raw);
    }
    return const _CountryFields();
  }

  /// Explicit player photo from lineup/player API payload only.
  static String resolvePlayerPhotoUrl(Map<String, dynamic> json) {
    final explicit = json['photo']?.toString().trim() ?? '';
    if (_isHttpUrl(explicit)) return explicit;
    return '';
  }

  static String playerCdnPhotoUrl(int id) =>
      'https://media.api-sports.io/football/players/$id.png';

  static bool _isHttpUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    final trimmed = value.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  /// API-Football CDN flag asset from ISO country code.
  static String flagUrlFromCountryCode(String code) {
    final normalized = code.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    return 'https://media.api-sports.io/flags/$normalized.svg';
  }
}

class _CountryFields {
  const _CountryFields({this.name = '', this.code = '', this.flagUrl = ''});

  final String name;
  final String code;
  final String flagUrl;
}
