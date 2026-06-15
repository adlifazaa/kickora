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
    copy.sort((a, b) {
      final aw = isWorldCupCompetition(a) ? 0 : 1;
      final bw = isWorldCupCompetition(b) ? 0 : 1;
      if (aw != bw) return aw.compareTo(bw);
      return a.name.compareTo(b.name);
    });
    return copy;
  }

  static List<MatchModel> sortMatches(List<MatchModel> list) {
    final copy = List<MatchModel>.from(list);
    copy.sort((a, b) {
      final aw = isWorldCupMatch(a) ? 0 : 1;
      final bw = isWorldCupMatch(b) ? 0 : 1;
      if (aw != bw) return aw.compareTo(bw);
      return a.date.compareTo(b.date);
    });
    return copy;
  }

  /// Ensures World Cup is present and marked featured; does not remove others.
  static List<CompetitionModel> applyCompetitionPriority(
    List<CompetitionModel> list, {
    CompetitionModel? fetchedWorldCup,
  }) {
    var out = List<CompetitionModel>.from(list);
    final hasWorldCup = out.any(isWorldCupCompetition);
    if (!hasWorldCup && fetchedWorldCup != null) {
      out.insert(0, fetchedWorldCup.copyWith(isFeatured: true));
    }
    out = out
        .map(
          (c) => isWorldCupCompetition(c)
              ? CompetitionModel(
                  id: c.id,
                  name: c.name,
                  region: c.region,
                  logo: c.logo,
                  countryCode: c.countryCode,
                  countryFlagUrl: c.countryFlagUrl,
                  season: c.season ?? WorldCupConfig.season,
                  competitionType: c.competitionType,
                  isFeatured: true,
                  teamCount: c.teamCount,
                  matchesToday: c.matchesToday,
                )
              : c,
        )
        .toList();
    return sortCompetitions(out);
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

extension _CompetitionCopy on CompetitionModel {
  CompetitionModel copyWith({
    bool? isFeatured,
    int? season,
  }) {
    return CompetitionModel(
      id: id,
      name: name,
      region: region,
      logo: logo,
      countryCode: countryCode,
      countryFlagUrl: countryFlagUrl,
      season: season ?? this.season,
      competitionType: competitionType,
      isFeatured: isFeatured ?? this.isFeatured,
      teamCount: teamCount,
      matchesToday: matchesToday,
    );
  }
}
