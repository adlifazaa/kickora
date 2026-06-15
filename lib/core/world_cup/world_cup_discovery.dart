import '../../data/models/competition_model.dart';
import '../competition/competition_season_resolver.dart';
import 'world_cup_debug_log.dart';
import 'world_cup_priority.dart';

/// Discovers FIFA World Cup league id + active season from API metadata.
class WorldCupDiscovery {
  WorldCupDiscovery._();

  static int? _leagueId;
  static int? _season;
  static String? _name;

  static bool get isResolved => _leagueId != null && _season != null;

  static int? get leagueId => _leagueId;
  static int? get season => _season;
  static String? get name => _name;

  static void applyFromCompetitions(Iterable<CompetitionModel> competitions) {
    for (final c in competitions) {
      if (!WorldCupPriority.isWorldCupCompetition(c)) continue;
      _apply(c, source: 'competitions');
      return;
    }
  }

  static void applyFromCompetition(CompetitionModel competition) {
    if (!WorldCupPriority.isWorldCupCompetition(competition)) return;
    _apply(competition, source: 'competitionById');
  }

  static void _apply(CompetitionModel c, {required String source}) {
    _leagueId = c.id;
    _season = c.season ?? _season;
    _name = c.name;
    CompetitionSeasonResolver.register(c);
    WorldCupDebugLog.discovered(
      leagueId: c.id,
      season: _season,
      name: c.name,
      source: source,
    );
  }

  static void clear() {
    _leagueId = null;
    _season = null;
    _name = null;
  }
}
