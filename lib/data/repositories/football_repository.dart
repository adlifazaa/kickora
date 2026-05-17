import '../../core/cache/cache_manager.dart';
import '../../core/cache/cache_service.dart';
import '../../core/constants/api_cache_policy.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/api_mode.dart';
import '../../core/player/player_photo_resolver.dart';
import '../../core/errors/api_error_messages.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_debug_log.dart';
import '../../core/state/data_state.dart';
import '../mock_data.dart';
import 'repository_memory_cache.dart';
import '../models/competition_model.dart';
import '../models/formation_model.dart';
import '../models/lineup_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/standing_model.dart';
import '../models/team_model.dart';
import '../providers/football_data_provider.dart';
import '../providers/football_data_provider_factory.dart';
import '../providers/remote_football_data_provider.dart';
import '../services/football_api_service.dart';
import '../sources/remote_football_source.dart';

/// Single entry point for football data. Uses API when configured; otherwise mock.
class FootballRepository {
  FootballRepository({
    FootballDataProvider? dataProvider,
    FootballApiService? api,
    CacheManager? cache,
  })  : _provider = dataProvider ??
            (api != null
                ? RemoteFootballDataProvider(
                    api,
                    mode: ApiConstants.isBackendProxy
                        ? ApiMode.backendProxy
                        : ApiMode.directApi,
                  )
                : FootballDataProviderFactory.create(cache: cache)),
        _cache = cache;

  final FootballDataProvider _provider;
  final CacheManager? _cache;
  final RepositoryMemoryCache _memory = RepositoryMemoryCache();
  RemoteFootballSource? _remoteSource;

  bool get usesLiveApi => RemoteFootballSource.isRemoteActive;

  // --- Matches ---

  Future<DataState<List<MatchModel>>> getLiveMatches({
    DateTime? date,
    int? competitionId,
    bool forceRefresh = false,
  }) async {
    final memKey = _matchMemKey('live', date: date, competitionId: competitionId);
    if (!forceRefresh) {
      final hit = _readMemory<List<MatchModel>>(memKey, ApiCachePolicy.liveMatches);
      if (hit != null) return hit;
    } else {
      _memory.remove(memKey);
      await _provider.invalidateMatchCaches(
        date: date,
        competitionId: competitionId,
      );
      if (RemoteFootballSource.isRemoteActive) {
        await _remote.invalidateLiveMatches(competitionId: competitionId);
      }
    }
    final result = await _loadLiveMatches(
      date: date,
      competitionId: competitionId,
      forceRefresh: forceRefresh,
    );
    _storeMemory(memKey, result, forceRefresh);
    return result;
  }

  Future<DataState<List<MatchModel>>> getUpcomingMatches({
    DateTime? date,
    int? competitionId,
    bool forceRefresh = false,
  }) async {
    final memKey =
        _matchMemKey('upcoming', date: date, competitionId: competitionId);
    if (!forceRefresh) {
      final hit =
          _readMemory<List<MatchModel>>(memKey, ApiCachePolicy.fixturesUpcoming);
      if (hit != null) return hit;
    } else {
      _memory.remove(memKey);
      await _provider.invalidateMatchCaches(
        date: date,
        competitionId: competitionId,
      );
    }
    final result = await _loadRemoteMatchList(
      operation: 'getUpcomingMatches',
      kind: 'upcoming',
      date: date,
      competitionId: competitionId,
      forceRefresh: forceRefresh,
      mock: () => MockData.matches()
          .where((m) => m.status == MatchStatus.upcoming)
          .toList(),
      fetch: () => _remote.fetchUpcomingMatches(
        date: date,
        competitionId: competitionId,
        skipCache: forceRefresh,
      ),
    );
    _storeMemory(memKey, result, forceRefresh);
    return result;
  }

