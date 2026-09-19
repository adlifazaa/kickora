import '../../data/models/competition_model.dart';
import '../../data/models/match_model.dart';
import '../../utils/api_datetime.dart';
import 'popular_competition_catalog.dart';

/// Ranks API competitions for Home "Top competitions" and the competitions list.
class CompetitionPriorityResolver {
  CompetitionPriorityResolver._();

  static const int topLimit = 5;
  static const Duration upcomingWindow = Duration(days: 7);

  static List<CompetitionModel> topCompetitions({
    required List<CompetitionModel> competitions,
    Iterable<MatchModel> liveMatches = const [],
    Iterable<MatchModel> todayMatches = const [],
    Iterable<MatchModel> upcomingMatches = const [],
    DateTime? now,
  }) {
    final ranked = _rankedCandidates(
      competitions: competitions,
      liveMatches: liveMatches,
      todayMatches: todayMatches,
      upcomingMatches: upcomingMatches,
      now: now ?? DateTime.now(),
      topModule: true,
    );
    if (ranked.length <= topLimit) return ranked;
    return ranked.take(topLimit).toList(growable: false);
  }

  static List<CompetitionModel> rankForCompetitionsScreen({
    required List<CompetitionModel> competitions,
    Iterable<MatchModel> liveMatches = const [],
    Iterable<MatchModel> todayMatches = const [],
    Iterable<MatchModel> upcomingMatches = const [],
    DateTime? now,
  }) {
    final popularFirst = _rankedCandidates(
      competitions: competitions,
      liveMatches: liveMatches,
      todayMatches: todayMatches,
      upcomingMatches: upcomingMatches,
      now: now ?? DateTime.now(),
      topModule: false,
    );
    final seen = popularFirst.map(PopularCompetitionCatalog.dedupeKey).toSet();
    final remaining = <CompetitionModel>[];
    for (final competition in competitions) {
      final key = PopularCompetitionCatalog.dedupeKey(competition);
      if (seen.contains(key)) continue;
      remaining.add(competition);
    }
    remaining.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return [...popularFirst, ...remaining];
  }

  static List<CompetitionModel> _rankedCandidates({
    required List<CompetitionModel> competitions,
    required Iterable<MatchModel> liveMatches,
    required Iterable<MatchModel> todayMatches,
    required Iterable<MatchModel> upcomingMatches,
    required DateTime now,
    required bool topModule,
  }) {
    if (competitions.isEmpty) return const [];

    final liveIds = _competitionIds(liveMatches, MatchStatus.live);
    final todayIds = {
      ..._competitionIds(todayMatches, null),
      ...competitions.where((c) => c.matchesToday > 0).map((c) => c.id),
    };
    final upcomingIds = _upcomingCompetitionIds(upcomingMatches, now);

    final unique = <String, CompetitionModel>{};
    for (final competition in competitions) {
      if (competition.id <= 0 && competition.name.trim().isEmpty) continue;
      unique.putIfAbsent(
        PopularCompetitionCatalog.dedupeKey(competition),
        () => competition,
      );
    }

    final scored = <_ScoredCompetition>[];
    for (final competition in unique.values) {
      final popular = PopularCompetitionCatalog.matchCompetition(competition);
      final hasLive = liveIds.contains(competition.id);
      final hasToday = todayIds.contains(competition.id) || hasLive;
      final hasUpcoming = upcomingIds.contains(competition.id);
      final relevant = hasLive || hasToday || hasUpcoming;

      if (topModule) {
        if (popular == null && !relevant) continue;
      } else if (popular == null) {
        continue;
      }

      scored.add(
        _ScoredCompetition(
          competition: competition,
          hasLive: hasLive,
          hasToday: hasToday,
          hasUpcoming: hasUpcoming,
          popularityRank: popular?.rank ?? 999,
        ),
      );
    }

    scored.sort((a, b) {
      final live = _boolRank(a.hasLive).compareTo(_boolRank(b.hasLive));
      if (live != 0) return live;
      final today = _boolRank(a.hasToday).compareTo(_boolRank(b.hasToday));
      if (today != 0) return today;
      final upcoming =
          _boolRank(a.hasUpcoming).compareTo(_boolRank(b.hasUpcoming));
      if (upcoming != 0) return upcoming;
      final popularity = a.popularityRank.compareTo(b.popularityRank);
      if (popularity != 0) return popularity;
      return a.competition.name.toLowerCase().compareTo(
            b.competition.name.toLowerCase(),
          );
    });

    return scored.map((item) => item.competition).toList(growable: false);
  }

  static Set<int> _competitionIds(
    Iterable<MatchModel> matches,
    MatchStatus? status,
  ) {
    final ids = <int>{};
    for (final match in matches) {
      if (status != null && match.status != status) continue;
      final id = match.competition.id;
      if (id > 0) ids.add(id);
    }
    return ids;
  }

  static Set<int> _upcomingCompetitionIds(
    Iterable<MatchModel> matches,
    DateTime now,
  ) {
    final end = now.add(upcomingWindow);
    final ids = <int>{};
    for (final match in matches) {
      if (match.status != MatchStatus.upcoming) continue;
      final kickoff = ApiDateTime.toLocalKickoff(match.date);
      if (kickoff.isBefore(now) || kickoff.isAfter(end)) continue;
      final id = match.competition.id;
      if (id > 0) ids.add(id);
    }
    return ids;
  }

  static int _boolRank(bool value) => value ? 0 : 1;
}

class _ScoredCompetition {
  const _ScoredCompetition({
    required this.competition,
    required this.hasLive,
    required this.hasToday,
    required this.hasUpcoming,
    required this.popularityRank,
  });

  final CompetitionModel competition;
  final bool hasLive;
  final bool hasToday;
  final bool hasUpcoming;
  final int popularityRank;
}
