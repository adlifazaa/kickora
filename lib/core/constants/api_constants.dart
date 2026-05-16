/// API-Football (api-sports.io v3) configuration.
///
/// Provide your key at build/run time:
/// `flutter run --dart-define=KICKORA_API_KEY=your_api_sports_key`
class ApiConstants {
  ApiConstants._();

  /// API-Football v3 base URL.
  static const String baseUrl = 'https://v3.football.api-sports.io';

  static const String apiKey = String.fromEnvironment(
    'KICKORA_API_KEY',
    defaultValue: '',
  );

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Minimum gap between outbound requests (free tier ≈ 10 req/min).
  static const Duration requestThrottleInterval = Duration(milliseconds: 650);

  static const int maxRetries = 3;
  static const Duration retryBaseDelay = Duration(milliseconds: 400);

  static const String headerApiKey = 'x-apisports-key';

  // --- API-Football paths ---
  static const String fixtures = '/fixtures';
  static const String fixtureEvents = '/fixtures/events';
  static const String fixtureStatistics = '/fixtures/statistics';
  static const String fixtureLineups = '/fixtures/lineups';
  static const String leagues = '/leagues';
  static const String standings = '/standings';
  static const String teams = '/teams';
  static const String playersTopScorers = '/players/topscorers';
  static const String players = '/players';

  // Backward-compatible aliases used by legacy imports.
  static const String matches = fixtures;
  static const String matchById = fixtures;
  static const String matchEvents = fixtureEvents;
  static const String matchStatistics = fixtureStatistics;
  static const String matchLineups = fixtureLineups;
  static const String competitions = leagues;
  static const String competitionById = leagues;

  static bool get hasApiKey => apiKey.trim().isNotEmpty;

  /// Current football season year for API-Football `season` query param.
  static int currentSeason([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    // European seasons span two calendar years; Aug+ uses current year.
    return now.month >= 8 ? now.year : now.year - 1;
  }

  static String formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String fill(String template, Map<String, Object> args) {
    var out = template;
    args.forEach((k, v) => out = out.replaceAll('{$k}', '$v'));
    return out;
  }
}

/// Supported football data providers.
enum ApiProvider {
  mock,
  apiFootball,
  footballData,
  sofa,
}
