import '../../core/cache/cache_manager.dart';
import '../../core/constants/api_mode.dart';
import '../services/football_api_service.dart';
import '../models/competition_model.dart';
import '../models/formation_model.dart';
import '../models/lineup_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/standing_model.dart';
import '../models/team_model.dart';
import 'football_data_provider.dart';

/// Remote football data via [FootballApiService] (direct API or backend proxy).
class RemoteFootballDataProvider implements FootballDataProvider {
  RemoteFootballDataProvider(
    this._service, {
    required this.mode,
  });

  factory RemoteFootballDataProvider.create({
    CacheManager? cache,
    required ApiMode mode,
  }) {
    return RemoteFootballDataProvider(
      FootballApiService(cache: cache),
      mode: mode,
    );
  }

  final FootballApiService _service;
  @override
  final ApiMode mode;

  @override
  bool get isMock => false;

  @override
  bool get isRemote => _service.isLive;

  FootballApiService get service => _service;

  @override
  void logConfiguration() => _service.logApiMode();

  @override
  Future<void> invalidateMatchCaches({
    DateTime? date,
    int? competitionId,
  }) =>
      _service.invalidateMatchCaches(
        date: date,
        competitionId: competitionId,
      );

  @override
  Future<List<MatchModel>> fetchLiveMatches({
    DateTime? date,
    int? competitionId,
    bool skipCache = false,
  }) =>
      _service.fetchLiveMatches(
        date: date,
        competitionId: competitionId,
        skipCache: skipCache,
      );

  @override
  Future<List<MatchModel>> fetchUpcomingMatches({
    DateTime? date,
    int? competitionId,
    bool skipCache = false,
  }) =>
      _service.fetchUpcomingMatches(
        date: date,
        competitionId: competitionId,
        skipCache: skipCache,
      );

  @override
  Future<List<MatchModel>> fetchFinishedMatches({
    DateTime? date,
    int? competitionId,
    bool skipCache = false,
  }) =>
      _service.fetchFinishedMatches(
        date: date,
        competitionId: competitionId,
        skipCache: skipCache,
      );

  @override
  Future<List<MatchModel>> fetchMatches({
    DateTime? date,
    int? competitionId,
    MatchStatus? status,
    bool skipCache = false,
  }) =>
      _service.fetchMatches(
        date: date,
        competitionId: competitionId,
        status: status,
        skipCache: skipCache,
      );

  @override
  Future<MatchModel?> fetchMatchById(int id, {bool skipCache = false}) =>
      _service.fetchMatchById(id, skipCache: skipCache);

  @override
  Future<List<MatchEventModel>> fetchMatchEvents(int matchId) =>
      _service.fetchMatchEvents(matchId);

  @override
  Future<List<MatchStatisticModel>> fetchMatchStatistics(int matchId) =>
      _service.fetchMatchStatistics(matchId);

  @override
  Future<({LineupModel? home, LineupModel? away})> fetchMatchLineups(
    int matchId,
  ) =>
      _service.fetchMatchLineups(matchId);

  @override
  Future<FormationModel?> fetchFormation(
    int matchId, {
    required bool isHome,
  }) =>
      _service.fetchFormation(matchId, isHome: isHome);

  @override
  Future<List<CompetitionModel>> fetchCompetitions() =>
      _service.fetchCompetitions();

  @override
  Future<CompetitionModel?> fetchCompetitionById(int id) =>
      _service.fetchCompetitionById(id);

  @override
  Future<List<TeamModel>> fetchTeams({int? competitionId}) =>
      _service.fetchTeams(competitionId: competitionId);

  @override
  Future<List<StandingModel>> fetchStandings({int? leagueId}) =>
      _service.fetchStandings(leagueId: leagueId);

  @override
  Future<List<PlayerModel>> fetchTopScorers(int competitionId) =>
      _service.fetchTopScorers(competitionId);

  @override
  Future<PlayerModel?> fetchPlayerById(int id) =>
      _service.fetchPlayerById(id);
}
