import '../data/models/match_model.dart';
import 'api_datetime.dart';

/// Single source of truth for merging live fixture snapshots onto slower lists.
///
/// Live feed scores/status always win over stale competition or detail caches
/// unless [isDowngrade] detects a regression (e.g. 3-1 live → 0-0 upcoming).
class LiveMatchOverlay {
  LiveMatchOverlay._();

  /// Higher = more authoritative match state.
  static int freshnessRank(MatchStatus status) {
    switch (status) {
      case MatchStatus.finished:
        return 3;
      case MatchStatus.live:
        return 2;
      case MatchStatus.upcoming:
        return 1;
    }
  }

  static bool sameFixture(MatchModel a, MatchModel b) {
    return a.id == b.id ||
        a.resolvedFixtureId == b.resolvedFixtureId ||
        a.id == b.resolvedFixtureId ||
        a.resolvedFixtureId == b.id;
  }

  /// True when [candidate] is strictly older/weaker than [baseline].
  static bool isDowngrade(MatchModel candidate, MatchModel baseline) {
    if (!sameFixture(candidate, baseline)) return false;

    final baseRank = freshnessRank(baseline.status);
    final candRank = freshnessRank(candidate.status);
    if (candRank < baseRank) return true;

    if (baseline.status == MatchStatus.finished &&
        candidate.status != MatchStatus.finished) {
      return true;
    }

    if (baseline.status == MatchStatus.live && candidate.status == MatchStatus.live) {
      final baseGoals = baseline.homeScore + baseline.awayScore;
      final candGoals = candidate.homeScore + candidate.awayScore;
      if (candGoals < baseGoals) return true;
    }

    return false;
  }

  /// Keeps the fresher of [known] and [incoming]; never downgrades live scores.
  static MatchModel preferNewer(MatchModel known, MatchModel incoming) {
    if (isDowngrade(incoming, known)) return known;
    if (isDowngrade(known, incoming)) return incoming;

    if (freshnessRank(incoming.status) > freshnessRank(known.status)) {
      return merge(known, incoming);
    }
    if (freshnessRank(incoming.status) < freshnessRank(known.status)) {
      return merge(incoming, known);
    }

    // Same status rank — prefer higher goal count during live play.
    if (incoming.status == MatchStatus.live) {
      final knownGoals = known.homeScore + known.awayScore;
      final incomingGoals = incoming.homeScore + incoming.awayScore;
      if (incomingGoals >= knownGoals) return merge(known, incoming);
      return known;
    }

    return merge(known, incoming);
  }

  static MatchModel merge(MatchModel base, MatchModel live) {
    final kickoff = ApiDateTime.toLocalKickoff(live.date);
    return base.copyWith(
      fixtureId: live.fixtureId ?? base.fixtureId,
      homeScore: live.homeScore,
      awayScore: live.awayScore,
      status: live.status,
      timeLabel: live.timeLabel,
      homeTeam: live.homeTeam,
      awayTeam: live.awayTeam,
      date: kickoff,
    );
  }

  static List<MatchModel> overlay(
    List<MatchModel> base,
    List<MatchModel> live,
  ) {
    if (live.isEmpty) return base;
    final byId = <int, MatchModel>{};
    for (final m in live) {
      byId[m.id] = m;
      byId[m.resolvedFixtureId] = m;
    }
    return base
        .map((m) {
          final snap = byId[m.id] ?? byId[m.resolvedFixtureId];
          if (snap == null) return m;
          return preferNewer(m, snap);
        })
        .toList(growable: false);
  }

  /// Applies the live pool onto a single fixture (match details header).
  static MatchModel applyLiveTruth(MatchModel match, Iterable<MatchModel> live) {
    for (final snap in live) {
      if (sameFixture(match, snap)) {
        return preferNewer(match, snap);
      }
    }
    return match;
  }
}
