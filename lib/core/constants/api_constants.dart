import 'api_mode.dart';

/// Football API configuration (direct API-Football or Kickora backend proxy).
///
/// **Development / testing (direct API):**
/// `flutter run --dart-define=KICKORA_API_MODE=direct --dart-define=KICKORA_API_KEY=your_key`
///
/// **Production (backend proxy — recommended for Play Store):**
/// `flutter build appbundle --dart-define=KICKORA_API_MODE=backend --dart-define=KICKORA_BACKEND_BASE_URL=https://your-api.example.com`
///
/// TODO(production): Ship Play Store builds with [ApiMode.backendProxy] only.
/// Never embed `KICKORA_API_KEY` in Flutter release binaries — the key belongs on the server.
///
/// Optional: `--dart-define=KICKORA_API_DEBUG=true` | `KICKORA_API_DEV_MODE=true`
class ApiConstants {
  ApiConstants._();

  // --- Mode ---

  /// `direct` (default) or `backend` / `backendProxy`.
  static const String apiModeName = String.fromEnvironment(
    'KICKORA_API_MODE',
    defaultValue: 'direct',
  );

  static ApiMode get apiMode {
    switch (apiModeName.trim().toLowerCase()) {
      case 'backend':
      case 'backendproxy':
      case 'backend_proxy':
        return ApiMode.backendProxy;
      case 'direct':
      case 'directapi':
      case 'direct_api':
      default:
        return ApiMode.directApi;
    }
  }

  static bool get isDirectApi => apiMode == ApiMode.directApi;

  static bool get isBackendProxy => apiMode == ApiMode.backendProxy;

  // --- Base URLs ---

  /// API-Football v3 host (direct mode only).
  static const String apiFootballBaseUrl = 'https://v3.football.api-sports.io';

  /// Kickora backend proxy base URL (backend mode).
  /// Example: `https://api.kickora.app`
  static const String backendBaseUrl = String.fromEnvironment(
    'KICKORA_BACKEND_BASE_URL',
    defaultValue: '',
  );

  static String get effectiveBaseUrl =>
      isBackendProxy ? backendBaseUrl : apiFootballBaseUrl;

  /// @deprecated Use [apiFootballBaseUrl] or [effectiveBaseUrl].
  static String get baseUrl => effectiveBaseUrl;

  // --- Credentials (direct mode only) ---

  /// Injected at compile time for [ApiMode.directApi]; must be empty in production releases.
  static const String apiKey = String.fromEnvironment(
    'KICKORA_API_KEY',
    defaultValue: '',
  );

  static const bool enableDebugLogs = bool.fromEnvironment(
    'KICKORA_API_DEBUG',
    defaultValue: false,
  );

  static const bool apiDevMode = bool.fromEnvironment(
    'KICKORA_API_DEV_MODE',
    defaultValue: false,
  );

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static Duration get requestThrottleInterval => apiDevMode
      ? const Duration(milliseconds: 1500)
      : const Duration(milliseconds: 650);

  static const int maxRetries = 3;
  static const Duration retryBaseDelay = Duration(milliseconds: 400);

  /// API-Football header — sent only in [ApiMode.directApi]. Never use in backend mode.
  static const String headerApiKey = 'x-apisports-key';

  // --- Kickora backend proxy routes (production) ---
  // Server holds the API-Football key and normalizes responses for the app.

  static const String backendMatchesLive = '/matches/live';
  static const String backendMatchesToday = '/matches/today';
  static const String backendMatchesUpcoming = '/matches/upcoming';
  static const String backendMatchesFinished = '/matches/finished';
  static const String backendCompetitions = '/competitions';
  static const String backendStandings = '/standings';

  static String backendMatch(int id) => '/match/$id';
  static String backendMatchEvents(int id) => '/match/$id/events';
  static String backendMatchStatistics(int id) => '/match/$id/statistics';
  static String backendMatchLineups(int id) => '/match/$id/lineups';

  // TODO(backend): add when proxy implements competition teams / top scorers / players.
  // static const String backendCompetitionTeams = '/competitions/{id}/teams';

  // --- API-Football v3 routes (direct mode) ---

  static const String fixtures = '/fixtures';
  static const String fixtureEvents = '/fixtures/events';
  static const String fixtureStatistics = '/fixtures/statistics';
  static const String fixtureLineups = '/fixtures/lineups';
  static const String leagues = '/leagues';
  static const String standings = '/standings';
  static const String teams = '/teams';
  static const String playersTopScorers = '/players/topscorers';
  static const String players = '/players';

  static const String matches = fixtures;
  static const String matchById = fixtures;
  static const String matchEvents = fixtureEvents;
  static const String matchStatistics = fixtureStatistics;
  static const String matchLineups = fixtureLineups;
  static const String competitions = leagues;
  static const String competitionById = leagues;

  static bool get hasApiKey => apiKey.trim().isNotEmpty;

  static bool get hasBackendUrl => backendBaseUrl.trim().isNotEmpty;

  /// True when remote football data can be loaded (direct key or backend URL).
  static bool get hasRemoteApi =>
      isDirectApi ? hasApiKey : hasBackendUrl;

  static int currentSeason([DateTime? reference]) {
    final now = reference ?? DateTime.now();
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
  backend,
  footballData,
  sofa,
}
