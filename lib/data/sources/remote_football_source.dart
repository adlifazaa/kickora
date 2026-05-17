import '../../core/cache/cache_manager.dart';
import '../../core/cache/cache_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/api_mode.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_debug_log.dart';
import '../models/competition_model.dart';
import '../models/formation_model.dart';
import '../models/lineup_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/standing_model.dart';
import '../models/team_model.dart';
import '../services/api_football_parser.dart';
import '../services/api_football/api_football_service.dart';
import '../services/backend_proxy/backend_proxy_service.dart';

/// Routes football remote calls by [ApiMode] when credentials are configured.
///
/// `mock` (default): inactive — [FootballRepository] uses [MockData].
/// `directApi` + key → [ApiFootballService].
/// `backendProxy` + URL → [BackendProxyService].
class RemoteFootballSource {
  RemoteFootballSource({
    CacheManager? cache,
    ApiFootballService? apiFootball,
    BackendProxyService? backendProxy,
  })  : _cache = cache != null ? CacheService(cache) : null,
        _apiFootball = apiFootball ?? ApiFootballService(),
        _backendProxy = backendProxy ?? BackendProxyService(cache: cache);

  final CacheService? _cache;
  final ApiFootballService _apiFootball;
  final BackendProxyService _backendProxy;

  static bool get isRemoteActive {
    if (ApiConstants.isMock) return false;
    if (ApiConstants.isDirectApi) return ApiConstants.hasApiKey;
    if (ApiConstants.isBackendProxy) return ApiConstants.hasBackendUrl;
    return false;
  }

  /// @deprecated Use [isRemoteActive].
  static bool get isRemoteLiveActive => isRemoteActive;

  String get _sourceLabel {
    if (ApiConstants.isDirectApi) return 'directApi';
    if (ApiConstants.isBackendProxy) return 'backendProxy';
    return 'mock';
  }

  void _ensureActive() {
    if (!isRemoteActive) throw const ApiException.notConfigured();
  }

  void _log(String operation, String source, int count) {
    ApiDebugLog.dataSource(
      operation: operation,
      source: source,
      count: count,
      message: 'mode=${ApiConstants.apiMode.name}',
    );
  }

  // --- Matches ---

  Future<List<MatchModel>> fetchLiveMatches({
    int? competitionId,
    bool skipCache = false,
  }) =>
      _fetchMatches(
        operation: 'getLiveMatches',
        cacheKey: _matchCacheKey('live', league: competitionId),
        bucket: CacheBucket.liveMatches,
        skipCache: skipCache,
        fetch: () => _apiFootball.getLiveMatches(competitionId: competitionId),
        fetchBackend: () =>
            _backendProxy.getLiveMatches(competitionId: competitionId),
      );

  Future<List<MatchModel>> fetchMatchesToday({
    DateTime? date,
    int? competitionId,
    bool skipCache = false,
  }) =>
      _fetchMatches(
        operation: 'getMatches',
        cacheKey: _matchCacheKey('today', date: date, league: competitionId),
        bucket: CacheBucket.todayMatches,
        skipCache: skipCache,
        fetch: () => _apiFootball.getMatchesToday(
          date: date,
          competitionId: competitionId,
        ),
        fetchBackend: () => _backendProxy.getMatchesToday(
          date: date,
          competitionId: competitionId,
        ),
      );

  Future<List<MatchModel>> fetchUpcomingMatches({
    DateTime? date,
    int? competitionId,
    bool skipCache = false,
  }) =>
      _fetchMatches(
        operation: 'getUpcomingMatches',
        cacheKey: _matchCacheKey('upcoming', date: date, league: competitionId),
        bucket: CacheBucket.upcomingMatches,
        skipCache: skipCache,
        fetch: () => _apiFootball.getUpcomingMatches(
          date: date,
          competitionId: competitionId,
        ),
        fetchBackend: () => _backendProxy.getUpcomingMatches(
          date: date,
          competitionId: competitionId,
        ),
      );

  Future<List<MatchModel>> fetchFinishedMatches({
    DateTime? date,
    int? competitionId,
    bool skipCache = false,
  }) =>
      _fetchMatches(
        operation: 'getFinishedMatches',
        cacheKey: _matchCacheKey('finished', date: date, league: competitionId),
        bucket: CacheBucket.finishedMatches,
        skipCache: skipCache,
        fetch: () => _apiFootball.getFinishedMatches(
          date: date,
          competitionId: competitionId,
        ),
        fetchBackend: () => _backendProxy.getFinishedMatches(
          date: date,
          competitionId: competitionId,
        ),
      );

