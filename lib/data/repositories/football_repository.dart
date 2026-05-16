import '../../core/cache/cache_manager.dart';
import '../../core/constants/api_cache_policy.dart';
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
import '../services/football_api_service.dart';

/// Single entry point for football data. Uses API when configured; otherwise mock.
class FootballRepository {
  FootballRepository({
    FootballApiService? api,
    CacheManager? cache,
  })  : _api = api ?? FootballApiService(),
        _cache = cache;

  final FootballApiService _api;
  final CacheManager? _cache;
  final RepositoryMemoryCache _memory = RepositoryMemoryCache();

  bool get usesLiveApi => _api.isLive;

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
      await _api.invalidateMatchCaches(
        date: date,
        competitionId: competitionId,
      );
    }
    final result = await _loadMatches(
      operation: 'getLiveMatches',
      cacheKey: 'cache_live_matches',
      fetch: () => _api.fetchLiveMatches(
        date: date,
        competitionId: competitionId,
        skipCache: forceRefresh,
      ),
      mock: () => MockData.matches()
          .where((m) => m.status == MatchStatus.live)
          .toList(),
      filterCompetition: competitionId,
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
      await _api.invalidateMatchCaches(
        date: date,
        competitionId: competitionId,
      );
    }
    final result = await _loadMatches(
      operation: 'getUpcomingMatches',
      cacheKey: 'cache_upcoming_matches',
      fetch: () => _api.fetchUpcomingMatches(
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
      await _api.invalidateMatchCaches(
        date: date,
        competitionId: competitionId,
      );
    }
    final result = await _loadMatches(
      operation: 'getFinishedMatches',
      cacheKey: 'cache_finished_matches',
      fetch: () => _api.fetchFinishedMatches(
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
          _readMemory<List<MatchModel>>(memKey, ApiCachePolicy.fixturesByDate);
      if (hit != null) return hit;
    } else {
      _memory.remove(memKey);
      await _api.invalidateMatchCaches(
        date: date,
        competitionId: competitionId,
      );
    }
    final result = await _loadMatches(
      operation: 'getMatches',
      cacheKey: 'cache_all_matches',
      fetch: () => _api.fetchMatches(
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
      if (!_api.isLive) {
        return DataState.success(_mockMatchById(id), fromMock: true);
      }
      final remote = await _api.fetchMatchById(fid);
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
      fetch: () => _api.fetchMatchEvents(fid),
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
      fetch: () => _api.fetchMatchStatistics(fid),
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
      fetch: () => _api.fetchMatchLineups(fid),
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
      fetch: () => _api.fetchFormation(fid, isHome: isHome),
      mockValue: () => lineup?.resolvedFormation,
      emptyValue: () => null,
    );
  }

  Future<DataState<List<StandingModel>>> getStandings({
    int? leagueId,
    bool allowMockFallback = true,
    bool forceRefresh = false,
  }) async {
    if (!_api.isLive) {
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
      final data = await _api.fetchStandings(leagueId: leagueId);
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
      return DataState.failure(e.toString());
    }
  }

  // --- Competitions / teams / standings / players ---

  Future<DataState<List<CompetitionModel>>> getCompetitions({
    bool forceRefresh = false,
  }) async {
    const operation = 'getCompetitions';
    if (!_api.isLive) {
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
      final data = await _api.fetchCompetitions();
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
      return DataState.failure(e.toString());
    }
  }

  Future<DataState<CompetitionModel?>> getCompetitionById(int id) async {
    try {
      if (!_api.isLive) {
        return DataState.success(_mockCompetitionById(id), fromMock: true);
      }
      final remote = await _api.fetchCompetitionById(id);
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
    if (!forceRefresh && _api.isLive) {
      final hit = _readMemory<List<TeamModel>>(memKey, ApiCachePolicy.teams);
      if (hit != null) return hit;
    } else if (forceRefresh) {
      _memory.remove(memKey);
    }
    final result = await _loadSimple(
      fetch: () => _api.fetchTeams(competitionId: competitionId),
      mock: () => MockData.competitionTeams(competitionId),
    );
    if (!result.hasError) {
      _storeMemory(memKey, result, forceRefresh);
    }
    return result;
  }

  Future<DataState<List<PlayerModel>>> getTopScorers(int competitionId) async {
    return _loadSimple(
      fetch: () => _api.fetchTopScorers(competitionId),
      mock: () => MockData.topScorers(competitionId),
    );
  }

  Future<DataState<PlayerModel?>> getPlayerById(int id) async {
    try {
      if (!_api.isLive) {
        return DataState.success(_mockPlayerById(id), fromMock: true);
      }
      final remote = await _api.fetchPlayerById(id);
      return DataState.success(remote ?? _mockPlayerById(id), fromMock: remote == null);
    } catch (_) {
      return DataState.success(_mockPlayerById(id), fromMock: true);
    }
  }

  // --- Helpers ---

  Future<DataState<List<MatchModel>>> _loadMatches({
    required String operation,
    required String cacheKey,
    required Future<List<MatchModel>> Function() fetch,
    required List<MatchModel> Function() mock,
    int? filterCompetition,
  }) async {
    if (!_api.isLive) {
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
      return DataState.failure(e.toString());
    }
  }

  DataState<T>? _readMemory<T>(String key, Duration ttl) {
    final cached = _memory.get<DataState<T>>(key, ttl);
    if (cached == null) return null;
    ApiDebugLog.dataSource(
      operation: key,
      source: 'memory',
      count: cached.data is List ? (cached.data as List).length : null,
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

  String _friendlyError(ApiException e) =>
      e.isRateLimited ? ApiCachePolicy.rateLimitMessageEn : e.message;

  int _resolvedFixtureId(int? fixtureId, int matchId) {
    if (fixtureId != null && fixtureId > 0) return fixtureId;
    return matchId;
  }

  bool _allowMockFallback(int fixtureId) {
    if (!_api.isLive) return true;
    return MockData.isMockMatchId(fixtureId);
  }

  Future<DataState<T>> _loadFixtureDetail<T>({
    required int fixtureId,
    required bool allowMock,
    required Future<T> Function() fetch,
    required T Function() mockValue,
    required T Function() emptyValue,
  }) async {
    if (!_api.isLive) {
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
      if (!_api.isLive) {
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
      return DataState.success(mock(), fromMock: true);
    } catch (_) {
      return DataState.success(mock(), fromMock: true);
    }
  }

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