  Future<DataState<List<MatchModel>>> getFinishedMatches({
    DateTime? date,
    int? competitionId,
    bool forceRefresh = false,
  }) async {
    final memKey =
        _matchMemKey('finished', date: date, competitionId: competitionId);
    if (!forceRefresh) {
      final hit =
          _readMemory<List<MatchModel>>(memKey, ApiCachePolicy.fixturesFinished);
      if (hit != null) return hit;
    } else {
      _memory.remove(memKey);
      await _provider.invalidateMatchCaches(
        date: date,
        competitionId: competitionId,
      );
    }
    final result = await _loadRemoteMatchList(
      operation: 'getFinishedMatches',
      kind: 'finished',
      date: date,
      competitionId: competitionId,
      forceRefresh: forceRefresh,
      mock: () => MockData.matches()
          .where((m) => m.status == MatchStatus.finished)
          .toList(),
      fetch: () => _remote.fetchFinishedMatches(
        date: date,
        competitionId: competitionId,
        skipCache: forceRefresh,
      ),
    );
    _storeMemory(memKey, result, forceRefresh);
    return result;
  }

  Future<DataState<List<MatchModel>>> getMatches({
    DateTime? date,
    int? competitionId,
    bool forceRefresh = false,
  }) async {
    final memKey = _matchMemKey('all', date: date, competitionId: competitionId);
    if (!forceRefresh) {
      final hit =
          _readMemory<List<MatchModel>>(memKey, ApiCachePolicy.todayMatches);
      if (hit != null) return hit;
    } else {
      _memory.remove(memKey);
      await _provider.invalidateMatchCaches(
        date: date,
        competitionId: competitionId,
      );
    }
    final result = await _loadRemoteMatchList(
      operation: 'getMatches',
      kind: 'today',
      date: date,
      competitionId: competitionId,
      forceRefresh: forceRefresh,
      mock: () => MockData.matches(),
      fetch: () => _remote.fetchMatchesToday(
        date: date,
        competitionId: competitionId,
        skipCache: forceRefresh,
      ),
    );
    _storeMemory(memKey, result, forceRefresh);
    return result;
  }

  Future<DataState<MatchModel?>> getMatchById(
    int id, {
    int? fixtureId,
  }) async {
    final fid = _resolvedFixtureId(fixtureId, id);
    final allowMock = _allowMockFallback(fid);

    if (!RemoteFootballSource.isRemoteActive) {
      return DataState.success(_mockMatchById(id), fromMock: true);
    }
    try {
      final remote = await _remote.fetchMatchDetails(fid);
      if (remote != null) {
        return DataState.success(
          remote.copyWith(fixtureId: fid),
          fromMock: false,
        );
      }
      final stale = _remote.readCachedMatchDetails(fid);
      if (stale != null) {
        return DataState.success(
          stale.copyWith(fixtureId: fid),
          fromMock: false,
          fromCache: true,
        );
      }
      if (allowMock) {
        return DataState.success(_mockMatchById(id), fromMock: true);
      }
      return const DataState.success(null, fromMock: false);
    } on ApiException catch (e) {
      final stale = _remote.readCachedMatchDetails(fid);
      if (stale != null) {
        return DataState.success(
          stale.copyWith(fixtureId: fid),
          fromMock: false,
          fromCache: true,
        );
      }
      if (e.isNotConfigured || allowMock) {
        return DataState.success(_mockMatchById(id), fromMock: true);
      }
      return DataState.failure(_friendlyError(e));
    } catch (e) {
      if (allowMock) {
        return DataState.success(_mockMatchById(id), fromMock: true);
      }
      return DataState.failure(ApiErrorMessages.friendlyFromObject(e));
    }
  }

  Future<DataState<List<MatchEventModel>>> getMatchEvents(
    int matchId, {
    int? fixtureId,
  }) async {
    final fid = _resolvedFixtureId(fixtureId, matchId);
    return _loadRemoteFixtureDetail(
      operation: 'getMatchEvents',
      fixtureId: fid,
      allowMock: _allowMockFallback(fid),
      fetch: () => _remote.fetchMatchEvents(fid),
      mockValue: () => _mockMatchById(matchId)?.events ?? const [],
      emptyValue: () => const <MatchEventModel>[],
    );
  }

