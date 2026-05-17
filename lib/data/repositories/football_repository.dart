import '../../core/cache/cache_manager.dart';
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
import '../sources/live_matches_source.dart';

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
  LiveMatchesSource? _liveMatchesSource;

  bool get usesLiveApi => _provider.isRemote;

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
      if (LiveMatchesSource.isRemoteLiveActive) {
        await _liveSource.invalidate(competitionId: competitionId);
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
    final result = await _loadMatches(
      operation: 'getUpcomingMatches',
      cacheKey: 'cache_upcoming_matches',
      fetch: () => _provider.fetchUpcomingMatches(
        date: date,
        competitionId: competitionId,
        skipCache: forceRefresh,
      ),
      mock: () => MockData.matches()
          .where((m) => m.status == MatchStatus.upcoming)
          .toList(),
      filterCompetition: competitionId,
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
    final result = await _loadMatches(
      operation: 'getFinishedMatches',
      cacheKey: 'cache_finished_matches',
      fetch: () => _provider.fetchFinishedMatches(
        date: date,
        competitionId: competitionId,
        skipCache: forceRefresh,
      ),
      mock: () => MockData.matches()
          .where((m) => m.status == MatchStatus.finished)
          .toList(),
      filterCompetition: competitionId,
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
    final result = await _loadMatches(
      operation: 'getMatches',
      cacheKey: 'cache_all_matches',
      fetch: () => _provider.fetchMatches(
        date: date,
        competitionId: competitionId,
        skipCache: forceRefresh,
      ),
      mock: () => MockData.matches(),
      filterCompetition: competitionId,
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

    try {
      if (!_provider.isRemote) {
        return DataState.success(_mockMatchById(id), fromMock: true);
      }
      final remote = await _provider.fetchMatchById(fid);
      if (remote != null) {
        return DataState.success(
          remote.copyWith(fixtureId: fid),
          fromMock: false,
        );
      }
      if (allowMock) {
        return DataState.success(_mockMatchById(id), fromMock: true);
      }
      return const DataState.success(null, fromMock: false);
    } on ApiException catch (e) {
      if (e.isNotConfigured || allowMock) {
        return DataState.success(_mockMatchById(id), fromMock: true);
      }
      return const DataState.success(null, fromMock: false);
    } catch (_) {
      if (allowMock) {
        return DataState.success(_mockMatchById(id), fromMock: true);
      }
      return const DataState.success(null, fromMock: false);
    }
  }

  Future<DataState<List<MatchEventModel>>> getMatchEvents(
    int matchId, {
    int? fixtureId,
  }) async {
    final fid = _resolvedFixtureId(fixtureId, matchId);
    return _loadFixtureDetail(
      fixtureId: fid,
      allowMock: _allowMockFallback(fid),
      fetch: () => _provider.fetchMatchEvents(fid),
      mockValue: () => _mockMatchById(matchId)?.events ?? const [],
      emptyValue: () => const <MatchEventModel>[],
    );
  }

  Future<DataState<List<MatchStatisticModel>>> getMatchStatistics(
    int matchId, {
    int? fixtureId,
  }) async {
    final fid = _resolvedFixtureId(fixtureId, matchId);
    return _loadFixtureDetail(
      fixtureId: fid,
      allowMock: _allowMockFallback(fid),
      fetch: () => _provider.fetchMatchStatistics(fid),
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
    return _loadFixtureDetail(
      fixtureId: fid,
      allowMock: _allowMockFallback(fid),
      fetch: () => _provider.fetchMatchLineups(fid),
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
    return _loadFixtureDetail(
      fixtureId: fid,
      allowMock: _allowMockFallback(fid),
      fetch: () => _provider.fetchFormation(fid, isHome: isHome),
      mockValue: () => lineup?.resolvedFormation,
      emptyValue: () => null,
    );
  }

  Future<DataState<List<StandingModel>>> getStandings({
    int? leagueId,
    bool allowMockFallback = true,
    bool forceRefresh = false,
  }) async {
    if (!_provider.isRemote) {
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
      final data = await _provider.fetchStandings(leagueId: leagueId);
      final result = DataState.success(data, fromMock: false);
      _storeMemory(memKey, result, forceRefresh);
      return result;
    } on ApiException catch (e) {
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
    if (!_provider.isRemote) {
      final list = MockData.competitions;
      ApiDebugLog.dataSource(
        operation: operation,
        source: 'mock',
        count: list.length,
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
      final data = await _provider.fetchCompetitions();
      await _cache?.setJson('cache_competitions', {'ok': true});
      final source = data.isEmpty ? 'empty' : 'api';
      ApiDebugLog.dataSource(
        operation: operation,
        source: source,
        count: data.length,
      );
      final result = DataState.success(data, fromMock: false);
      _storeMemory(memKey, result, forceRefresh);
      return result;
    } on ApiException catch (e) {
      ApiDebugLog.dataSource(
        operation: operation,
        source: 'error',
        message: 'status=${e.statusCode} ${e.code ?? e.message}',
      );
      return DataState.failure(_friendlyError(e));
    } catch (e) {
      ApiDebugLog.dataSource(
        operation: operation,
        source: 'error',
        message: '$e',
      );
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
    if (!forceRefresh && _provider.isRemote) {
      final hit = _readMemory<List<TeamModel>>(memKey, ApiCachePolicy.teams);
      if (hit != null) return hit;
    } else if (forceRefresh) {
      _memory.remove(memKey);
    }
    final result = await _loadSimple(
      fetch: () => _provider.fetchTeams(competitionId: competitionId),
      mock: () => MockData.competitionTeams(competitionId),
    );
    if (!result.hasError) {
      _storeMemory(memKey, result, forceRefresh);
    }
    return result;
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

  LiveMatchesSource get _liveSource =>
      _liveMatchesSource ??= LiveMatchesSource(cache: _cache);

  Future<DataState<List<MatchModel>>> _loadLiveMatches({
    DateTime? date,
    int? competitionId,
    bool forceRefresh = false,
  }) async {
    if (!LiveMatchesSource.isRemoteLiveActive) {
      final list = _filterMatches(_mockLiveMatches(), competitionId);
      ApiDebugLog.dataSource(
        operation: 'getLiveMatches',
        source: 'mock',
        count: list.length,
        message: 'mode=${ApiConstants.apiMode.name}',
      );
      return DataState.success(list, fromMock: true);
    }

    try {
      final data = await _liveSource.fetch(
        competitionId: competitionId,
        skipCache: forceRefresh,
      );
      final filtered = _filterMatches(data, competitionId);
      await _cache?.setJson('cache_live_matches', {'ok': true});
      return DataState.success(filtered, fromMock: false);
    } on ApiException catch (e) {
      final stale = _liveSource.readCached(competitionId: competitionId);
      if (stale != null && stale.isNotEmpty) {
        final filtered = _filterMatches(stale, competitionId);
        ApiDebugLog.dataSource(
          operation: 'getLiveMatches',
          source: 'cache',
          count: filtered.length,
          message:
              'fallback mode=${ApiConstants.apiMode.name} after ${e.code ?? 'error'}',
        );
        return DataState.success(filtered, fromMock: false, fromCache: true);
      }
      ApiDebugLog.dataSource(
        operation: 'getLiveMatches',
        source: 'error',
        message:
            'mode=${ApiConstants.apiMode.name} status=${e.statusCode} ${e.code ?? e.message}',
      );
      return DataState.failure(_friendlyError(e));
    } catch (e) {
      final stale = _liveSource.readCached(competitionId: competitionId);
      if (stale != null && stale.isNotEmpty) {
        final filtered = _filterMatches(stale, competitionId);
        ApiDebugLog.dataSource(
          operation: 'getLiveMatches',
          source: 'cache',
          count: filtered.length,
          message: 'fallback mode=${ApiConstants.apiMode.name}',
        );
        return DataState.success(filtered, fromMock: false, fromCache: true);
      }
      ApiDebugLog.dataSource(
        operation: 'getLiveMatches',
        source: 'error',
        message: 'mode=${ApiConstants.apiMode.name} $e',
      );
      return DataState.failure(ApiErrorMessages.friendlyFromObject(e));
    }
  }

  Future<DataState<List<MatchModel>>> _loadMatches({
    required String operation,
    required String cacheKey,
    required Future<List<MatchModel>> Function() fetch,
    required List<MatchModel> Function() mock,
    int? filterCompetition,
  }) async {
    if (!_provider.isRemote) {
      final list = _filterMatches(mock(), filterCompetition);
      ApiDebugLog.dataSource(
        operation: operation,
        source: 'mock',
        count: list.length,
      );
      return DataState.success(list, fromMock: true);
    }

    try {
      final data = await fetch();
      final filtered = _filterMatches(data, filterCompetition);
      await _cache?.setJson(cacheKey, {'ok': true});
      final source = filtered.isEmpty ? 'empty' : 'api';
      ApiDebugLog.dataSource(
        operation: operation,
        source: source,
        count: filtered.length,
      );
      return DataState.success(filtered, fromMock: false);
    } on ApiException catch (e) {
      ApiDebugLog.dataSource(
        operation: operation,
        source: 'error',
        message: 'status=${e.statusCode} ${e.code ?? e.message}',
      );
      return DataState.failure(_friendlyError(e));
    } catch (e) {
      ApiDebugLog.dataSource(
        operation: operation,
        source: 'error',
        message: '$e',
      );
      return DataState.failure(ApiErrorMessages.friendlyFromObject(e));
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
    if (!_provider.isRemote) return true; // mock fallback allowed
    return MockData.isMockMatchId(fixtureId);
  }

  Future<DataState<T>> _loadFixtureDetail<T>({
    required int fixtureId,
    required bool allowMock,
    required Future<T> Function() fetch,
    required T Function() mockValue,
    required T Function() emptyValue,
  }) async {
    if (!_provider.isRemote) {
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
      return DataState.success(emptyValue(), fromMock: false);
    } catch (_) {
      if (allowMock) {
        return DataState.success(mockValue(), fromMock: true);
      }
      return DataState.success(emptyValue(), fromMock: false);
    }
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
