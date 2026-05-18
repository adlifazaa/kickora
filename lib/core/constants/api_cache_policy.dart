/// TTL durations for football API caching (production cost control).
class ApiCachePolicy {
  ApiCachePolicy._();

  /// Live fixtures — refresh at most every 30–60s.
  static const Duration liveMatches = Duration(seconds: 45);

  static const Duration todayMatches = Duration(minutes: 5);

  static const Duration fixturesUpcoming = Duration(minutes: 5);

  /// Finished fixtures — stable longer than live.
  static const Duration fixturesFinished = Duration(minutes: 10);

  /// League tables — refresh every 10–30 minutes.
  static const Duration standings = Duration(minutes: 20);

  static const Duration competitions = Duration(hours: 24);

  static const Duration teams = Duration(hours: 24);

  static const Duration playerProfile = Duration(hours: 24);

  /// Match header / fixture row (opened match only).
  static const Duration matchDetails = Duration(minutes: 2);

  /// Events, statistics, lineups — match details screen only.
  static const Duration matchEvents = Duration(minutes: 2);
  static const Duration matchStatistics = Duration(minutes: 2);
  static const Duration matchLineups = Duration(minutes: 2);

  /// @deprecated Use [todayMatches].
  static const Duration fixturesByDate = todayMatches;
}