  Future<DataState<List<MatchStatisticModel>>> getMatchStatistics(
    int matchId, {
    int? fixtureId,
  }) async {
    final fid = _resolvedFixtureId(fixtureId, matchId);
    return _loadRemoteFixtureDetail(
      operation: 'getMatchStatistics',
      fixtureId: fid,
      allowMock: _allowMockFallback(fid),
      fetch: () => _remote.fetchMatchStatistics(fid),
      mockValue: () => _mockMatchById(matchId)?.stats ?? const [],
      emptyValue: () => const <MatchStatisticModel>[],
    );
  }

  Future<DataState<({LineupModel? home, LineupModel? away})>> getMatchLineups(
    int matchId, {
    int? fixtureId,
  }) async {
    final fid = _resolvedFixtureId(fixtureId, matchId);
    final match = _mockMatchById(matchId);
    return _loadRemoteFixtureDetail(
      operation: 'getMatchLineups',
      fixtureId: fid,
      allowMock: _allowMockFallback(fid),
      fetch: () => _remote.fetchLineups(fid),
      mockValue: () => (home: match?.homeLineup, away: match?.awayLineup),
      emptyValue: () => (home: null, away: null),
    );
  }

  Future<DataState<FormationModel?>> getFormation(
    int matchId, {
    int? fixtureId,
    required bool isHome,
  }) async {
    final fid = _resolvedFixtureId(fixtureId, matchId);
    final match = _mockMatchById(matchId);
    final lineup = isHome ? match?.homeLineup : match?.awayLineup;
    return _loadRemoteFixtureDetail(
      operation: 'getFormation',
      fixtureId: fid,
      allowMock: _allowMockFallback(fid),
      fetch: () => _remote.fetchFormation(fid, isHome: isHome),
      mockValue: () => lineup?.resolvedFormation,
      emptyValue: () => null,
    );
  }

  Future<DataState<List<StandingModel>>> getStandings({
    int? leagueId,
    bool allowMockFallback = true,
    bool forceRefresh = false,
  }) async {
    if (!RemoteFootballSource.isRemoteActive || leagueId == null) {
      return DataState.success(MockData.standings, fromMock: true);
    }
    final memKey = 'mem_standings_$leagueId';
    if (!forceRefresh) {
      final hit =
          _readMemory<List<StandingModel>>(memKey, ApiCachePolicy.standings);
      if (hit != null) return hit;
    } else {
      _memory.remove(memKey);
    }
    try {
      final data = await _remote.fetchStandings(
        leagueId: leagueId,
        skipCache: forceRefresh,
      );
      final result = DataState.success(data, fromMock: false);
      _storeMemory(memKey, result, forceRefresh);
      return result;
    } on ApiException catch (e) {
      final stale = _remote.readCachedStandings(leagueId);
      if (stale != null && stale.isNotEmpty) {
        return DataState.success(stale, fromMock: false, fromCache: true);
      }
      if (e.isNotConfigured || allowMockFallback) {
        return DataState.success(MockData.standings, fromMock: true);
      }
      return DataState.failure(_friendlyError(e));
    } catch (e) {
      if (allowMockFallback) {
        return DataState.success(MockData.standings, fromMock: true);
      }
      return DataState.failure(ApiErrorMessages.friendlyFromObject(e));
    }
  }

  // --- Competitions / teams / standings / players ---

