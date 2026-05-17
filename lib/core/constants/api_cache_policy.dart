/// TTL durations for football API caching.
class ApiCachePolicy {
  ApiCachePolicy._();

  static const Duration liveMatches = Duration(seconds: 60);
  static const Duration todayMatches = Duration(minutes: 5);
  static const Duration standings = Duration(minutes: 10);
  static const Duration competitions = Duration(hours: 24);
  static const Duration teams = Duration(hours: 24);
  static const Duration matchDetails = Duration(minutes: 2);
  static const Duration playerProfile = Duration(hours: 24);

  /// @deprecated Use [todayMatches].
  static const Duration fixturesByDate = todayMatches;

  static const Duration fixturesUpcoming = Duration(minutes: 5);
  static const Duration fixturesFinished = Duration(minutes: 15);
}
