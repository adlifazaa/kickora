/// API configuration for live football data providers.
///
/// TODO(api): Set [apiKey] from secure storage, `--dart-define`, or env at startup.
/// TODO(api): Point [baseUrl] to your provider (e.g. API-Football v3).
class ApiConstants {
  ApiConstants._();

  /// Example: `https://v3.football.api-sports.io`
  static const String baseUrl = 'https://api.placeholder.kickora.live/v1';

  /// TODO(api): Replace with your real API key before enabling live requests.
  static const String apiKey = String.fromEnvironment(
    'KICKORA_API_KEY',
    defaultValue: '',
  );

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static const String headerApiKey = 'x-apisports-key';
  static const String headerAuthBearer = 'Authorization';

  // Paths (provider-agnostic placeholders — map in FootballApiService).
  static const String matches = '/fixtures';
  static const String matchById = '/fixtures/{id}';
  static const String matchEvents = '/fixtures/events';
  static const String matchStatistics = '/fixtures/statistics';
  static const String matchLineups = '/fixtures/lineups';
  static const String standings = '/standings';
  static const String competitions = '/leagues';
  static const String competitionById = '/leagues/{id}';
  static const String teams = '/teams';

  static bool get hasApiKey => apiKey.trim().isNotEmpty;

  static String fill(String template, Map<String, Object> args) {
    var out = template;
    args.forEach((k, v) => out = out.replaceAll('{$k}', '$v'));
    return out;
  }
}

/// Supported providers when wiring real HTTP.
enum ApiProvider {
  mock,
  apiFootball,
  footballData,
  sofa,
}
