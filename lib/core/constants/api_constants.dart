import 'api_mode.dart';

/// Football API configuration: mock, direct API-Football, or Kickora backend proxy.
///
/// **Production (default — Play Store / release builds):**
/// `flutter build appbundle --release`
/// Uses backend proxy → [productionBackendUrl] (no dart-define required).
///
/// **Mock (development / UI testing only):**
/// `flutter run --dart-define=KICKORA_API_MODE=mock`
///
/// **Development (direct API — never ship to Play Store):**
/// `flutter run --dart-define=KICKORA_API_MODE=direct --dart-define=KICKORA_API_KEY=your_key`
///
/// Never embed `KICKORA_API_KEY` in Play Store release binaries.
class ApiConstants {
  ApiConstants._();

  /// Kickora Render backend — production default when no dart-define override is set.
  static const String productionBackendUrl =
      'https://kickora-aoi0.onrender.com';

  // --- Mode ---

  static const String _apiModeOverride = String.fromEnvironment(
    'KICKORA_API_MODE',
    defaultValue: '',
  );

  /// Resolved mode name: explicit dart-define, else `backend` (production default).
  static String get apiModeName {
    final override = _apiModeOverride.trim();
    if (override.isNotEmpty) return override;
    return 'backend';
  }

  /// True only when mock was explicitly requested via dart-define.
  static bool get isExplicitMock =>
      _apiModeOverride.trim().toLowerCase() == 'mock';

  static ApiMode get apiMode {
    switch (apiModeName.trim().toLowerCase()) {
      case 'mock':
        return ApiMode.mock;
      case 'backend':
      case 'backendproxy':
      case 'backend_proxy':
        return ApiMode.backendProxy;
      case 'direct':
      case 'directapi':
      case 'direct_api':
        return ApiMode.directApi;
      default:
        return ApiMode.backendProxy;
    }
  }

  static bool get isMock => apiMode == ApiMode.mock;

  static bool get isDirectApi => apiMode == ApiMode.directApi;

  static bool get isBackendProxy => apiMode == ApiMode.backendProxy;

  // --- Base URLs ---

  /// API-Football v3 host (direct mode only).
  static const String apiFootballBaseUrl = 'https://v3.football.api-sports.io';

  static const String _backendUrlOverride = String.fromEnvironment(
    'KICKORA_BACKEND_URL',
    defaultValue: '',
  );

  static const String _backendUrlLegacy = String.fromEnvironment(
    'KICKORA_BACKEND_BASE_URL',
    defaultValue: '',
  );

  /// Kickora backend proxy base URL (backend mode).
  static String get backendBaseUrl {
    final override = _backendUrlOverride.trim();
    if (override.isNotEmpty) return override;
    final legacy = _backendUrlLegacy.trim();
    if (legacy.isNotEmpty) return legacy;
    return productionBackendUrl;
  }

  static String get effectiveBaseUrl =>
      isBackendProxy ? backendBaseUrl : apiFootballBaseUrl;

  /// @deprecated Use [apiFootballBaseUrl] or [effectiveBaseUrl].
  static String get baseUrl => effectiveBaseUrl;

  // --- Credentials (direct mode only) ---

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

  static const String backendWorldCupNews = '/news/world-cup';

  static const String backendMatchesLive = '/matches/live';
  static const String backendMatchesToday = '/matches/today';
  static const String backendMatchesUpcoming = '/matches/upcoming';
  static const String backendMatchesFinished = '/matches/finished';
  static const String backendCompetitions = '/competitions';
  static const String backendPlayersSearch = '/players/search';

  static String backendCompetition(int id) => '/competitions/$id';
  static String backendTopScorers(int competitionId) =>
      '/competitions/$competitionId/top-scorers';
  static String backendCompetitionMatches(int competitionId) =>
      '/competitions/$competitionId/matches';
  static String backendPlayer(int id) => '/players/$id';
  static String backendStandings(int competitionId) =>
      '/standings/$competitionId';
  static String backendTeams(int competitionId) => '/teams/$competitionId';
  static String backendMatch(int id) => '/matches/$id';
  static String backendMatchEvents(int id) => '/matches/$id/events';
  static String backendMatchStatistics(int id) => '/matches/$id/statistics';
  static String backendMatchLineups(int id) => '/matches/$id/lineups';

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

  /// True when remote football data can be loaded (not mock, with credentials).
  static bool get hasRemoteApi => hasBackendUrl || (isDirectApi && hasApiKey);

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