  List<MatchModel>? readCachedMatches({
    required String kind,
    DateTime? date,
    int? competitionId,
    CacheBucket? bucket,
  }) =>
      _readMatches(
        _matchCacheKey(kind, date: date, league: competitionId),
        bucket ?? CacheBucket.todayMatches,
      );

  Future<void> invalidateLiveMatches({int? competitionId}) async {
    await _cache?.remove(_matchCacheKey('live', league: competitionId));
  }

  Future<void> invalidateMatchList({
    required String kind,
    DateTime? date,
    int? competitionId,
  }) async {
    await _cache?.remove(
      _matchCacheKey(kind, date: date, league: competitionId),
    );
  }

  // --- Competitions / teams / standings / players ---

  Future<List<CompetitionModel>> fetchCompetitions({
    bool skipCache = false,
  }) async {
    _ensureActive();
    const cacheKey = 'remote_competitions';
    if (!skipCache) {
      final cached = _readCompetitions(cacheKey);
      if (cached != null) {
        _log('getCompetitions', 'cache', cached.length);
        return cached;
      }
    }
    final list = await _call(
      () => _apiFootball.getCompetitions(),
      () => _backendProxy.getCompetitions(),
    );
    await _writeCompetitions(cacheKey, list);
    _log('getCompetitions', _sourceLabel, list.length);
    return list;
  }

  List<CompetitionModel>? readCachedCompetitions() =>
      _readCompetitions('remote_competitions');

  Future<List<StandingModel>> fetchStandings({
    required int leagueId,
    bool skipCache = false,
  }) async {
    _ensureActive();
    final cacheKey = 'remote_standings_$leagueId';
    if (!skipCache) {
      final cached = _readStandings(cacheKey);
      if (cached != null) {
        _log('getStandings', 'cache', cached.length);
        return cached;
      }
    }
    final list = await _call(
      () => _apiFootball.getStandings(leagueId: leagueId),
      () => _backendProxy.getStandings(competitionId: leagueId),
    );
    await _writeStandings(cacheKey, list);
    _log('getStandings', _sourceLabel, list.length);
    return list;
  }

  List<StandingModel>? readCachedStandings(int leagueId) =>
      _readStandings('remote_standings_$leagueId');

  Future<List<TeamModel>> fetchTeams({
    required int competitionId,
    bool skipCache = false,
  }) async {
    _ensureActive();
    final cacheKey = 'remote_teams_$competitionId';
    if (!skipCache) {
      final cached = _readTeams(cacheKey);
      if (cached != null) {
        _log('getCompetitionTeams', 'cache', cached.length);
        return cached;
      }
    }
    final list = await _call(
      () => _apiFootball.getTeams(competitionId: competitionId),
      () => _backendProxy.getTeams(competitionId: competitionId),
    );
    await _writeTeams(cacheKey, list);
    _log('getCompetitionTeams', _sourceLabel, list.length);
    return list;
  }

  List<TeamModel>? readCachedTeams(int competitionId) =>
      _readTeams('remote_teams_$competitionId');

  Future<List<PlayerModel>> searchPlayers(String query) async {
    _ensureActive();
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final list = await _call(
      () => _apiFootball.searchPlayers(trimmed),
      () => _backendProxy.searchPlayers(trimmed),
    );
    _log('searchPlayers', _sourceLabel, list.length);
    return list;
  }

  // --- Match details ---

  Future<MatchModel?> fetchMatchDetails(int matchId) async {
    _ensureActive();
    final cacheKey = 'remote_fixture_$matchId';
    final cached = _readMatches(cacheKey, CacheBucket.matchDetails);
    if (cached != null && cached.isNotEmpty) {
      _log('getMatchById', 'cache', 1);
      return cached.first;
    }
    final match = await _call(
      () => _apiFootball.getMatchDetails(matchId),
      () => _backendProxy.getMatchDetails(matchId),
    );
    if (match != null) {
      await _writeMatches(cacheKey, [match], CacheBucket.matchDetails);
    }
    _log('getMatchById', _sourceLabel, match == null ? 0 : 1);
    return match;
  }

  MatchModel? readCachedMatchDetails(int matchId) {
    final list = _readMatches('remote_fixture_$matchId', CacheBucket.matchDetails);
    return list == null || list.isEmpty ? null : list.first;
  }

  Future<List<MatchEventModel>> fetchMatchEvents(int matchId) async {
    _ensureActive();
    final list = await _call(
      () => _apiFootball.getMatchEvents(matchId),
      () => _backendProxy.getMatchEvents(matchId),
    );
    _log('getMatchEvents', _sourceLabel, list.length);
    return list;
  }

