import '../../core/constants/api_mode.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_debug_log.dart';
import '../mock_data.dart';
import '../models/competition_model.dart';
import '../models/formation_model.dart';
import '../models/lineup_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/standing_model.dart';
import '../models/team_model.dart';
import 'football_data_provider.dart';

/// Local mock data — default for Play Store / MVP builds.
class MockFootballDataProvider implements FootballDataProvider {
  @override
  ApiMode get mode => ApiMode.mock;

  @override
  bool get isMock => true;

  @override
  bool get isRemote => false;

  @override
  void logConfiguration() {
    ApiDebugLog.dataSource(
      operation: 'MockFootballDataProvider',
      source: 'mock',
      message: 'mode=mock',
    );
  }

  Future<T> _notLive<T>() => throw const ApiException.notConfigured();

  @override
  Future<void> invalidateMatchCaches({
    DateTime? date,
    int? competitionId,
  }) async {}

  @override
  Future<List<MatchModel>> fetchLiveMatches({
    DateTime? date,
    int? competitionId,
    bool skipCache = false,
  }) =>
      _notLive();

  @override
  Future<List<MatchModel>> fetchUpcomingMatches({
    DateTime? date,
    int? competitionId,
    bool skipCache = false,
  }) =>
      _notLive();

  @override
  Future<List<MatchModel>> fetchFinishedMatches({
    DateTime? date,
    int? competitionId,
    bool skipCache = false,
  }) =>
      _notLive();

  @override
  Future<List<MatchModel>> fetchMatches({
    DateTime? date,
    int? competitionId,
    MatchStatus? status,
    bool skipCache = false,
  }) =>
      _notLive();

  @override
  Future<MatchModel?> fetchMatchById(int id, {bool skipCache = false}) =>
      _notLive();

  @override
  Future<List<MatchEventModel>> fetchMatchEvents(int matchId) => _notLive();

  @override
  Future<List<MatchStatisticModel>> fetchMatchStatistics(int matchId) =>
      _notLive();

  @override
  Future<({LineupModel? home, LineupModel? away})> fetchMatchLineups(
    int matchId,
  ) =>
      _notLive();

  @override
  Future<FormationModel?> fetchFormation(
    int matchId, {
    required bool isHome,
  }) =>
      _notLive();

  @override
  Future<List<CompetitionModel>> fetchCompetitions() => _notLive();

  @override
  Future<CompetitionModel?> fetchCompetitionById(int id) => _notLive();

  @override
  Future<List<TeamModel>> fetchTeams({int? competitionId}) => _notLive();

  @override
  Future<List<StandingModel>> fetchStandings({int? leagueId}) => _notLive();

  @override
  Future<List<PlayerModel>> fetchTopScorers(int competitionId) => _notLive();

  @override
  Future<PlayerModel?> fetchPlayerById(int id) => _notLive();

  /// Debug helper (not used when [isRemote] is false).
  List<MatchModel> debugMockMatches() => MockData.matches();
}
