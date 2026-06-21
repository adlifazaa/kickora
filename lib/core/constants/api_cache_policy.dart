import '../../data/models/match_model.dart';

/// TTL durations for football API caching (production cost control).
class ApiCachePolicy {
  ApiCachePolicy._();

  /// Live fixtures — refresh at most every 30–60s.
  static const Duration liveMatches = Duration(seconds: 45);

  static const Duration todayMatches = Duration(minutes: 3);

  static const Duration fixturesUpcoming = Duration(minutes: 10);

  /// Finished fixtures — stable longer than live.
  static const Duration fixturesFinished = Duration(hours: 12);

  /// Full competition fixture list (World Cup hub).
  static const Duration competitionFixtures = Duration(minutes: 15);

  /// League tables — refresh every 10–30 minutes.
  static const Duration standings = Duration(minutes: 15);

  static const Duration competitions = Duration(hours: 24);

  static const Duration teams = Duration(hours: 24);

  static const Duration topScorers = Duration(minutes: 20);

  static const Duration worldCupNews = Duration(minutes: 30);

  static const Duration standingGroups = Duration(minutes: 15);

  static const Duration playerProfile = Duration(hours: 24);

  /// Match header / fixture row (opened match only).
  static const Duration matchDetails = Duration(seconds: 45);

  /// Events, statistics, lineups — live default; use [matchDetailResourceTtl].
  static const Duration matchEvents = Duration(seconds: 45);
  static const Duration matchStatistics = Duration(seconds: 45);
  static const Duration matchLineups = Duration(seconds: 45);

  /// Status-aware TTL for match detail sub-resources (events, stats, lineups).
  static Duration matchDetailResourceTtl(MatchStatus status) {
    switch (status) {
      case MatchStatus.finished:
        return const Duration(hours: 24);
      case MatchStatus.upcoming:
        return const Duration(hours: 1);
      case MatchStatus.live:
        return const Duration(seconds: 45);
    }
  }

  /// @deprecated Use [todayMatches].
  static const Duration fixturesByDate = todayMatches;
}
