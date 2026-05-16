import '../core/constants/api_constants.dart';

export '../core/constants/api_constants.dart';

/// @deprecated Use [ApiConstants] from `core/constants/api_constants.dart`.
class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = ApiConstants.baseUrl;
  static const String matches = ApiConstants.matches;
  static const String matchById = ApiConstants.matchById;
  static const String standings = ApiConstants.standings;
  static const String competitions = ApiConstants.competitions;
  static const String competitionById = ApiConstants.competitionById;
  static const String competitionTeams = ApiConstants.teams;
  static const String topScorers = '/competitions/{id}/top-scorers';
  static const String teamById = '/teams/{id}';
  static const String playerById = '/players/{id}';

  static String fill(String template, Map<String, Object> args) =>
      ApiConstants.fill(template, args);
}
