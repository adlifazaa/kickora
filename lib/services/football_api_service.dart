import '../data/mock_data.dart';
import '../models/competition_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/standing_model.dart';
import '../models/team_model.dart';
import 'api_endpoints.dart';

/// Abstraction for the upcoming football data provider (API-Football, SofaScore
/// proxy, etc.). The mock implementation returns local data with a small delay
/// so the UI flows feel realistic; swap the bodies with HTTP calls when ready.
class FootballApiService {
  FootballApiService({this.provider = ApiProvider.mock, this.apiKey});

  final ApiProvider provider;
  final String? apiKey;

  Future<List<MatchModel>> fetchMatches({DateTime? date, int? competitionId}) async {
    await _delay(350);
    var data = MockData.matches();
    if (competitionId != null) {
      data = data.where((m) => m.competition.id == competitionId).toList();
    }
    return data;
  }

  Future<MatchModel?> fetchMatchById(int id) async {
    await _delay(220);
    try {
      return MockData.matches().firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<StandingModel>> fetchStandings({int? leagueId}) async {
    await _delay(300);
    return MockData.standings;
  }

  Future<List<CompetitionModel>> fetchCompetitions() async {
    await _delay(260);
    return MockData.competitions;
  }

  Future<CompetitionModel?> fetchCompetitionById(int id) async {
    await _delay(200);
    try {
      return MockData.competitions.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<TeamModel>> fetchCompetitionTeams(int competitionId) async {
    await _delay(220);
    return MockData.competitionTeams(competitionId);
  }

  Future<List<PlayerModel>> fetchTopScorers(int competitionId) async {
    await _delay(220);
    return MockData.topScorers(competitionId);
  }

  Future<PlayerModel?> fetchPlayerById(int id) async {
    await _delay(180);
    try {
      return MockData.players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _delay(int ms) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  /// Hook to flip the data source at runtime.
  Future<void> configureRealProvider({String? baseUrl, String? apiKey}) async {
    // TODO(api): wire Dio/http + headers per provider when going live.
  }
}