  Future<List<MatchStatisticModel>> fetchMatchStatistics(int matchId) async {
    _ensureActive();
    final list = await _call(
      () => _apiFootball.getMatchStatistics(matchId),
      () => _backendProxy.getMatchStatistics(matchId),
    );
    _log('getMatchStatistics', _sourceLabel, list.length);
    return list;
  }

  Future<({LineupModel? home, LineupModel? away})> fetchLineups(
    int matchId,
  ) async {
    _ensureActive();
    final lineups = await _call(
      () => _apiFootball.getLineups(matchId),
      () => _backendProxy.getLineups(matchId),
    );
    final count = (lineups.home != null ? 1 : 0) + (lineups.away != null ? 1 : 0);
    _log('getMatchLineups', _sourceLabel, count);
    return lineups;
  }

  Future<FormationModel?> fetchFormation(
    int matchId, {
    required bool isHome,
  }) async {
    final lineups = await fetchLineups(matchId);
    final lineup = isHome ? lineups.home : lineups.away;
    return lineup?.resolvedFormation;
  }

  // --- Internals ---

  Future<T> _call<T>(
    Future<T> Function() direct,
    Future<T> Function() backend,
  ) async {
    if (ApiConstants.isDirectApi) {
      if (!_apiFootball.isEnabled) throw const ApiException.notConfigured();
      return direct();
    }
    if (ApiConstants.isBackendProxy) {
      if (!_backendProxy.isEnabled) throw const ApiException.notConfigured();
      return backend();
    }
    throw const ApiException.notConfigured();
  }

  Future<List<MatchModel>> _fetchMatches({
    required String operation,
    required String cacheKey,
    required CacheBucket bucket,
    required bool skipCache,
    required Future<List<MatchModel>> Function() fetch,
    required Future<List<MatchModel>> Function() fetchBackend,
  }) async {
    _ensureActive();
    if (!skipCache) {
      final cached = _readMatches(cacheKey, bucket);
      if (cached != null) {
        _log(operation, 'cache', cached.length);
        return cached;
      }
    }
    final matches = await _call(fetch, fetchBackend);
    await _writeMatches(cacheKey, matches, bucket);
    _log(operation, _sourceLabel, matches.length);
    return matches;
  }

  String _matchCacheKey(String prefix, {DateTime? date, int? league}) {
    final d = date != null ? ApiConstants.formatDate(date) : 'any';
    return 'remote_${prefix}_${league ?? 'all'}_$d';
  }

  List<MatchModel>? _readMatches(String key, CacheBucket bucket) {
    final list = _cache?.readJsonList(key, bucket);
    if (list == null) return null;
    return list
        .whereType<Map>()
        .map(
          (e) => ApiFootballParser.parseFixture(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList(growable: false);
  }

  Future<void> _writeMatches(
    String key,
    List<MatchModel> matches,
    CacheBucket bucket,
  ) async {
    await _cache?.writeJsonList(
      key,
      matches.map(_matchToJson).toList(),
      bucket,
    );
  }

  Map<String, dynamic> _matchToJson(MatchModel m) => {
        'fixture': {
          'id': m.id,
          'date': m.date.toIso8601String(),
          'status': {'short': _statusShort(m.status)},
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
      };

  List<CompetitionModel>? _readCompetitions(String key) {
    final list = _cache?.readJsonList(key, CacheBucket.competitions);
    if (list == null) return null;
    return list
        .whereType<Map>()
        .map((e) => CompetitionModel.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<void> _writeCompetitions(
    String key,
    List<CompetitionModel> list,
  ) async {
    await _cache?.writeJsonList(
      key,
      list.map((c) => c.toJson()).toList(),
      CacheBucket.competitions,
    );
  }

  List<StandingModel>? _readStandings(String key) {
    final list = _cache?.readJsonList(key, CacheBucket.standings);
    if (list == null) return null;
    return list
        .whereType<Map>()
        .map((e) => StandingModel.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<void> _writeStandings(String key, List<StandingModel> list) async {
    await _cache?.writeJsonList(
      key,
      list
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
      CacheBucket.standings,
    );
  }

  List<TeamModel>? _readTeams(String key) {
    final list = _cache?.readJsonList(key, CacheBucket.teams);
    if (list == null) return null;
    return list
        .whereType<Map>()
        .map((e) => TeamModel.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<void> _writeTeams(String key, List<TeamModel> list) async {
    await _cache?.writeJsonList(
      key,
      list.map((t) => t.toJson()).toList(),
      CacheBucket.teams,
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
}
