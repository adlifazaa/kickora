import '../core/constants/api_constants.dart';

export '../core/constants/api_constants.dart';
export '../core/constants/api_mode.dart';
export '../core/constants/api_mode_service.dart';

/// @deprecated Use [ApiConstants] from `core/constants/api_constants.dart`.
class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl => ApiConstants.effectiveBaseUrl;
  static const String matches = ApiConstants.matches;
  static const String matchById = ApiConstants.matchById;
  static const String standings = ApiConstants.standings;
  static const String competitions = ApiConstants.competitions;
  static const String competitionById = ApiConstants.competitionById;
  static const String competitionTeams = ApiConstants.teams;
  static const String topScorers = '/competitions/{id}/top-scorers';
  static const String teamById = '/teams/{id}';
  static const String playerById = '/players/{id}';

  static const String backendMatchesLive = ApiConstants.backendMatchesLive;
  static const String backendCompetitions = ApiConstants.backendCompetitions;
  static const String backendPlayersSearch = ApiConstants.backendPlayersSearch;

  static String backendMatch(int id) => ApiConstants.backendMatch(id);
  static String backendCompetition(int id) => ApiConstants.backendCompetition(id);
  static String backendStandings(int id) => ApiConstants.backendStandings(id);
  static String backendTeams(int id) => ApiConstants.backendTeams(id);

  static String fill(String template, Map<String, Object> args) =>
      ApiConstants.fill(template, args);
}
