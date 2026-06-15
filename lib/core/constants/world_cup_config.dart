import '../../data/models/competition_model.dart';
import '../competition/competition_season_resolver.dart';
import '../world_cup/world_cup_discovery.dart';

/// FIFA World Cup — league id and season resolved from live API metadata.
class WorldCupConfig {
  WorldCupConfig._();

  /// Resolved from `/competitions` or `/competitions/{id}` (`seasons.current`).
  static int get competitionId =>
      WorldCupDiscovery.leagueId ?? _bootstrapLeagueId;

  /// Active World Cup season year from API (e.g. 2026 during FIFA World Cup 2026).
  static int get season =>
      WorldCupDiscovery.season ??
      CompetitionSeasonResolver.seasonFor(_bootstrapLeagueId) ??
      DateTime.now().year;

  static const int _bootstrapLeagueId = 1;

  static String get displayName => WorldCupDiscovery.name ?? 'World Cup';

  static CompetitionModel fallbackCompetition() => CompetitionModel(
        id: competitionId,
        name: displayName,
        region: 'World',
        logo: '',
        season: season,
        isFeatured: true,
      );

  /// Tournament window for schedule lazy-loading (UTC dates).
  static DateTime get tournamentStartUtc => DateTime.utc(2026, 6, 11);

  static DateTime get tournamentEndUtc => DateTime.utc(2026, 7, 19);

  /// Last day of the group stage (UTC) — knockout begins 2026-06-28.
  static DateTime get groupStageEndUtc =>
      DateTime.utc(2026, 6, 27, 23, 59, 59);

  /// Final match kickoff for countdown (UTC).
  static DateTime get finalKickoffUtc => DateTime.utc(2026, 7, 19, 19, 0);

  static List<DateTime> get tournamentDays {
    final days = <DateTime>[];
    var d = tournamentStartUtc;
    while (!d.isAfter(tournamentEndUtc)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }
    return days;
  }
}
