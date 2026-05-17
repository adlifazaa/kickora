import '../../models/competition_model.dart';
import '../../models/formation_model.dart';
import '../../models/lineup_model.dart';
import '../../models/match_model.dart';
import '../../models/player_model.dart';
import '../../models/standing_model.dart';
import '../../models/team_model.dart';
import '../../services/api_football_parser.dart';
import '../football_api_envelope.dart';

/// Maps remote JSON envelopes into existing Kickora domain models.
///
/// Backed by [ApiFootballParser] so direct API and backend proxy share one path.
class FootballApiMapper {
  const FootballApiMapper._();

  static List<MatchModel> liveMatches(FootballApiEnvelope body) =>
      matchesByDate(body);

  static List<MatchModel> matchesByDate(FootballApiEnvelope body) =>
      ApiFootballParser.parseFixtures(body.raw);

  static MatchModel? matchDetails(FootballApiEnvelope body) {
    final list = ApiFootballParser.parseFixtures(body.raw);
    return list.isEmpty ? null : list.first;
  }

  static List<MatchEventModel> matchEvents(
    FootballApiEnvelope body, {
    int? homeTeamId,
    int? awayTeamId,
  }) =>
      ApiFootballParser.parseEvents(
        body.raw,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
      );

  static List<MatchStatisticModel> matchStatistics(
    FootballApiEnvelope body, {
    int? homeTeamId,
  }) =>
      ApiFootballParser.parseStatistics(body.raw, homeTeamId: homeTeamId);

  static ({LineupModel? home, LineupModel? away}) matchLineups(
    FootballApiEnvelope body, {
    int? homeTeamId,
    int? awayTeamId,
  }) =>
      ApiFootballParser.parseLineups(
        body.raw,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
      );

  static FormationModel? formationFromLineups(
    ({LineupModel? home, LineupModel? away}) lineups, {
    required bool isHome,
  }) {
    final lineup = isHome ? lineups.home : lineups.away;
    return lineup?.resolvedFormation;
  }

  static List<CompetitionModel> competitions(FootballApiEnvelope body) =>
      ApiFootballParser.parseLeagues(body.raw);

  static CompetitionModel? competitionById(FootballApiEnvelope body) {
    final list = competitions(body);
    return list.isEmpty ? null : list.first;
  }

  static List<TeamModel> teams(FootballApiEnvelope body) =>
      ApiFootballParser.parseTeams(body.raw);

  static List<PlayerModel> players(FootballApiEnvelope body) =>
      ApiFootballParser.parseTopScorers(body.raw);

  static List<PlayerModel> searchPlayers(FootballApiEnvelope body) =>
      ApiFootballParser.parseTopScorers(body.raw);

  static PlayerModel? playerById(FootballApiEnvelope body) =>
      ApiFootballParser.parsePlayer(body.raw);

  static List<StandingModel> standings(FootballApiEnvelope body) =>
      ApiFootballParser.parseStandings(body.raw);
}
