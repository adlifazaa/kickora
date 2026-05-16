/// API-Football (api-sports.io v3) configuration.
///
/// Run with your key (never commit the key to source control):
/// `flutter run --dart-define=KICKORA_API_KEY=your_api_sports_key`
///
/// Optional request logs (debug builds only, never prints the key):
/// `flutter run --dart-define=KICKORA_API_KEY=... --dart-define=KICKORA_API_DEBUG=true`
class ApiConstants {
  ApiConstants._();

  /// Official API-Football v3 host — all routes are relative to this base.
  static const String baseUrl = 'https://v3.football.api-sports.io';

  /// Injected at compile time; empty → repository uses mock data.
  static const String apiKey = String.fromEnvironment(
    'KICKORA_API_KEY',
    defaultValue: '',
  );

  /// When true (and [kDebugMode]), [ApiDebugLog] prints request status only.
  static const bool enableDebugLogs = bool.fromEnvironment(
    'KICKORA_API_DEBUG',
    defaultValue: false,
  );

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Minimum gap between outbound requests (free tier ≈ 10 req/min).
  static const Duration requestThrottleInterval = Duration(milliseconds: 650);

  static const int maxRetries = 3;
  static const Duration retryBaseDelay = Duration(milliseconds: 400);

  /// Required by API-Football — see https://www.api-football.com/documentation-v3
  static const String headerApiKey = 'x-apisports-key';

  // --- API-Football v3 routes (used by [FootballApiService]) ---
  // GET /fixtures?live=all | ?date= | ?league=&season= | ?id=
  static const String fixtures = '/fixtures';
  // GET /fixtures/events?fixture=
  static const String fixtureEvents = '/fixtures/events';
  // GET /fixtures/statistics?fixture=
  static const String fixtureStatistics = '/fixtures/statistics';
  // GET /fixtures/lineups?fixture=
  static const String fixtureLineups = '/fixtures/lineups';
  // GET /leagues?current=true | ?id=&season=
  static const String leagues = '/leagues';
  // GET /standings?league=&season=
  static const String standings = '/standings';
  // GET /teams?league=&season=
  static const String teams = '/teams';
  // GET /players/topscorers?league=&season=
  static const String playersTopScorers = '/players/topscorers';
  // GET /players?id=&season=
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
