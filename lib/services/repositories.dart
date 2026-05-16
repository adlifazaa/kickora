export '../data/repositories/app_repositories.dart';
export '../data/repositories/football_repository.dart';

import '../data/repositories/football_repository.dart';
import '../models/competition_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/standing_model.dart';
import '../models/team_model.dart';

/// Legacy split repositories — delegate to [FootballRepository].
class MatchRepository {
  MatchRepository(this._football);

  final FootballRepository _football;

  Future<List<MatchModel>> getMatches({DateTime? date, int? competitionId}) async {
    final state = await _football.getMatches(date: date, competitionId: competitionId);
    return state.data ?? [];
  }

  Future<MatchModel?> getById(int id) async {
    final state = await _football.getMatchById(id);
    return state.data;
  }
}

class CompetitionRepository {
  CompetitionRepository(this._football);

  final FootballRepository _football;

  Future<List<CompetitionModel>> getAll() async {
    final state = await _football.getCompetitions();
    return state.data ?? [];
  }

  Future<CompetitionModel?> getById(int id) async {
    final state = await _football.getCompetitionById(id);
    return state.data;
  }

  Future<List<TeamModel>> getTeams(int competitionId) async {
    final state = await _football.getCompetitionTeams(competitionId);
    return state.data ?? [];
  }

  Future<List<PlayerModel>> getTopScorers(int competitionId) async {
    final state = await _football.getTopScorers(competitionId);
    return state.data ?? [];
  }

  Future<List<StandingModel>> getStandings({int? leagueId}) async {
    final state = await _football.getStandings(leagueId: leagueId);
    return state.data ?? [];
  }
}

class PlayerRepository {
  PlayerRepository(this._football);

  final FootballRepository _football;

  Future<PlayerModel?> getById(int id) async {
    final state = await _football.getPlayerById(id);
    return state.data;
  }
}
