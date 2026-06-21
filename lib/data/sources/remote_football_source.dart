import '../../core/cache/cache_manager.dart';
import '../../core/cache/cache_service.dart';
import '../../core/constants/api_cache_policy.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/api_mode_service.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_debug_log.dart';
import '../models/news_article_model.dart';
import '../models/competition_model.dart';
import '../models/formation_model.dart';
import '../models/lineup_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/standing_group_model.dart';
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

  static bool get isRemoteActive => ApiModeService.usesRemoteApi;

  /// @deprecated Use [isRemoteActive].
  static bool get isRemoteLiveActive => isRemoteActive;

  String get _sourceLabel {
    if (ApiModeService.isDirectApi) return 'directApi';
    if (ApiModeService.isBackendProxy) return 'backendProxy';
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
  }) async {
    _ensureActive();
    final canonicalKey = _matchCacheKey('today', date: date, league: null);
    if (!skipCache) {
      final cached = _readMatches(canonicalKey, CacheBucket.todayMatches);
      if (cached != null) {
        final list = competitionId == null
            ? cached
            : cached.where((m) => m.competition.id == competitionId).toList();
        _log('getMatches', 'cache', list.length);
        return list;
      }
    }
    final all = await _call(
      () => _apiFootball.getMatchesToday(date: date, competitionId: competitionId),
      () => _backendProxy.getMatchesToday(date: date),
    );
    await _writeMatches(canonicalKey, all, CacheBucket.todayMatches);
    final list = competitionId == null
        ? all
        : all.where((m) => m.competition.id == competitionId).toList();
    _log('getMatches', _sourceLabel, list.length);
    return list;
  }

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

  Future<List<MatchModel>> fetchCompetitionMatches({
    required int competitionId,
    required int season,
    bool skipCache = false,
  }) async {
    _ensureActive();
    final cacheKey = 'remote_competition_matches_${competitionId}_$season';
    if (!skipCache) {
      final cached = _readMatches(cacheKey, CacheBucket.competitionFixtures);
      if (cached != null) {
        _log('getCompetitionMatches', 'cache', cached.length);
        return cached;
      }
    }
    final list = await _call(
      () => _apiFootball.fetchCompetitionFixtures(
        competitionId: competitionId,
        season: season,
      ),
      () => _backendProxy.getCompetitionMatches(
        competitionId: competitionId,
        season: season,
      ),
    );
    await _writeMatches(cacheKey, list, CacheBucket.competitionFixtures);
    _log('getCompetitionMatches', _sourceLabel, list.length);
    return list;
  }

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

  Future<List<StandingGroupModel>> fetchStandingGroups({
    required int leagueId,
    bool skipCache = false,
  }) async {
    _ensureActive();
    if (_backendProxy.isEnabled) {
      return _backendProxy.getStandingGroups(competitionId: leagueId);
    }
    final list = await fetchStandings(leagueId: leagueId, skipCache: skipCache);
    if (list.isEmpty) return const [];
    return [StandingGroupModel(name: 'Group A', rows: list)];
  }

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

  // --- Match details (lazy: only from match details screen via repository) ---

  Future<MatchModel?> fetchMatchDetails(
    int matchId, {
    bool skipCache = false,
  }) async {
    _ensureActive();
    final cacheKey = 'remote_fixture_$matchId';
    if (!skipCache) {
      final cached = _readMatches(cacheKey, CacheBucket.matchDetails);
      if (cached != null && cached.isNotEmpty) {
        _log('getMatchById', 'cache', 1);
        return cached.first;
      }
    }
    final match = await _call(
      () => _apiFootball.getMatchDetails(matchId),
      () => _backendProxy.getMatchDetails(matchId),
    );
    if (match != null) {
      await _writeMatches(
        cacheKey,
        [match],
        CacheBucket.matchDetails,
        ttl: ApiCachePolicy.matchDetailResourceTtl(match.status),
      );
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
    final cacheKey = 'remote_events_$matchId';
    final cached = _readMatchEvents(cacheKey);
    if (cached != null) {
      _log('getMatchEvents', 'cache', cached.length);
      return cached;
    }
    final list = await _call(
      () => _apiFootball.getMatchEvents(matchId),
      () => _backendProxy.getMatchEvents(matchId),
    );
    await _writeMatchEvents(cacheKey, list, ttl: _detailDiskTtl(matchId));
    _log('getMatchEvents', _sourceLabel, list.length);
    return list;
  }

  Future<List<MatchStatisticModel>> fetchMatchStatistics(int matchId) async {
    _ensureActive();
    final cacheKey = 'remote_stats_$matchId';
    final cached = _readMatchStatistics(cacheKey);
    if (cached != null) {
      _log('getMatchStatistics', 'cache', cached.length);
      return cached;
    }
    final list = await _call(
      () => _apiFootball.getMatchStatistics(matchId),
      () => _backendProxy.getMatchStatistics(matchId),
    );
    await _writeMatchStatistics(cacheKey, list, ttl: _detailDiskTtl(matchId));
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

  Duration _detailDiskTtl(int matchId) {
    final status = readCachedMatchDetails(matchId)?.status;
    if (status == null) return ApiCachePolicy.matchDetails;
    return ApiCachePolicy.matchDetailResourceTtl(status);
  }

  Future<FormationModel?> fetchFormation(
    int matchId, {
    required bool isHome,
  }) async {
    final lineups = await fetchLineups(matchId);
    final lineup = isHome ? lineups.home : lineups.away;
    return lineup?.resolvedFormation;
  }

  // --- Competition / players (extended) ---

  Future<CompetitionModel?> fetchCompetitionById(int id) async {
    _ensureActive();
    final cacheKey = 'remote_competition_$id';
    final cached = _readCompetitions(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      _log('getCompetitionById', 'cache', 1);
      return cached.first;
    }
    final competition = await _call(
      () => _apiFootball.getCompetitionById(id),
      () => _backendProxy.getCompetitionById(id),
    );
    if (competition != null) {
      await _cache?.writeJsonList(
        cacheKey,
        [competition.toJson()],
        CacheBucket.competitions,
      );
    }
    _log('getCompetitionById', _sourceLabel, competition == null ? 0 : 1);
    return competition;
  }

  CompetitionModel? readCachedCompetitionById(int id) {
    final list = _readCompetitions('remote_competition_$id');
    return list == null || list.isEmpty ? null : list.first;
  }

  Future<List<PlayerModel>> fetchTopScorers(
    int competitionId, {
    bool skipCache = false,
  }) async {
    _ensureActive();
    final cacheKey = 'remote_scorers_$competitionId';
    if (!skipCache) {
      final cached = _readPlayers(cacheKey);
      if (cached != null) {
        _log('getTopScorers', 'cache', cached.length);
        return cached;
      }
    }
    final list = await _call(
      () => _apiFootball.getTopScorers(competitionId),
      () => _backendProxy.getTopScorers(competitionId),
    );
    await _writePlayers(cacheKey, list);
    _log('getTopScorers', _sourceLabel, list.length);
    return list;
  }

  List<PlayerModel>? readCachedTopScorers(int competitionId) =>
      _readPlayers('remote_scorers_$competitionId');

  Future<WorldCupNewsResult> fetchWorldCupNews() async {
    _ensureActive();
    if (!ApiModeService.isBackendProxy) {
      return WorldCupNewsResult.notConfigured;
    }
    return _backendProxy.getWorldCupNews();
  }

  Future<PlayerModel?> fetchPlayerById(int id) async {
    _ensureActive();
    final cacheKey = 'remote_player_$id';
    final cached = _readPlayers(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      _log('getPlayerById', 'cache', 1);
      return cached.first;
    }
    final player = await _call(
      () => _apiFootball.getPlayerById(id),
      () => _backendProxy.getPlayerById(id),
    );
    if (player != null) {
      await _writePlayers(cacheKey, [player]);
    }
    _log('getPlayerById', _sourceLabel, player == null ? 0 : 1);
    return player;
  }

  PlayerModel? readCachedPlayerById(int id) {
    final list = _readPlayers('remote_player_$id');
    return list == null || list.isEmpty ? null : list.first;
  }

  // --- Internals ---

  Future<T> _call<T>(
    Future<T> Function() direct,
    Future<T> Function() backend,
  ) async {
    if (ApiModeService.isDirectApi) {
      if (!_apiFootball.isEnabled) throw const ApiException.notConfigured();
      return direct();
    }
    if (ApiModeService.isBackendProxy) {
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
        .map((e) => _matchFromCacheJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  MatchModel _matchFromCacheJson(Map<String, dynamic> json) {
    final parsed = ApiFootballParser.parseFixture(json);
    final meta = json['_kickora'];
    if (meta is! Map) return parsed;
    final map = Map<String, dynamic>.from(meta);
    final statusRaw = map['status']?.toString();
    final timeLabel = map['timeLabel']?.toString();
    return parsed.copyWith(
      status: statusRaw != null ? parseMatchStatus(statusRaw) : parsed.status,
      timeLabel: (timeLabel != null && timeLabel.isNotEmpty)
          ? timeLabel
          : parsed.timeLabel,
    );
  }

  Future<void> _writeMatches(
    String key,
    List<MatchModel> matches,
    CacheBucket bucket, {
    Duration? ttl,
  }) async {
    await _cache?.writeJsonList(
      key,
      matches.map(_matchToJson).toList(),
      bucket,
      ttl: ttl,
    );
  }

  Map<String, dynamic> _matchToJson(MatchModel m) => {
        'fixture': {
          'id': m.resolvedFixtureId,
          'date': m.date.toUtc().toIso8601String(),
          'status': {
            'short': _apiStatusShort(m),
            if (_elapsedMinutes(m) != null) 'elapsed': _elapsedMinutes(m),
          },
          'venue': {'name': m.stadium},
        },
        'league': {
          'id': m.competition.id,
          'name': m.competition.name,
          'country': m.competition.region,
          'logo': m.competition.logo,
          'round': m.round,
        },
        'teams': {
          'home': m.homeTeam.toJson(),
          'away': m.awayTeam.toJson(),
        },
        'goals': {'home': m.homeScore, 'away': m.awayScore},
        'score': {
          'fulltime': {'home': m.homeScore, 'away': m.awayScore},
        },
        '_kickora': {
          'timeLabel': m.timeLabel,
          'status': m.status.name,
        },
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

  List<PlayerModel>? _readPlayers(String key) {
    final list = _cache?.readJsonList(key, CacheBucket.playerProfile);
    if (list == null) return null;
    return list
        .whereType<Map>()
        .map((e) => PlayerModel.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<void> _writePlayers(String key, List<PlayerModel> list) async {
    await _cache?.writeJsonList(
      key,
      list.map(_playerToJson).toList(),
      CacheBucket.playerProfile,
    );
  }

  List<MatchEventModel>? _readMatchEvents(String key) {
    final list = _cache?.readJsonList(key, CacheBucket.matchEvents);
    if (list == null) return null;
    return list
        .whereType<Map>()
        .map((e) => MatchEventModel.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<void> _writeMatchEvents(
    String key,
    List<MatchEventModel> list, {
    Duration? ttl,
  }) async {
    await _cache?.writeJsonList(
      key,
      list
          .map(
            (e) => {
              'minute': e.minute,
              'type': e.type.name,
              'playerName': e.playerName,
              'assistName': e.assistName,
              'detail': e.description,
              'isHome': e.isHome,
            },
          )
          .toList(),
      CacheBucket.matchEvents,
      ttl: ttl,
    );
  }

  List<MatchStatisticModel>? _readMatchStatistics(String key) {
    final list = _cache?.readJsonList(key, CacheBucket.matchStatistics);
    if (list == null) return null;
    return list
        .whereType<Map>()
        .map((e) => MatchStatisticModel.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<void> _writeMatchStatistics(
    String key,
    List<MatchStatisticModel> list, {
    Duration? ttl,
  }) async {
    await _cache?.writeJsonList(
      key,
      list
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
      CacheBucket.matchStatistics,
      ttl: ttl,
    );
  }

  Map<String, dynamic> _playerToJson(PlayerModel p) => {
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
        if (p.photoUrl.isNotEmpty) 'photoUrl': p.photoUrl,
      };

  String _apiStatusShort(MatchModel m) {
    if (m.timeLabel == 'HT') return 'HT';
    if (m.status == MatchStatus.finished) return 'FT';
    if (m.status == MatchStatus.upcoming) return 'NS';
    final minute = _elapsedMinutes(m);
    if (minute != null && minute > 45) return '2H';
    return '1H';
  }

  int? _elapsedMinutes(MatchModel m) {
    if (m.timeLabel == 'HT') return 45;
    if (m.timeLabel == 'FT') return 90;
    final raw = RegExp(r'^(\d+)').firstMatch(m.timeLabel)?.group(1);
    if (raw == null) return null;
    return int.tryParse(raw);
  }
}
