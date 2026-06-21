import '../../core/cache/cache_manager.dart';
import '../../core/cache/cache_service.dart';
import '../../core/constants/api_cache_policy.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/api_mode.dart';
import '../../core/constants/api_mode_service.dart';
import '../../core/competition/competition_season_resolver.dart';
import '../../core/constants/world_cup_config.dart';
import '../../core/world_cup/world_cup_discovery.dart';
import '../../core/world_cup/world_cup_priority.dart';
import '../../core/player/player_photo_resolver.dart';
import '../../core/errors/api_error_messages.dart';
import '../../core/errors/api_exception.dart';
import '../../core/debug/match_details_log.dart';
import '../../core/network/api_debug_log.dart';
import '../../core/state/data_state.dart';
import '../mock_data.dart';
import 'repository_memory_cache.dart';
import '../models/competition_model.dart';
import '../models/formation_model.dart';
import '../models/lineup_model.dart';
import '../models/match_model.dart';
import '../models/news_article_model.dart';
import '../models/player_model.dart';
import '../models/standing_group_model.dart';
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
                    mode: ApiModeService.isBackendProxy
                        ? ApiMode.backendProxy
                        : ApiMode.directApi,
                  )
                : FootballDataProviderFactory.create(cache: cache)),
        _cache = cache;

  final FootballDataProvider _provider;
  final CacheManager? _cache;
  final RepositoryMemoryCache _memory = RepositoryMemoryCache();
  final Map<String, Future<Object?>> _inFlight = {};
  RemoteFootballSource? _remoteSource;

  bool get _remoteFetchEnabled =>
      !_provider.isMock && RemoteFootballSource.isRemoteActive;

  bool get usesLiveApi => _remoteFetchEnabled;

  /// Resolves World Cup league id + season from cache or API before fixture calls.
  Future<void> ensureWorldCupReady() async {
    if (WorldCupDiscovery.isResolved) return;

    final cached = _remote.readCachedCompetitions();
    if (cached != null && cached.isNotEmpty) {
      CompetitionSeasonResolver.registerAll(cached);
      WorldCupDiscovery.applyFromCompetitions(cached);
      if (WorldCupDiscovery.isResolved) return;
    }

    if (!_remoteFetchEnabled) return;

    try {
      final wc = await _remote.fetchCompetitionById(WorldCupConfig.competitionId);
      if (wc != null) {
        CompetitionSeasonResolver.register(wc);
        WorldCupDiscovery.applyFromCompetition(wc);
      }
    } catch (_) {}
  }

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
      if (_remoteFetchEnabled) {
        await _remote.invalidateLiveMatches(competitionId: competitionId);
      }
    }
    return _dedupe(memKey, () async {
      final result = await _loadLiveMatches(
        date: date,
        competitionId: competitionId,
        forceRefresh: forceRefresh,
      );
      _storeMemory(memKey, result, forceRefresh);
      return result;
    });
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
    return _dedupe(memKey, () async {
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
    });
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
    return _dedupe(memKey, () async {
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
    });
  }

  Future<DataState<List<MatchModel>>> getMatches({
    DateTime? date,
    int? competitionId,
    bool forceRefresh = false,
  }) async {
    final effectiveDate = date ?? DateTime.now();

    // One global today fetch; filter client-side per competition.
    if (competitionId != null && _isSameCalendarDay(effectiveDate, DateTime.now())) {
      final scopedKey =
          _matchMemKey('all', date: effectiveDate, competitionId: competitionId);
      if (!forceRefresh) {
        final hit =
            _readMemory<List<MatchModel>>(scopedKey, ApiCachePolicy.todayMatches);
        if (hit != null) return hit;
      } else {
        _memory.remove(scopedKey);
      }
      return _dedupe(scopedKey, () async {
        final pool = await getMatches(
          date: effectiveDate,
          forceRefresh: forceRefresh,
        );
        if (pool.hasError) {
          return DataState.failure(pool.errorMessage ?? 'Could not load matches.');
        }
        final filtered = _filterMatches(pool.data ?? [], competitionId);
        final result = DataState.success(
          filtered,
          fromMock: pool.fromMock,
          fromCache: pool.fromCache,
        );
        _storeMemory(scopedKey, result, forceRefresh);
        return result;
      });
    }

    final memKey =
        _matchMemKey('all', date: effectiveDate, competitionId: competitionId);
    if (!forceRefresh) {
      final hit =
          _readMemory<List<MatchModel>>(memKey, ApiCachePolicy.todayMatches);
      if (hit != null) return hit;
    } else {
      _memory.remove(memKey);
      await _provider.invalidateMatchCaches(
        date: effectiveDate,
        competitionId: competitionId,
      );
    }
    return _dedupe(memKey, () async {
      final result = await _loadRemoteMatchList(
        operation: 'getMatches',
        kind: 'today',
        date: effectiveDate,
        competitionId: competitionId,
        forceRefresh: forceRefresh,
        mock: () => MockData.matches(),
        fetch: () => _remote.fetchMatchesToday(
          date: effectiveDate,
          competitionId: competitionId,
          skipCache: forceRefresh,
        ),
      );
      _storeMemory(memKey, result, forceRefresh);
      return result;
    });
  }

  /// All fixtures for a competition season — one upstream call (World Cup hub).
  Future<DataState<List<MatchModel>>> getCompetitionMatches(
    int competitionId, {
    int? season,
    bool forceRefresh = false,
  }) async {
    final resolvedSeason =
        season ?? CompetitionSeasonResolver.seasonForOrDefault(competitionId);
    final memKey = 'mem_competition_matches_${competitionId}_$resolvedSeason';
    if (!forceRefresh) {
      final hit = _readMemory<List<MatchModel>>(
        memKey,
        ApiCachePolicy.competitionFixtures,
      );
      if (hit != null) return hit;
    } else {
      _memory.remove(memKey);
    }
    return _dedupe(memKey, () async {
      if (!_remoteFetchEnabled) {
        return DataState.success(MockData.matches(), fromMock: true);
      }
      try {
        final data = await _remote.fetchCompetitionMatches(
          competitionId: competitionId,
          season: resolvedSeason,
          skipCache: forceRefresh,
        );
        final result = DataState.success(data, fromMock: false);
        _storeMemory(memKey, result, forceRefresh);
        return result;
      } on ApiException catch (e) {
        return DataState.failure(_friendlyError(e));
      } catch (e) {
        return DataState.failure(ApiErrorMessages.friendlyFromObject(e));
      }
    });
  }

  Future<DataState<MatchModel?>> getMatchById(
    int id, {
    int? fixtureId,
    bool forceRefresh = false,
  }) async {
    final fid = _resolvedFixtureId(fixtureId, id);
    final allowMock = _allowMockFallback(fid);
    final memKey = 'mem_match_$fid';
    final ttl = ApiCachePolicy.matchDetailResourceTtl(_knownFixtureStatus(fid, id));

    if (!_remoteFetchEnabled) {
      return DataState.success(_mockMatchById(id), fromMock: true);
    }

    if (!forceRefresh && !allowMock) {
      final hit = _readMemory<MatchModel?>(memKey, ttl);
      if (hit != null) return hit;
    }

    return _dedupe(memKey, () async {
      try {
        final remote = await _remote.fetchMatchDetails(
          fid,
          skipCache: forceRefresh,
        );
        if (remote != null) {
          _rememberFixtureStatus(fid, remote.status);
          final result = DataState.success(
            remote.copyWith(fixtureId: fid),
            fromMock: false,
          );
          _storeMemory(memKey, result, forceRefresh);
          return result;
        }
        final stale = _remote.readCachedMatchDetails(fid);
        if (stale != null) {
          _rememberFixtureStatus(fid, stale.status);
          final result = DataState.success(
            stale.copyWith(fixtureId: fid),
            fromMock: false,
            fromCache: true,
          );
          _storeMemory(memKey, result, forceRefresh);
          return result;
        }
        if (allowMock) {
          return DataState.success(_mockMatchById(id), fromMock: true);
        }
        return const DataState.success(null, fromMock: false);
      } on ApiException catch (e) {
        final stale = _remote.readCachedMatchDetails(fid);
        if (stale != null) {
          _rememberFixtureStatus(fid, stale.status);
          final result = DataState.success(
            stale.copyWith(fixtureId: fid),
            fromMock: false,
            fromCache: true,
          );
          _storeMemory(memKey, result, forceRefresh);
          return result;
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
    });
  }

  Future<DataState<List<MatchEventModel>>> getMatchEvents(
    int matchId, {
    int? fixtureId,
    int? leagueId,
  }) async {
    final fid = _resolvedFixtureId(fixtureId, matchId);
    final memKey = 'mem_events_$fid';
    final ttl = ApiCachePolicy.matchDetailResourceTtl(_knownFixtureStatus(fid, matchId));
    return _loadRemoteFixtureDetail(
      operation: 'getMatchEvents',
      endpoint: '/events',
      leagueId: leagueId ?? _mockMatchById(matchId)?.competition.id,
      fixtureId: fid,
      allowMock: _allowMockFallback(fid),
      memoryKey: memKey,
      memoryTtl: ttl,
      fetch: () => _remote.fetchMatchEvents(fid),
      mockValue: () => _mockMatchById(matchId)?.events ?? const [],
      emptyValue: () => const <MatchEventModel>[],
    );
  }

  Future<DataState<List<MatchStatisticModel>>> getMatchStatistics(
    int matchId, {
    int? fixtureId,
    int? leagueId,
  }) async {
    final fid = _resolvedFixtureId(fixtureId, matchId);
    final memKey = 'mem_stats_$fid';
    final ttl = ApiCachePolicy.matchDetailResourceTtl(_knownFixtureStatus(fid, matchId));
    return _loadRemoteFixtureDetail(
      operation: 'getMatchStatistics',
      endpoint: '/statistics',
      leagueId: leagueId ?? _mockMatchById(matchId)?.competition.id,
      fixtureId: fid,
      allowMock: _allowMockFallback(fid),
      memoryKey: memKey,
      memoryTtl: ttl,
      fetch: () => _remote.fetchMatchStatistics(fid),
      mockValue: () => _mockMatchById(matchId)?.stats ?? const [],
      emptyValue: () => const <MatchStatisticModel>[],
    );
  }

  Future<DataState<({LineupModel? home, LineupModel? away})>> getMatchLineups(
    int matchId, {
    int? fixtureId,
    int? leagueId,
  }) async {
    final fid = _resolvedFixtureId(fixtureId, matchId);
    final match = _mockMatchById(matchId);
    final memKey = 'mem_lineups_$fid';
    final ttl = ApiCachePolicy.matchDetailResourceTtl(_knownFixtureStatus(fid, matchId));
    return _loadRemoteFixtureDetail(
      operation: 'getMatchLineups',
      endpoint: '/lineups',
      leagueId: leagueId ?? match?.competition.id,
      fixtureId: fid,
      allowMock: _allowMockFallback(fid),
      memoryKey: memKey,
      memoryTtl: ttl,
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
    final memKey = 'mem_formation_${fid}_${isHome ? 'home' : 'away'}';
    final ttl = ApiCachePolicy.matchDetailResourceTtl(_knownFixtureStatus(fid, matchId));
    if (!_remoteFetchEnabled) {
      final lineup = isHome ? match?.homeLineup : match?.awayLineup;
      return DataState.success(lineup?.resolvedFormation, fromMock: true);
    }
    final hit = _readMemory<FormationModel?>(memKey, ttl);
    if (hit != null) return hit;

    return _dedupe(memKey, () async {
      final lineupsState = await getMatchLineups(
        matchId,
        fixtureId: fixtureId,
        leagueId: match?.competition.id,
      );
      if (lineupsState.hasError) {
        return DataState.failure(lineupsState.errorMessage ?? 'Could not load lineups.');
      }
      final lineup =
          isHome ? lineupsState.data?.home : lineupsState.data?.away;
      final formation = lineup?.resolvedFormation;
      final result = DataState.success(
        formation,
        fromMock: lineupsState.fromMock,
        fromCache: lineupsState.fromCache,
      );
      _storeMemory(memKey, result, false);
      return result;
    });
  }

  Future<DataState<List<StandingModel>>> getStandings({
    int? leagueId,
    bool allowMockFallback = true,
    bool forceRefresh = false,
  }) async {
    if (!_remoteFetchEnabled || leagueId == null) {
      return DataState.success(MockData.standings, fromMock: true);
    }
    final memKey = 'mem_standings_$leagueId';
    if (!forceRefresh) {
      final hit =
          _readMemory<List<StandingModel>>(memKey, ApiCachePolicy.standings);
      if (hit != null) return hit;
      final disk = _remote.readCachedStandings(leagueId);
      if (disk != null && disk.isNotEmpty) {
        final cached = DataState.success(disk, fromMock: false, fromCache: true);
        _storeMemory(memKey, cached, false);
        ApiDebugLog.dataSource(
          operation: 'getStandings',
          source: 'cache-disk',
          count: disk.length,
        );
        _scheduleQuietRefresh(
          () => _refreshStandingsQuietly(leagueId, memKey),
        );
        return cached;
      }
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

  Future<DataState<List<StandingGroupModel>>> getStandingGroups({
    int? leagueId,
    bool allowMockFallback = true,
    bool forceRefresh = false,
  }) async {
    if (!_remoteFetchEnabled || leagueId == null) {
      final flat = MockData.standings;
      return DataState.success(
        [StandingGroupModel(name: 'Group A', rows: flat)],
        fromMock: true,
      );
    }
    final memKey = 'mem_standing_groups_$leagueId';
    if (!forceRefresh) {
      final hit = _readMemory<List<StandingGroupModel>>(
        memKey,
        ApiCachePolicy.standingGroups,
      );
      if (hit != null) return hit;
    } else {
      _memory.remove(memKey);
    }
    return _dedupe(memKey, () async {
      try {
        final groups =
            await _remote.fetchStandingGroups(leagueId: leagueId);
        final result = DataState.success(groups, fromMock: false);
        _storeMemory(memKey, result, forceRefresh);
        return result;
      } catch (e) {
        if (allowMockFallback) {
          final flat = MockData.standings;
          return DataState.success(
            [StandingGroupModel(name: 'Group A', rows: flat)],
            fromMock: true,
          );
        }
        return DataState.failure(ApiErrorMessages.friendlyFromObject(e));
      }
    });
  }

  // --- Competitions / teams / standings / players ---

  Future<DataState<List<CompetitionModel>>> getCompetitions({
    bool forceRefresh = false,
  }) async {
    const operation = 'getCompetitions';
    if (!_remoteFetchEnabled) {
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
      final disk = _remote.readCachedCompetitions();
      if (disk != null && disk.isNotEmpty) {
        final prioritized = await _finalizeCompetitions(disk);
        final cached = DataState.success(
          prioritized,
          fromMock: false,
          fromCache: true,
        );
        _storeMemory(memKey, cached, false);
        ApiDebugLog.dataSource(
          operation: operation,
          source: 'cache-disk',
          count: prioritized.length,
        );
        _scheduleQuietRefresh(() => _refreshCompetitionsQuietly(memKey));
        return cached;
      }
    } else {
      _memory.remove(memKey);
    }
    try {
      final data =
          await _remote.fetchCompetitions(skipCache: forceRefresh);
      final prioritized = await _finalizeCompetitions(data);
      final result = DataState.success(prioritized, fromMock: false);
      _storeMemory(memKey, result, forceRefresh);
      return result;
    } on ApiException catch (e) {
      final stale = _remote.readCachedCompetitions();
      if (stale != null && stale.isNotEmpty) {
        final prioritized = await _finalizeCompetitions(stale);
        return DataState.success(
          prioritized,
          fromMock: false,
          fromCache: true,
        );
      }
      return DataState.failure(_friendlyError(e));
    } catch (e) {
      return DataState.failure(ApiErrorMessages.friendlyFromObject(e));
    }
  }

  Future<DataState<CompetitionModel?>> getCompetitionById(int id) async {
    if (!_remoteFetchEnabled) {
      ApiDebugLog.dataSource(
        operation: 'getCompetitionById',
        source: 'mock',
        count: 1,
        message: 'mode=${ApiConstants.apiMode.name}',
      );
      return DataState.success(_mockCompetitionById(id), fromMock: true);
    }
    try {
      final remote = await _remote.fetchCompetitionById(id);
      return DataState.success(
        remote ?? _mockCompetitionById(id),
        fromMock: remote == null,
      );
    } on ApiException catch (e) {
      final stale = _remote.readCachedCompetitionById(id);
      if (stale != null) {
        return DataState.success(stale, fromMock: false, fromCache: true);
      }
      return DataState.failure(_friendlyError(e));
    } catch (e) {
      final stale = _remote.readCachedCompetitionById(id);
      if (stale != null) {
        return DataState.success(stale, fromMock: false, fromCache: true);
      }
      return DataState.failure(ApiErrorMessages.friendlyFromObject(e));
    }
  }

  Future<DataState<List<TeamModel>>> getCompetitionTeams(
    int competitionId, {
    bool forceRefresh = false,
  }) async {
    final memKey = 'mem_teams_$competitionId';
    if (!forceRefresh && _remoteFetchEnabled) {
      final hit = _readMemory<List<TeamModel>>(memKey, ApiCachePolicy.teams);
      if (hit != null) return hit;
      final disk = _remote.readCachedTeams(competitionId);
      if (disk != null && disk.isNotEmpty) {
        final cached = DataState.success(disk, fromMock: false, fromCache: true);
        _storeMemory(memKey, cached, false);
        ApiDebugLog.dataSource(
          operation: 'getCompetitionTeams',
          source: 'cache-disk',
          count: disk.length,
        );
        _scheduleQuietRefresh(
          () => _refreshTeamsQuietly(competitionId, memKey),
        );
        return cached;
      }
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
    if (!_remoteFetchEnabled) {
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

  Future<DataState<WorldCupNewsResult>> getWorldCupNews({
    bool forceRefresh = false,
  }) async {
    if (!_remoteFetchEnabled) {
      return const DataState.success(WorldCupNewsResult.notConfigured, fromMock: true);
    }
    const memKey = 'mem_world_cup_news';
    if (!forceRefresh) {
      final hit = _readMemory<WorldCupNewsResult>(
        memKey,
        ApiCachePolicy.worldCupNews,
      );
      if (hit != null) return hit;
    } else {
      _memory.remove(memKey);
    }
    return _dedupe(memKey, () async {
      try {
        final data = await _remote.fetchWorldCupNews();
        final result = DataState.success(data, fromMock: false);
        _storeMemory(memKey, result, forceRefresh);
        return result;
      } on ApiException catch (e) {
        return DataState.failure(_friendlyError(e));
      } catch (e) {
        return DataState.failure(ApiErrorMessages.friendlyFromObject(e));
      }
    });
  }

  Future<DataState<List<PlayerModel>>> getTopScorers(
    int competitionId, {
    bool forceRefresh = false,
  }) async {
    if (!_remoteFetchEnabled) {
      final list = MockData.topScorers(competitionId);
      ApiDebugLog.dataSource(
        operation: 'getTopScorers',
        source: 'mock',
        count: list.length,
        message: 'mode=${ApiConstants.apiMode.name}',
      );
      return DataState.success(list, fromMock: true);
    }
    final memKey = 'mem_top_scorers_$competitionId';
    if (!forceRefresh) {
      final hit = _readMemory<List<PlayerModel>>(
        memKey,
        ApiCachePolicy.topScorers,
      );
      if (hit != null) return hit;
      final stale = _remote.readCachedTopScorers(competitionId);
      if (stale != null && stale.isNotEmpty) {
        final cached = DataState.success(stale, fromMock: false, fromCache: true);
        _storeMemory(memKey, cached, false);
        return cached;
      }
    } else {
      _memory.remove(memKey);
    }
    return _dedupe(memKey, () async {
      try {
        final data = await _remote.fetchTopScorers(competitionId);
        final result = DataState.success(data, fromMock: false);
        _storeMemory(memKey, result, forceRefresh);
        return result;
      } on ApiException catch (e) {
        final stale = _remote.readCachedTopScorers(competitionId);
        if (stale != null && stale.isNotEmpty) {
          return DataState.success(stale, fromMock: false, fromCache: true);
        }
        return DataState.failure(_friendlyError(e));
      } catch (e) {
        final stale = _remote.readCachedTopScorers(competitionId);
        if (stale != null && stale.isNotEmpty) {
          return DataState.success(stale, fromMock: false, fromCache: true);
        }
        return DataState.failure(ApiErrorMessages.friendlyFromObject(e));
      }
    });
  }

  Future<DataState<PlayerModel?>> getPlayerById(int id) async {
    final memKey = 'player_profile_$id';
    if (!_remoteFetchEnabled) {
      return DataState.success(_mockPlayerById(id), fromMock: true);
    }
    final cached =
        _memory.get<PlayerModel>(memKey, ApiCachePolicy.playerProfile);
    if (cached != null) {
      PlayerPhotoResolver.cacheProfilePhoto(id, cached.photoUrl);
      return DataState.success(cached, fromMock: false, fromCache: true);
    }
    final disk = _remote.readCachedPlayerById(id);
    if (disk != null) {
      _memory.put(memKey, disk);
      PlayerPhotoResolver.cacheProfilePhoto(id, disk.photoUrl);
      ApiDebugLog.dataSource(
        operation: 'getPlayerById',
        source: 'cache-disk',
        count: 1,
      );
      _scheduleQuietRefresh(() => _refreshPlayerQuietly(id, memKey));
      return DataState.success(disk, fromMock: false, fromCache: true);
    }
    try {
      final remote = await _remote.fetchPlayerById(id);
      final player = remote ?? _mockPlayerById(id);
      if (remote != null) {
        _memory.put(memKey, remote);
        PlayerPhotoResolver.cacheProfilePhoto(id, remote.photoUrl);
        return DataState.success(player, fromMock: false);
      }
      final stale = _remote.readCachedPlayerById(id);
      if (stale != null) {
        _memory.put(memKey, stale);
        PlayerPhotoResolver.cacheProfilePhoto(id, stale.photoUrl);
        return DataState.success(stale, fromMock: false, fromCache: true);
      }
      return DataState.success(player, fromMock: true);
    } on ApiException catch (e) {
      final stale = _remote.readCachedPlayerById(id);
      if (stale != null) {
        _memory.put(memKey, stale);
        PlayerPhotoResolver.cacheProfilePhoto(id, stale.photoUrl);
        return DataState.success(stale, fromMock: false, fromCache: true);
      }
      return DataState.failure(_friendlyError(e));
    } catch (e) {
      final stale = _remote.readCachedPlayerById(id);
      if (stale != null) {
        PlayerPhotoResolver.cacheProfilePhoto(id, stale.photoUrl);
        return DataState.success(stale, fromMock: false, fromCache: true);
      }
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
    if (!_remoteFetchEnabled) {
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
    if (!_remoteFetchEnabled) {
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
    String? endpoint,
    int? leagueId,
    bool Function(T value)? isEmpty,
    String? memoryKey,
    Duration? memoryTtl,
  }) async {
    if (!_remoteFetchEnabled) {
      return DataState.success(mockValue(), fromMock: true);
    }
    final dedupeKey = memoryKey ?? 'detail_${operation}_$fixtureId';
    if (memoryKey != null && memoryTtl != null) {
      final hit = _readMemory<T>(memoryKey, memoryTtl);
      if (hit != null) return hit;
    }
    final path = endpoint ?? operation;
    final leagueLabel = leagueId?.toString() ?? 'unknown';

    return _dedupe(dedupeKey, () async {
      try {
        final data = await fetch();
        final empty = isEmpty?.call(data) ?? _isEmptyDetailValue(data);
        logMatchDetailsEndpoint(
          matchId: fixtureId,
          league: leagueLabel,
          endpoint: path,
          statusCode: 200,
          itemCount: _detailItemCount(data),
          empty: empty,
          failed: false,
        );
        final result = DataState.success(data, fromMock: false);
        if (memoryKey != null) _storeMemory(memoryKey, result, false);
        return result;
      } on ApiException catch (e) {
        if (e.isNotConfigured || allowMock) {
          return DataState.success(mockValue(), fromMock: true);
        }
        if (e.isEmptyResponse) {
          final empty = emptyValue();
          logMatchDetailsEndpoint(
            matchId: fixtureId,
            league: leagueLabel,
            endpoint: path,
            statusCode: 200,
            itemCount: 0,
            empty: true,
            failed: false,
          );
          final result = DataState.success(empty, fromMock: false);
          if (memoryKey != null) _storeMemory(memoryKey, result, false);
          return result;
        }
        logMatchDetailsEndpoint(
          matchId: fixtureId,
          league: leagueLabel,
          endpoint: path,
          statusCode: e.statusCode ?? 0,
          itemCount: 0,
          empty: false,
          failed: true,
        );
        if (e.isRateLimited) {
          return DataState.failure(_friendlyError(e));
        }
        return DataState.failure(_friendlyError(e));
      } catch (e) {
        logMatchDetailsEndpoint(
          matchId: fixtureId,
          league: leagueLabel,
          endpoint: path,
          statusCode: 0,
          itemCount: 0,
          empty: false,
          failed: true,
        );
        if (allowMock) {
          return DataState.success(mockValue(), fromMock: true);
        }
        return DataState.failure(ApiErrorMessages.friendlyFromObject(e));
      }
    });
  }

  bool _isEmptyDetailValue(Object? value) {
    if (value == null) return true;
    if (value is List) return value.isEmpty;
    if (value is ({LineupModel? home, LineupModel? away})) {
      return value.home == null && value.away == null;
    }
    return false;
  }

  int _detailItemCount(Object? value) {
    if (value is List) return value.length;
    if (value is ({LineupModel? home, LineupModel? away})) {
      return (value.home != null ? 1 : 0) + (value.away != null ? 1 : 0);
    }
    return value == null ? 0 : 1;
  }

  bool _isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  MatchStatus _knownFixtureStatus(int fixtureId, int matchId) {
    final remembered = _memory.get<MatchStatus>(
      _fixtureStatusKey(fixtureId),
      const Duration(hours: 24),
    );
    if (remembered != null) return remembered;

    final disk = _remote.readCachedMatchDetails(fixtureId);
    if (disk != null) return disk.status;

    final mock = _mockMatchById(matchId);
    if (mock != null) return mock.status;

    return MatchStatus.upcoming;
  }

  void _rememberFixtureStatus(int fixtureId, MatchStatus status) {
    _memory.put(_fixtureStatusKey(fixtureId), status);
  }

  String _fixtureStatusKey(int fixtureId) => 'mem_fixture_status_$fixtureId';

  Future<DataState<T>> _dedupe<T>(
    String key,
    Future<DataState<T>> Function() action,
  ) async {
    final existing = _inFlight[key];
    if (existing != null) {
      ApiDebugLog.deduped(key);
      return await existing as Future<DataState<T>>;
    }
    final future = action();
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(key);
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

  void _scheduleQuietRefresh(Future<void> Function() action) {
    Future.microtask(action);
  }

  Future<void> _refreshCompetitionsQuietly(String memKey) async {
    try {
      final data = await _remote.fetchCompetitions(skipCache: true);
      final prioritized = await _finalizeCompetitions(data);
      _storeMemory(
        memKey,
        DataState.success(prioritized, fromMock: false),
        true,
      );
    } catch (_) {}
  }

  Future<List<CompetitionModel>> _finalizeCompetitions(
    List<CompetitionModel> raw,
  ) async {
    CompetitionSeasonResolver.registerAll(raw);
    WorldCupDiscovery.applyFromCompetitions(raw);
    var list = WorldCupPriority.applyCompetitionPriority(raw);
    if (WorldCupPriority.findWorldCup(list) != null || !_remoteFetchEnabled) {
      return list;
    }
    try {
      final wcState = await getCompetitionById(WorldCupConfig.competitionId);
      final wc = wcState.data;
      if (wc != null) {
        list = WorldCupPriority.applyCompetitionPriority(
          list,
          fetchedWorldCup: wc,
        );
      }
    } catch (_) {}
    return list;
  }

  Future<void> _refreshTeamsQuietly(int competitionId, String memKey) async {
    try {
      final data = await _remote.fetchTeams(
        competitionId: competitionId,
        skipCache: true,
      );
      _storeMemory(
        memKey,
        DataState.success(data, fromMock: false),
        true,
      );
    } catch (_) {}
  }

  Future<void> _refreshStandingsQuietly(int leagueId, String memKey) async {
    try {
      final data = await _remote.fetchStandings(
        leagueId: leagueId,
        skipCache: true,
      );
      _storeMemory(
        memKey,
        DataState.success(data, fromMock: false),
        true,
      );
    } catch (_) {}
  }

  Future<void> _refreshPlayerQuietly(int id, String memKey) async {
    try {
      final player = await _remote.fetchPlayerById(id);
      if (player != null) {
        _memory.put(memKey, player);
        PlayerPhotoResolver.cacheProfilePhoto(id, player.photoUrl);
      }
    } catch (_) {}
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
    if (!_remoteFetchEnabled) return true;
    return MockData.isMockMatchId(fixtureId);
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
