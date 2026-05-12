import '../models/competition_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/standing_model.dart';
import '../models/team_model.dart';
import 'football_api_service.dart';

/// Repositories sit between the API service and the UI. Caching, retries, and
/// future offline support belongs here. UI code should depend on these instead
/// of [FootballApiService] directly.
abstract class _BaseRepository {
  _BaseRepository(this.api);
  final FootballApiService api;
}

class MatchRepository extends _BaseRepository {
  MatchRepository(super.api);

  Future<List<MatchModel>> getMatches({DateTime? date, int? competitionId}) =>
      api.fetchMatches(date: date, competitionId: competitionId);

  Future<MatchModel?> getById(int id) => api.fetchMatchById(id);
}

class CompetitionRepository extends _BaseRepository {
  CompetitionRepository(super.api);

  Future<List<CompetitionModel>> getAll() => api.fetchCompetitions();
  Future<CompetitionModel?> getById(int id) => api.fetchCompetitionById(id);
  Future<List<TeamModel>> getTeams(int competitionId) =>
      api.fetchCompetitionTeams(competitionId);
  Future<List<PlayerModel>> getTopScorers(int competitionId) =>
      api.fetchTopScorers(competitionId);
  Future<List<StandingModel>> getStandings({int? leagueId}) =>
      api.fetchStandings(leagueId: leagueId);
}

class PlayerRepository extends _BaseRepository {
  PlayerRepository(super.api);

  Future<PlayerModel?> getById(int id) => api.fetchPlayerById(id);
}

/// Bundles all repositories into a single dependency-injection-friendly object.
class AppRepositories {
  AppRepositories({FootballApiService? api})
      : api = api ?? FootballApiService(),
        matches = MatchRepository(api ?? FootballApiService()),
        competitions = CompetitionRepository(api ?? FootballApiService()),
        players = PlayerRepository(api ?? FootballApiService());

  final FootballApiService api;
  final MatchRepository matches;
  final CompetitionRepository competitions;
  final PlayerRepository players;
}
