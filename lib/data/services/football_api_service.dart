import '../../core/cache/cache_manager.dart';
import '../../core/constants/api_cache_policy.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_debug_log.dart';
import '../mock_data.dart';
import 'football_api_routes.dart';
import '../models/competition_model.dart';
import '../models/formation_model.dart';
import '../models/lineup_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/standing_model.dart';
import '../models/team_model.dart';
import 'api_football_parser.dart';

/// Remote football data via API-Football (direct) or Kickora backend (proxy).
///
/// Without credentials ([KICKORA_API_KEY] or [KICKORA_BACKEND_BASE_URL]), throws
/// [ApiException.notConfigured] so [FootballRepository] uses mock data.
///
/// TODO(production): Use [ApiMode.backendProxy] for Play Store — do not ship API keys in Flutter.
class FootballApiService {
  FootballApiService({
    ApiClient? client,
    ApiProvider? provider,
    String? apiKey,
    CacheManager? cache,
  })  : _client = client ??
            ApiClient(
              baseUrl: ApiConstants.effectiveBaseUrl,
              apiKey: ApiConstants.isDirectApi
                  ? (apiKey ?? ApiConstants.apiKey)
                  : '',
              mode: ApiConstants.apiMode,
            ),
        _cache = cache,
        provider = provider ?? _defaultProvider();

  final ApiClient _client;
  final CacheManager? _cache;
  final ApiProvider provider;

  static ApiProvider _defaultProvider() {
    if (!ApiConstants.hasRemoteApi) return ApiProvider.mock;
    return ApiConstants.isBackendProxy
        ? ApiProvider.backend
        : ApiProvider.apiFootball;
  }

  int get _season => ApiConstants.currentSeason();

  bool get isLive =>
      _client.isConfigured && provider != ApiProvider.mock;

  void logApiMode() {
    ApiDebugLog.dataSource(
      operation: 'FootballApiService',
      source: isLive ? 'api' : 'mock',
      message:
          'mode=${ApiConstants.apiMode.name} configured=${_client.isConfigured} provider=$provider',
    );
  }

  Future<Map<String, dynamic>> _getRoute(ApiRouteRequest route) =>
      _client.get(route.path, queryParameters: route.queryParameters);

  // --- Matches ---

  Future<List<MatchModel>> fetchLiveMatches({
    DateTime? date,
    int? competitionId,
    bool skipCache = false,
  }) async {
    if (!isLive) throw const ApiException.notConfigured();

    final cacheKey = _cacheKey('live', date: date, league: competitionId);
    if (!skipCache) {
      final cached = _readMatchCache(cacheKey);
      if (cached != null) return cached;
    }

    final route = FootballApiRoutes.liveMatches(
      date: date,
      competitionId: competitionId,
      season: _season,
    );
    final response = await _getRoute(route);

    // `live=all` already scopes to in-play fixtures — do not drop rows here.
    var matches = ApiFootballParser.parseFixtures(response);

    if (matches.isEmpty && date != null) {
      matches = await fetchMatches(
        date: date,
        competitionId: competitionId,
        status: MatchStatus.live,
        skipCache: skipCache,
      );
    }

    await _writeMatchCache(
      cacheKey,
      matches,
      ttl: ApiCachePolicy.liveMatches,
    );
    return matches;
  }

  Future<List<MatchModel>> fetchUpcomingMatches({
    DateTime? date,
    int? competitionId,
    bool skipCache = false,
  }) =>
      fetchMatches(
        date: date ?? DateTime.now(),
        competitionId: competitionId,
        status: MatchStatus.upcoming,
        skipCache: skipCache,
      );

  Future<List<MatchModel>> fetchFinishedMatches({
    DateTime? date,
    int? competitionId,
    bool skipCache = false,
  }) =>
      fetchMatches(
        date: date ?? DateTime.now(),
        competitionId: competitionId,
        status: MatchStatus.finished,
        skipCache: skipCache,
      );

