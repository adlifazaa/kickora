import 'match_refresh_category.dart';

/// Polling intervals — tuned for battery vs freshness.
class MatchRefreshConfig {
  const MatchRefreshConfig({
    this.liveInterval = const Duration(seconds: 45),
    this.upcomingInterval = const Duration(minutes: 3),
    this.finishedInterval = const Duration(minutes: 12),
    this.allMatchesInterval = const Duration(minutes: 2),
    this.minGapBetweenSameCategory = const Duration(seconds: 25),
  });

  /// Live scores: 30–60s target (default 45s).
  final Duration liveInterval;

  /// Upcoming fixtures: less frequent.
  final Duration upcomingInterval;

  /// Finished results: rarely changes.
  final Duration finishedInterval;

  /// Home “today” aggregate lists.
  final Duration allMatchesInterval;

  /// Prevents duplicate back-to-back calls for the same category.
  final Duration minGapBetweenSameCategory;

  Duration intervalFor(MatchRefreshCategory category) {
    switch (category) {
      case MatchRefreshCategory.live:
        return liveInterval;
      case MatchRefreshCategory.upcoming:
        return upcomingInterval;
      case MatchRefreshCategory.finished:
        return finishedInterval;
      case MatchRefreshCategory.all:
        return allMatchesInterval;
    }
  }
}
