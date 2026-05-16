import '../../core/cache/cache_manager.dart';
import '../../core/errors/api_exception.dart';
import '../../core/state/data_state.dart';
import '../mock_data.dart';
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

  bool get usesLiveApi => _api.isLive;

  // --- Matches ---

  Future<DataState<List<MatchModel>>> getLiveMatches({
    DateTime? date,
    int? competitionId,
  }) =>
      _loadMatches(
        cacheKey: 'cache_live_matches',
        fetch: () => _api.fetchLiveMatches(
          date: date,
          competitionId: competitionId,
        ),
        mock: () => MockData.matches()
            .where((m) => m.status == MatchStatus.live)
            .toList(),
        filterCompetition: competitionId,
      );

  Future<DataState<List<MatchModel>>> getUpcomingMatches({
    DateTime? date,
    int? competitionId,
  }) =>
      _loadMatches(
        cacheKey: 'cache_upcoming_matches',
        fetch: () => _api.fetchUpcomingMatches(
          date: date,
          competitionId: competitionId,
        ),
        mock: () => MockData.matches()
            .where((m) => m.status == MatchStatus.upcoming)
            .toList(),
        filterCompetition: competitionId,
      );

  Future<DataState<List<MatchModel>>> getFinishedMatches({
    DateTime? date,
    int? competitionId,
  }) =>
      _loadMatches(
        cacheKey: 'cache_finished_matches',
        fetch: () => _api.fetchFinishedMatches(
          date: date,
          competitionId: competitionId,
        ),
        mock: () => MockData.matches()
            .where((m) => m.status == MatchStatus.finished)
            .toList(),
        filterCompetition: competitionId,
      );

  Future<DataState<List<MatchModel>>> getMatches({
    DateTime? date,
    int? competitionId,
  }) =>
      _loadMatches(
        cacheKey: 'cache_all_matches',
        fetch: () => _api.fetchMatches(date: date, competitionId: competitionId),
        mock: () => MockData.matches(),
        filterCompetition: competitionId,
      );

  Future<DataState<MatchModel?>> getMatchById(int id) async {
    try {
      if (!_api.isLive) {
        return DataState.success(_mockMatchById(id), fromMock: true);
      }
      final remote = await _api.fetchMatchById(id);
      if (remote != null) return DataState.success(remote);
      return DataState.success(_mockMatchById(id), fromMock: true);
    } on ApiException catch (e) {
      if (e.isNotConfigured) {
        return DataState.success(_mockMatchById(id), fromMock: true);
      }
      return DataState.success(_mockMatchById(id), fromMock: true);
    } catch (_) {
      return DataState.success(_mockMatchById(id), fromMock: true);
    }
  }

  Future<DataState<List<MatchEventModel>>> getMatchEvents(int matchId) async {
    final mock = _mockMatchById(matchId)?.events ?? const [];
    return _loadSimple(
      fetch: () => _api.fetchMatchEvents(matchId),
      mock: () => mock,
    );
  }

  Future<DataState<List<MatchStatisticModel>>> getMatchStatistics(
    int matchId,
  ) async {
    final mock = _mockMatchById(matchId)?.stats ?? const [];
    return _loadSimple(
      fetch: () => _api.fetchMatchStatistics(matchId),
      mock: () => mock,
    );
  }

  Future<DataState<({LineupModel? home, LineupModel? away})>> getMatchLineups(
    int matchId,
  ) async {
    final match = _mockMatchById(matchId);
    return _loadSimple(
      fetch: () => _api.fetchMatchLineups(matchId),
      mock: () => (home: match?.homeLineup, away: match?.awayLineup),
    );
  }

  Future<DataState<FormationModel?>> getFormation(
    int matchId, {
    required bool isHome,
  }) async {
    final match = _mockMatchById(matchId);
    final lineup = isHome ? match?.homeLineup : match?.awayLineup;
    return _loadSimple(
      fetch: () => _api.fetchFormation(matchId, isHome: isHome),
      mock: () => lineup?.resolvedFormation,
    );
  }

  // --- Competitions / teams / standings / players ---

  Future<DataState<List<CompetitionModel>>> getCompetitions() async {
    return _loadSimple(
      cacheKey: 'cache_competitions',
      fetch: _api.fetchCompetitions,
      mock: () => MockData.competitions,
    );
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

  Future<DataState<List<TeamModel>>> getCompetitionTeams(int competitionId) async {
    return _loadSimple(
      fetch: () => _api.fetchTeams(competitionId: competitionId),
      mock: () => MockData.competitionTeams(competitionId),
    );
  }

  Future<DataState<List<StandingModel>>> getStandings({int? leagueId}) async {
    return _loadSimple(
      cacheKey: 'cache_standings_$leagueId',
      fetch: () => _api.fetchStandings(leagueId: leagueId),
      mock: () => MockData.standings,
    );
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
    required String cacheKey,
    required Future<List<MatchModel>> Function() fetch,
    required List<MatchModel> Function() mock,
    int? filterCompetition,
  }) async {
    try {
      if (!_api.isLive) {
        return DataState.success(_filterMatches(mock(), filterCompetition), fromMock: true);
      }
      final data = await fetch();
      if (data.isEmpty) {
        return DataState.success(_filterMatches(mock(), filterCompetition), fromMock: true);
      }
      await _cache?.setJson(cacheKey, {'ok': true});
      return DataState.success(_filterMatches(data, filterCompetition));
    } on ApiException catch (e) {
      if (e.isNotConfigured) {
        return DataState.success(_filterMatches(mock(), filterCompetition), fromMock: true);
      }
      return DataState.success(_filterMatches(mock(), filterCompetition), fromMock: true);
    } catch (_) {
      return DataState.success(_filterMatches(mock(), filterCompetition), fromMock: true);
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