  Future<List<MatchModel>> fetchMatches({
    DateTime? date,
    int? competitionId,
    MatchStatus? status,
    bool skipCache = false,
  }) async {
    if (!isLive) throw const ApiException.notConfigured();

    final cacheKey = _cacheKey(
      'fixtures_${status?.name ?? 'all'}',
      date: date,
      league: competitionId,
    );
    if (!skipCache) {
      final cached = _readMatchCache(cacheKey);
      if (cached != null) {
        return status == null ? cached : _filterStatus(cached, status);
      }
    }

    final route = FootballApiRoutes.matchesByDate(
      date: date,
      competitionId: competitionId,
      status: status,
      season: _season,
    );
    final response = await _getRoute(route);

    var matches = ApiFootballParser.parseFixtures(response);
    if (status != null) {
      matches = _filterStatus(matches, status);
    }

    final ttl = switch (status) {
      MatchStatus.live => ApiCachePolicy.liveMatches,
      MatchStatus.upcoming => ApiCachePolicy.fixturesUpcoming,
      MatchStatus.finished => ApiCachePolicy.fixturesFinished,
      null => ApiCachePolicy.fixturesByDate,
    };
    await _writeMatchCache(cacheKey, matches, ttl: ttl);
    return matches;
  }

  /// Clears in-memory/disk fixture caches before a forced refresh.
  Future<void> invalidateMatchCaches({
    DateTime? date,
    int? competitionId,
  }) async {
    if (_cache == null) return;
    final prefixes = <String>[
      _cacheKey('live', date: date, league: competitionId),
      _cacheKey('fixtures_live', date: date, league: competitionId),
      _cacheKey('fixtures_upcoming', date: date, league: competitionId),
      _cacheKey('fixtures_finished', date: date, league: competitionId),
      _cacheKey('fixtures_all', date: date, league: competitionId),
    ];
    for (final key in prefixes) {
      await _cache.remove(key);
    }
  }

  Future<MatchModel?> fetchMatchById(
    int id, {
    bool skipCache = false,
  }) async {
    if (!isLive) throw const ApiException.notConfigured();

    final cacheKey = 'cache_fixture_$id';
    if (!skipCache) {
      final cached = _readMatchCache(cacheKey);
      if (cached != null && cached.isNotEmpty) return cached.first;
    }

    final response = await _getRoute(FootballApiRoutes.matchById(id));
    final list = ApiFootballParser.parseFixtures(response);
    if (list.isNotEmpty) {
      await _writeMatchCache(
        cacheKey,
        list,
        ttl: ApiCachePolicy.matchDetails,
      );
    }
    return list.isEmpty ? null : list.first;
  }

