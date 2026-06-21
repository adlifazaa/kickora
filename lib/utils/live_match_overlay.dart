import '../data/models/match_model.dart';

/// Applies fresher live snapshots onto slower cached fixture lists.
class LiveMatchOverlay {
  LiveMatchOverlay._();

  static MatchModel merge(MatchModel base, MatchModel live) {
    return base.copyWith(
      fixtureId: live.fixtureId ?? base.fixtureId,
      homeScore: live.homeScore,
      awayScore: live.awayScore,
      status: live.status,
      timeLabel: live.timeLabel,
      homeTeam: live.homeTeam,
      awayTeam: live.awayTeam,
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
          return merge(m, snap);
        })
        .toList(growable: false);
  }
}
