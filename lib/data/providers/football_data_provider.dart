import '../../core/constants/api_mode.dart';
import '../models/competition_model.dart';
import '../models/formation_model.dart';
import '../models/lineup_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/standing_model.dart';
import '../models/team_model.dart';

/// Football data access for repositories (mock, direct API, or backend proxy).
abstract class FootballDataProvider {
  ApiMode get mode;

  bool get isMock;

  bool get isRemote;

  void logConfiguration();

  Future<void> invalidateMatchCaches({
    DateTime? date,
    int? competitionId,
  });

  Future<List<MatchModel>> fetchLiveMatches({
    DateTime? date,
    int? competitionId,
    bool skipCache = false,
  });

  Future<List<MatchModel>> fetchUpcomingMatches({
    DateTime? date,
    int? competitionId,
    bool skipCache = false,
  });

  Future<List<MatchModel>> fetchFinishedMatches({
    DateTime? date,
    int? competitionId,
    bool skipCache = false,
  });

  Future<List<MatchModel>> fetchMatches({
    DateTime? date,
    int? competitionId,
    MatchStatus? status,
    bool skipCache = false,
  });

  Future<MatchModel?> fetchMatchById(int id, {bool skipCache = false});

  Future<List<MatchEventModel>> fetchMatchEvents(int matchId);

  Future<List<MatchStatisticModel>> fetchMatchStatistics(int matchId);

  Future<({LineupModel? home, LineupModel? away})> fetchMatchLineups(
    int matchId,
  );

  Future<FormationModel?> fetchFormation(
    int matchId, {
    required bool isHome,
  });

  Future<List<CompetitionModel>> fetchCompetitions();

  Future<CompetitionModel?> fetchCompetitionById(int id);

  Future<List<TeamModel>> fetchTeams({int? competitionId});

  Future<List<StandingModel>> fetchStandings({int? leagueId});

  Future<List<PlayerModel>> fetchTopScorers(int competitionId);

  Future<PlayerModel?> fetchPlayerById(int id);
}