  Future<List<MatchEventModel>> fetchMatchEvents(int matchId) async {
    if (!isLive) throw const ApiException.notConfigured();

    final cacheKey = 'cache_events_$matchId';
    final cached = _cache?.getJsonList(cacheKey);
    if (cached != null) {
      return cached
          .whereType<Map>()
          .map((e) => MatchEventModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final fixture = await fetchMatchById(matchId);
    final response = await _getRoute(FootballApiRoutes.matchEvents(matchId));

    final events = ApiFootballParser.parseEvents(
      response,
      homeTeamId: fixture?.homeTeam.id,
      awayTeamId: fixture?.awayTeam.id,
    );

    await _cache?.setJsonList(
      cacheKey,
      events.map(_eventToJson).toList(),
      ttl: ApiCachePolicy.matchDetails,
    );
    return events;
  }

  Future<List<MatchStatisticModel>> fetchMatchStatistics(int matchId) async {
    if (!isLive) throw const ApiException.notConfigured();

    final cacheKey = 'cache_stats_$matchId';
    final cached = _cache?.getJsonList(cacheKey);
    if (cached != null) {
      return cached
          .whereType<Map>()
          .map((e) => MatchStatisticModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final response = await _getRoute(FootballApiRoutes.matchStatistics(matchId));
    final fixture = await fetchMatchById(matchId);
    final stats = ApiFootballParser.parseStatistics(
      response,
      homeTeamId: fixture?.homeTeam.id,
    );

    await _cache?.setJsonList(
      cacheKey,
      stats
          .map(
            (s) => {
              'title': s.title,
              'home': s.home,
              'away': s.away,
              'homeDisplay': s.homeValue,
              'awayDisplay': s.awayValue,
            },
          )
          .toList(),
      ttl: ApiCachePolicy.matchDetails,
    );
    return stats;
  }

  Future<({LineupModel? home, LineupModel? away})> fetchMatchLineups(
    int matchId,
  ) async {
    if (!isLive) throw const ApiException.notConfigured();

    final response = await _getRoute(FootballApiRoutes.matchLineups(matchId));
    final fixture = await fetchMatchById(matchId);
    return ApiFootballParser.parseLineups(
      response,
      homeTeamId: fixture?.homeTeam.id,
      awayTeamId: fixture?.awayTeam.id,
    );
  }

  Future<FormationModel?> fetchFormation(
    int matchId, {
    required bool isHome,
  }) async {
    final lineups = await fetchMatchLineups(matchId);
    final lineup = isHome ? lineups.home : lineups.away;
    return lineup?.resolvedFormation;
  }

  // --- Competitions / teams / standings / players ---

  Future<List<CompetitionModel>> fetchCompetitions() async {
    if (!isLive) throw const ApiException.notConfigured();

    const cacheKey = 'cache_competitions_list';
    final cached = _cache?.getJsonList(cacheKey);
    if (cached != null) {
      return cached
          .whereType<Map>()
          .map((e) => CompetitionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final response = await _getRoute(FootballApiRoutes.competitions());
    final leagues = ApiFootballParser.parseLeagues(response);

    await _cache?.setJsonList(
      cacheKey,
      leagues.map((c) => c.toJson()).toList(),
      ttl: ApiCachePolicy.competitions,
    );
    return leagues;
  }

  Future<CompetitionModel?> fetchCompetitionById(int id) async {
    if (!isLive) throw const ApiException.notConfigured();

    final response = await _getRoute(
      FootballApiRoutes.competitionById(id, season: _season),
    );
    final list = ApiFootballParser.parseLeagues(response);
    return list.isEmpty ? null : list.first;
  }

  Future<List<TeamModel>> fetchTeams({int? competitionId}) async {
    if (!isLive) throw const ApiException.notConfigured();
    // TODO(backend): expose teams via proxy; until then backend builds return empty.
    if (!FootballApiRoutes.supportsTeamsOnBackend) {
      return const [];
    }

    final cacheKey = 'cache_teams_${competitionId ?? 'all'}';
    final cached = _cache?.getJsonList(cacheKey);
    if (cached != null) {
      return cached
          .whereType<Map>()
          .map((e) => TeamModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final response = await _getRoute(
      FootballApiRoutes.teams(competitionId: competitionId, season: _season),
    );
    final teams = ApiFootballParser.parseTeams(response);

    await _cache?.setJsonList(
      cacheKey,
      teams.map((t) => t.toJson()).toList(),
      ttl: ApiCachePolicy.teams,
    );
    return teams;
  }

  Future<List<StandingModel>> fetchStandings({int? leagueId}) async {
    if (!isLive) throw const ApiException.notConfigured();
    if (leagueId == null) return const [];

    final cacheKey = 'cache_standings_$leagueId';
    final cached = _cache?.getJsonList(cacheKey);
    if (cached != null) {
      return cached
          .whereType<Map>()
          .map((e) => StandingModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final response = await _getRoute(
      FootballApiRoutes.standings(leagueId: leagueId, season: _season),
    );
    final standings = ApiFootballParser.parseStandings(response);

    await _cache?.setJsonList(
      cacheKey,
      standings
          .map(
            (s) => {
              'rank': s.position,
              'position': s.position,
              'team': s.team.toJson(),
              'played': s.played,
              'wins': s.wins,
              'draws': s.draws,
              'losses': s.losses,
              'goalDifference': s.goalDifference,
              'points': s.points,
            },
          )
          .toList(),
      ttl: ApiCachePolicy.standings,
    );
    return standings;
  }

  Future<List<PlayerModel>> fetchTopScorers(int competitionId) async {
    if (!isLive) throw const ApiException.notConfigured();
    if (!FootballApiRoutes.supportsTeamsOnBackend) {
      return const [];
    }

    final cacheKey = 'cache_scorers_$competitionId';
    final cached = _cache?.getJsonList(cacheKey);
    if (cached != null) {
      return cached
          .whereType<Map>()
          .map((e) => PlayerModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final response = await _getRoute(
      FootballApiRoutes.topScorers(competitionId: competitionId, season: _season),
    );
    final players = ApiFootballParser.parseTopScorers(response);

    await _cache?.setJsonList(
      cacheKey,
      players
          .map(
            (p) => {
              'id': p.id,
              'name': p.name,
              'shortName': p.shortName,
              'number': p.number,
              'nationality': p.nationality,
              'age': p.age,
              'position': p.position,
              'team': p.team,
              'teamLogoShort': p.teamLogoShort,
              'appearances': p.appearances,
              'goals': p.goals,
              'seasonRating': p.seasonRating,
            },
          )
          .toList(),
      ttl: const Duration(hours: 1),
    );
    return players;
  }

  Future<PlayerModel?> fetchPlayerById(int id) async {
    if (!isLive) throw const ApiException.notConfigured();
    if (!FootballApiRoutes.supportsTeamsOnBackend) {
      return null;
    }

    final response = await _getRoute(
      FootballApiRoutes.playerById(id: id, season: _season),
    );
    return ApiFootballParser.parsePlayer(response);
  }

  /// Rebuild client when credentials become available at runtime.
  Future<void> configureRealProvider({
    String? baseUrl,
    String? apiKey,
    ApiProvider? provider,
  }) async {
    // No-op placeholder: construct a new [FootballApiService] in app bootstrap.
  }

  List<MatchModel> debugMockMatches() => MockData.matches();

  // --- Cache helpers ---

  String _cacheKey(String prefix, {DateTime? date, int? league}) {
    final d = date != null ? ApiConstants.formatDate(date) : 'any';
    return 'cache_${prefix}_${league ?? 'all'}_$d';
  }

  List<MatchModel>? _readMatchCache(String key) {
    final list = _cache?.getJsonList(key);
    if (list == null) return null;
    return list
        .whereType<Map>()
        .map((e) => ApiFootballParser.parseFixture(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _writeMatchCache(
    String key,
    List<MatchModel> matches, {
    Duration ttl = const Duration(minutes: 3),
  }) async {
    await _cache?.setJsonList(
      key,
      matches
          .map(
            (m) => {
              'fixture': {
                'id': m.id,
                'date': m.date.toIso8601String(),
                'status': {'short': _statusShort(m.status), 'elapsed': null},
                'venue': {'name': m.stadium},
              },
              'league': {
                'id': m.competition.id,
                'name': m.competition.name,
                'country': m.competition.region,
                'logo': m.competition.logo,
              },
              'teams': {
                'home': m.homeTeam.toJson(),
                'away': m.awayTeam.toJson(),
              },
              'goals': {'home': m.homeScore, 'away': m.awayScore},
            },
          )
          .toList(),
      ttl: ttl,
    );
  }

  String _statusShort(MatchStatus status) {
    switch (status) {
      case MatchStatus.live:
        return '1H';
      case MatchStatus.finished:
        return 'FT';
      case MatchStatus.upcoming:
        return 'NS';
    }
  }

  List<MatchModel> _filterStatus(List<MatchModel> list, MatchStatus status) =>
      list.where((m) => m.status == status).toList();

  Map<String, dynamic> _eventToJson(MatchEventModel e) => {
        'minute': e.minute,
        'type': e.type.name,
        'playerName': e.playerName,
        'assistName': e.assistName,
        'detail': e.description,
        'isHome': e.isHome,
      };
}
