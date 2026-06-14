import '../constants/api_constants.dart';
import '../../data/models/competition_model.dart';

/// Maps API-Football league id → active season year from competition metadata.
class CompetitionSeasonResolver {
  CompetitionSeasonResolver._();

  static final Map<int, int> _seasons = {};

  static void register(CompetitionModel competition) {
    final season = competition.season;
    if (season != null) {
      _seasons[competition.id] = season;
    }
  }

  static void registerAll(Iterable<CompetitionModel> competitions) {
    for (final c in competitions) {
      register(c);
    }
  }

  static int? seasonFor(int leagueId) => _seasons[leagueId];

  /// Season for league-scoped fixture/standings calls; falls back to football
  /// season calendar only when metadata is unknown.
  static int seasonForOrDefault(int leagueId) =>
      seasonFor(leagueId) ?? ApiConstants.currentSeason();

  static void clear() => _seasons.clear();
}
