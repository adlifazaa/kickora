import '../../data/models/match_model.dart';
import '../../utils/api_datetime.dart';
import '../competition/popular_competition_catalog.dart';

/// Home featured-match priority using real API fixtures only.
class FeaturedMatchSelector {
  FeaturedMatchSelector._();

  static const Duration upcomingWindow = Duration(hours: 48);

  static MatchModel? pick({
    Iterable<MatchModel> liveMatches = const [],
    Iterable<MatchModel> upcomingMatches = const [],
    Iterable<MatchModel> finishedMatches = const [],
    DateTime? now,
  }) {
    final moment = now ?? DateTime.now();
    final live = _usable(liveMatches, MatchStatus.live);
    final majorLive = live.where(_isMajor).toList(growable: false);
    if (majorLive.isNotEmpty) return _earliest(majorLive);
    if (live.isNotEmpty) return _earliest(live);

    final upcoming = _usable(upcomingMatches, MatchStatus.upcoming)
        .where((match) => _isWithinUpcomingWindow(match, moment))
        .toList(growable: false);
    final majorUpcoming = upcoming.where(_isMajor).toList(growable: false);
    if (majorUpcoming.isNotEmpty) return _earliest(majorUpcoming);
    if (upcoming.isNotEmpty) return _earliest(upcoming);

    final finished = _usable(finishedMatches, MatchStatus.finished);
    final majorFinished = finished.where(_isMajor).toList(growable: false);
    if (majorFinished.isNotEmpty) return _latest(majorFinished);
    if (finished.isNotEmpty) return _latest(finished);
    return null;
  }

  static List<MatchModel> _usable(
    Iterable<MatchModel> matches,
    MatchStatus status,
  ) {
    final out = <MatchModel>[];
    for (final match in matches) {
      if (match.status != status) continue;
      if (!_isSafe(match)) continue;
      out.add(match);
    }
    return out;
  }

  static bool _isSafe(MatchModel match) {
    if (match.homeTeam.name.trim().isEmpty &&
        match.awayTeam.name.trim().isEmpty) {
      return false;
    }
    return true;
  }

  static bool _isMajor(MatchModel match) {
    return PopularCompetitionCatalog.isPopular(
      name: match.competition.name,
      id: match.competition.id,
    );
  }

  static bool _isWithinUpcomingWindow(MatchModel match, DateTime now) {
    final kickoff = ApiDateTime.toLocalKickoff(match.date);
    if (kickoff.isBefore(now)) return false;
    return !kickoff.isAfter(now.add(upcomingWindow));
  }

  static MatchModel _earliest(List<MatchModel> matches) {
    final copy = [...matches]
      ..sort((a, b) => a.date.compareTo(b.date));
    return copy.first;
  }

  static MatchModel _latest(List<MatchModel> matches) {
    final copy = [...matches]
      ..sort((a, b) => b.date.compareTo(a.date));
    return copy.first;
  }
}
