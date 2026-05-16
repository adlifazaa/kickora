import '../refresh/match_refresh_config.dart';

/// Low-request profile for local development (`--dart-define=KICKORA_API_DEV_MODE=true`).
class ApiDevMode {
  ApiDevMode._();

  static const bool enabled = bool.fromEnvironment(
    'KICKORA_API_DEV_MODE',
    defaultValue: false,
  );

  static MatchRefreshConfig refreshConfig() {
    if (!enabled) return const MatchRefreshConfig();
    return const MatchRefreshConfig(
      enableBackgroundTimers: false,
      liveInterval: Duration(minutes: 5),
      upcomingInterval: Duration(minutes: 10),
      finishedInterval: Duration(minutes: 15),
      allMatchesInterval: Duration(minutes: 5),
      minGapBetweenSameCategory: Duration(minutes: 2),
    );
  }
}