  Future<DataState<List<CompetitionModel>>> getCompetitions({
    bool forceRefresh = false,
  }) async {
    const operation = 'getCompetitions';
    if (!RemoteFootballSource.isRemoteActive) {
      final list = MockData.competitions;
      ApiDebugLog.dataSource(
        operation: operation,
        source: 'mock',
        count: list.length,
        message: 'mode=${ApiConstants.apiMode.name}',
      );
      return DataState.success(list, fromMock: true);
    }
    const memKey = 'mem_competitions';
    if (!forceRefresh) {
      final hit = _readMemory<List<CompetitionModel>>(
        memKey,
        ApiCachePolicy.competitions,
      );
      if (hit != null) return hit;
    } else {
      _memory.remove(memKey);
    }
    try {
      final data =
          await _remote.fetchCompetitions(skipCache: forceRefresh);
      final result = DataState.success(data, fromMock: false);
      _storeMemory(memKey, result, forceRefresh);
      return result;
    } on ApiException catch (e) {
      final stale = _remote.readCachedCompetitions();
      if (stale != null && stale.isNotEmpty) {
        return DataState.success(stale, fromMock: false, fromCache: true);
      }
      return DataState.failure(_friendlyError(e));
    } catch (e) {
      return DataState.failure(ApiErrorMessages.friendlyFromObject(e));
    }
  }

  Future<DataState<CompetitionModel?>> getCompetitionById(int id) async {
    try {
      if (!_provider.isRemote) {
        return DataState.success(_mockCompetitionById(id), fromMock: true);
      }
      final remote = await _provider.fetchCompetitionById(id);
      return DataState.success(remote ?? _mockCompetitionById(id), fromMock: remote == null);
    } catch (_) {
      return DataState.success(_mockCompetitionById(id), fromMock: true);
    }
  }

  Future<DataState<List<TeamModel>>> getCompetitionTeams(
    int competitionId, {
    bool forceRefresh = false,
  }) async {
    final memKey = 'mem_teams_$competitionId';
    if (!forceRefresh && RemoteFootballSource.isRemoteActive) {
      final hit = _readMemory<List<TeamModel>>(memKey, ApiCachePolicy.teams);
      if (hit != null) return hit;
    } else if (forceRefresh) {
      _memory.remove(memKey);
    }
    final result = await _loadRemoteTeams(
      competitionId: competitionId,
      forceRefresh: forceRefresh,
    );
    if (!result.hasError) {
      _storeMemory(memKey, result, forceRefresh);
    }
    return result;
  }

