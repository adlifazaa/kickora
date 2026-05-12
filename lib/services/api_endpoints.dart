/// Centralised constants for the future football API integration.
/// Update [baseUrl] and add headers/API key once you switch to a real provider
/// such as API-Football, SofaScore unofficial, or Football-Data.org.
class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://api.placeholder.kickora.live/v1';

  static const String matches = '/matches';
  static const String matchById = '/matches/{id}';
  static const String standings = '/standings';
  static const String competitions = '/competitions';
  static const String competitionById = '/competitions/{id}';
  static const String competitionTeams = '/competitions/{id}/teams';
  static const String topScorers = '/competitions/{id}/top-scorers';
  static const String teamById = '/teams/{id}';
  static const String playerById = '/players/{id}';

  static String fill(String template, Map<String, Object> args) {
    var out = template;
    args.forEach((k, v) => out = out.replaceAll('{$k}', '$v'));
    return out;
  }
}

/// Public list of supported providers. Keep this in sync with the swap logic
/// inside [FootballApiService.configureRealProvider].
enum ApiProvider {
  mock,
  apiFootball,
  footballData,
  sofa,
}
