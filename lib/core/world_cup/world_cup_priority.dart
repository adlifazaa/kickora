import '../../data/models/competition_model.dart';
import '../../data/models/match_model.dart';
import '../constants/world_cup_config.dart';

/// Sorting and fallback helpers for FIFA World Cup 2026 prominence.
class WorldCupPriority {
  WorldCupPriority._();

  static bool isWorldCupCompetition(CompetitionModel c) =>
      c.id == WorldCupConfig.competitionId ||
      _isMainWorldCupName(c.name);

  static bool isWorldCupCompetitionName(String name) =>
      _isMainWorldCupName(name);

  /// True for league id 1 / exact World Cup name (not Club / youth / qualifiers).
  static bool isWorldCupBadge({int? competitionId, String? competitionName}) {
    if (competitionId == WorldCupConfig.competitionId) return true;
    if (competitionName != null &&
        _isMainWorldCupName(competitionName)) {
      return true;
    }
    return false;
  }

  static bool isWorldCupMatch(MatchModel m) =>
      m.competition.id == WorldCupConfig.competitionId ||
      _isMainWorldCupName(m.competition.name);

  static bool _isMainWorldCupName(String name) {
    final n = name.trim().toLowerCase();
    // API-Football league id 1 is exactly "World Cup" (not Club / youth / qualifiers).
    return n == 'world cup' || n == 'fifa world cup';
  }

  static List<CompetitionModel> sortCompetitions(List<CompetitionModel> list) {
    final copy = List<CompetitionModel>.from(list);
    copy.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return copy;
  }

  static List<MatchModel> sortMatches(List<MatchModel> list) {
    final copy = List<MatchModel>.from(list);
    copy.sort((a, b) => a.date.compareTo(b.date));
    return copy;
  }

  /// Kept for hub internals. Does not pin World Cup in current-season lists.
  static List<CompetitionModel> applyCompetitionPriority(
    List<CompetitionModel> list, {
    CompetitionModel? fetchedWorldCup,
  }) {
    return List<CompetitionModel>.from(list);
  }

  static CompetitionModel? findWorldCup(List<CompetitionModel> list) {
    for (final c in list) {
      if (isWorldCupCompetition(c)) return c;
    }
    return null;
  }

  /// Home / hub featured match priority:
  /// 1. Live World Cup → 2. Upcoming WC today → 3. Latest finished WC → 4. Any live.
  static MatchModel? pickFeaturedMatch({
    required Iterable<MatchModel> liveMatches,
    required Iterable<MatchModel> wcDayMatches,
    Iterable<MatchModel> wcFinishedPool = const [],
  }) {
    for (final m in liveMatches) {
      if (isWorldCupMatch(m) && m.status == MatchStatus.live) return m;
    }

    final today = DateTime.now();
    bool sameDay(DateTime d) =>
        d.year == today.year && d.month == today.month && d.day == today.day;

    final wcUpcomingToday = wcDayMatches
        .where(
          (m) =>
              isWorldCupMatch(m) &&
              m.status == MatchStatus.upcoming &&
              sameDay(m.date),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (wcUpcomingToday.isNotEmpty) return wcUpcomingToday.first;

    final wcFinished = [...wcDayMatches, ...wcFinishedPool]
        .where((m) => isWorldCupMatch(m) && m.status == MatchStatus.finished)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (wcFinished.isNotEmpty) return wcFinished.first;

    final anyLive = liveMatches
        .where((m) => m.status == MatchStatus.live)
        .toList();
    if (anyLive.isNotEmpty) return sortMatches(anyLive).first;

    return null;
  }
}