  Future<DataState<List<PlayerModel>>> searchPlayers(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const DataState.success(<PlayerModel>[]);
    }
    if (!RemoteFootballSource.isRemoteActive) {
      final lower = trimmed.toLowerCase();
      final list = MockData.players
          .where(
            (p) =>
                p.name.toLowerCase().contains(lower) ||
                p.team.toLowerCase().contains(lower),
          )
          .toList();
      ApiDebugLog.dataSource(
        operation: 'searchPlayers',
        source: 'mock',
        count: list.length,
        message: 'mode=${ApiConstants.apiMode.name}',
      );
      return DataState.success(list, fromMock: true);
    }
    try {
      final data = await _remote.searchPlayers(trimmed);
      return DataState.success(data, fromMock: false);
    } on ApiException catch (e) {
      return DataState.failure(_friendlyError(e));
    } catch (e) {
      return DataState.failure(ApiErrorMessages.friendlyFromObject(e));
    }
  }

  Future<DataState<List<PlayerModel>>> getTopScorers(int competitionId) async {
    return _loadSimple(
      fetch: () => _provider.fetchTopScorers(competitionId),
      mock: () => MockData.topScorers(competitionId),
    );
  }

  Future<DataState<PlayerModel?>> getPlayerById(int id) async {
    final memKey = 'player_profile_$id';
    if (!_provider.isRemote) {
      return DataState.success(_mockPlayerById(id), fromMock: true);
    }
    final cached =
        _memory.get<PlayerModel>(memKey, ApiCachePolicy.playerProfile);
    if (cached != null) {
      PlayerPhotoResolver.cacheProfilePhoto(id, cached.photoUrl);
      return DataState.success(cached, fromMock: false);
    }
    try {
      final remote = await _provider.fetchPlayerById(id);
      final player = remote ?? _mockPlayerById(id);
      if (remote != null) {
        _memory.put(memKey, remote);
        PlayerPhotoResolver.cacheProfilePhoto(id, remote.photoUrl);
      }
      return DataState.success(player, fromMock: remote == null);
    } catch (_) {
      return DataState.success(_mockPlayerById(id), fromMock: true);
    }
  }

  // --- Helpers ---

  RemoteFootballSource get _remote =>
      _remoteSource ??= RemoteFootballSource(cache: _cache);

  Future<DataState<List<MatchModel>>> _loadLiveMatches({
    DateTime? date,
    int? competitionId,
    bool forceRefresh = false,
  }) =>
      _loadRemoteMatchList(
        operation: 'getLiveMatches',
        kind: 'live',
        date: date,
        competitionId: competitionId,
        forceRefresh: forceRefresh,
        mock: _mockLiveMatches,
        fetch: () => _remote.fetchLiveMatches(
          competitionId: competitionId,
          skipCache: forceRefresh,
        ),
      );

  Future<DataState<List<MatchModel>>> _loadRemoteMatchList({
    required String operation,
    required String kind,
    DateTime? date,
    int? competitionId,
    bool forceRefresh = false,
    required List<MatchModel> Function() mock,
    required Future<List<MatchModel>> Function() fetch,
  }) async {
    if (!RemoteFootballSource.isRemoteActive) {
      final list = _filterMatches(mock(), competitionId);
      ApiDebugLog.dataSource(
        operation: operation,
        source: 'mock',
        count: list.length,
        message: 'mode=${ApiConstants.apiMode.name}',
      );
      return DataState.success(list, fromMock: true);
    }

    try {
      final data = await fetch();
      final filtered = _filterMatches(data, competitionId);
      return DataState.success(filtered, fromMock: false);
    } on ApiException catch (e) {
      final stale = _remote.readCachedMatches(
        kind: kind,
        date: date,
        competitionId: competitionId,
        bucket: _bucketForMatchKind(kind),
      );
      if (stale != null && stale.isNotEmpty) {
        final filtered = _filterMatches(stale, competitionId);
        ApiDebugLog.dataSource(
          operation: operation,
          source: 'cache',
          count: filtered.length,
          message:
              'fallback mode=${ApiConstants.apiMode.name} after ${e.code ?? 'error'}',
        );
        return DataState.success(filtered, fromMock: false, fromCache: true);
      }
      return DataState.failure(_friendlyError(e));
    } catch (e) {
      final stale = _remote.readCachedMatches(
        kind: kind,
        date: date,
        competitionId: competitionId,
        bucket: _bucketForMatchKind(kind),
      );
      if (stale != null && stale.isNotEmpty) {
        final filtered = _filterMatches(stale, competitionId);
        ApiDebugLog.dataSource(
          operation: operation,
          source: 'cache',
          count: filtered.length,
          message: 'fallback mode=${ApiConstants.apiMode.name}',
        );
        return DataState.success(filtered, fromMock: false, fromCache: true);
      }
      return DataState.failure(ApiErrorMessages.friendlyFromObject(e));
    }
  }

  Future<DataState<List<TeamModel>>> _loadRemoteTeams({
    required int competitionId,
    bool forceRefresh = false,
  }) async {
    if (!RemoteFootballSource.isRemoteActive) {
      return DataState.success(
        MockData.competitionTeams(competitionId),
        fromMock: true,
      );
    }
    try {
      final data = await _remote.fetchTeams(
        competitionId: competitionId,
        skipCache: forceRefresh,
      );
      return DataState.success(data, fromMock: false);
    } on ApiException catch (e) {
      final stale = _remote.readCachedTeams(competitionId);
      if (stale != null && stale.isNotEmpty) {
        return DataState.success(stale, fromMock: false, fromCache: true);
      }
      return DataState.failure(_friendlyError(e));
    } catch (e) {
      return DataState.failure(ApiErrorMessages.friendlyFromObject(e));
    }
  }

  Future<DataState<T>> _loadRemoteFixtureDetail<T>({
    required String operation,
    required int fixtureId,
    required bool allowMock,
    required Future<T> Function() fetch,
    required T Function() mockValue,
    required T Function() emptyValue,
  }) async {
    if (!RemoteFootballSource.isRemoteActive) {
      return DataState.success(mockValue(), fromMock: true);
    }
    try {
      final data = await fetch();
      return DataState.success(data, fromMock: false);
    } on ApiException catch (e) {
      if (e.isNotConfigured || allowMock) {
        return DataState.success(mockValue(), fromMock: true);
      }
      if (e.isRateLimited) {
        return DataState.failure(_friendlyError(e));
      }
      return DataState.failure(_friendlyError(e));
    } catch (e) {
      if (allowMock) {
        return DataState.success(mockValue(), fromMock: true);
      }
      return DataState.failure(ApiErrorMessages.friendlyFromObject(e));
    }
  }

  CacheBucket _bucketForMatchKind(String kind) {
    switch (kind) {
      case 'live':
        return CacheBucket.liveMatches;
      case 'upcoming':
        return CacheBucket.upcomingMatches;
      case 'finished':
        return CacheBucket.finishedMatches;
      default:
        return CacheBucket.todayMatches;
    }
  }

  DataState<T>? _readMemory<T>(String key, Duration ttl) {
    final cached = _memory.get<DataState<T>>(key, ttl);
    if (cached == null) {
      ApiDebugLog.cache(
        key: key,
        hit: false,
        bucket: 'memory',
        layer: 'memory',
      );
      return null;
    }
    ApiDebugLog.cache(
      key: key,
      hit: true,
      bucket: 'memory',
      layer: 'memory',
    );
    return cached.copyWith(fromCache: true);
  }

  void _storeMemory<T>(String key, DataState<T> state, bool forceRefresh) {
    if (forceRefresh || state.hasError) return;
    _memory.put(key, state);
  }

  String _matchMemKey(
    String kind, {
    DateTime? date,
    int? competitionId,
  }) {
    final d = date != null
        ? '${date.year}-${date.month}-${date.day}'
        : 'any';
    return 'mem_${kind}_${competitionId ?? 'all'}_$d';
  }

  String _friendlyError(ApiException e, {bool isArabic = false}) =>
      ApiErrorMessages.friendly(e, isArabic: isArabic);

  int _resolvedFixtureId(int? fixtureId, int matchId) {
    if (fixtureId != null && fixtureId > 0) return fixtureId;
    return matchId;
  }

  bool _allowMockFallback(int fixtureId) {
    if (!RemoteFootballSource.isRemoteActive) return true;
    return MockData.isMockMatchId(fixtureId);
  }

  Future<DataState<T>> _loadSimple<T>({
    String? cacheKey,
    required Future<T> Function() fetch,
    required T Function() mock,
  }) async {
    try {
      if (!_provider.isRemote) {
        return DataState.success(mock(), fromMock: true);
      }
      final data = await fetch();
      if (cacheKey != null) {
        await _cache?.setJson(cacheKey, {'ok': true});
      }
      return DataState.success(data);
    } on ApiException catch (e) {
      if (e.isNotConfigured) {
        return DataState.success(mock(), fromMock: true);
      }
      if (e.isRateLimited) {
        return DataState.failure(_friendlyError(e));
      }
      return DataState.failure(_friendlyError(e));
    } catch (e) {
      if (!_provider.isRemote) {
        return DataState.success(mock(), fromMock: true);
      }
      return DataState.failure(ApiErrorMessages.friendlyFromObject(e));
    }
  }

  List<MatchModel> _mockLiveMatches() => MockData.matches()
      .where((m) => m.status == MatchStatus.live)
      .toList();

  List<MatchModel> _filterMatches(List<MatchModel> list, int? competitionId) {
    if (competitionId == null) return list;
    return list.where((m) => m.competition.id == competitionId).toList();
  }

  MatchModel? _mockMatchById(int id) {
    try {
      return MockData.matches().firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  CompetitionModel? _mockCompetitionById(int id) {
    try {
      return MockData.competitions.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  PlayerModel? _mockPlayerById(int id) {
    try {
      return MockData.players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
