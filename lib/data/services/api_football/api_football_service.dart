import '../../../core/constants/api_constants.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_debug_log.dart';
import '../../api/clients/football_remote_client.dart';
import '../../api/football_api_envelope.dart';
import '../../api/mappers/football_api_mapper.dart';
import '../../models/competition_model.dart';
import '../../models/lineup_model.dart';
import '../../models/match_model.dart';
import '../../models/player_model.dart';
import '../../models/standing_model.dart';
import '../../models/team_model.dart';
import '../football_api_routes.dart' as shared;
import 'api_football_routes.dart';

/// Prepared API-Football integration (direct mode only).
///
/// Disabled by default. Active only when:
/// `--dart-define=KICKORA_API_MODE=direct --dart-define=KICKORA_API_KEY=YOUR_KEY`
///
/// Never logs the API key. Use [ApiFootballService.safe] for non-throwing calls.
class ApiFootballService {
  ApiFootballService({DirectApiFootballClient? client})
      : _client = client ?? DirectApiFootballClient();

  final DirectApiFootballClient _client;

  int get _season => ApiConstants.currentSeason();

  /// True when direct mode and [KICKORA_API_KEY] are configured.
  bool get isEnabled =>
      ApiConstants.isDirectApi &&
      ApiConstants.hasApiKey &&
      _client.isConfigured;

  void logStatus() {
    ApiDebugLog.dataSource(
      operation: 'ApiFootballService',
      source: isEnabled ? 'api-football' : 'disabled',
      message:
          'mode=${ApiConstants.apiMode.name} enabled=$isEnabled (key not logged)',
    );
  }

  void _ensureEnabled() {
    if (!isEnabled) throw const ApiException.notConfigured();
  }

  Future<FootballApiEnvelope> _get(shared.ApiRouteRequest route) async {
    _ensureEnabled();
    return _client.get(route.path, queryParameters: route.queryParameters);
  }

  /// Runs [action] and maps unexpected errors to [ApiException] (no UI crash).
  static Future<T> safe<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.unknown(e.toString());
    }
  }

  Future<List<MatchModel>> getLiveMatches({
    int? competitionId,
  }) =>
      safe(() async {
        final route = ApiFootballRoutes.liveMatches(
          competitionId: competitionId,
          season: _season,
        );
        final envelope = await _get(route);
        return FootballApiMapper.liveMatches(envelope);
      });

  Future<List<MatchModel>> getMatchesToday({
    DateTime? date,
    int? competitionId,
  }) =>
      safe(() async {
        final route = ApiFootballRoutes.matchesToday(
          date: date,
          competitionId: competitionId,
          season: _season,
        );
        final envelope = await _get(route);
        return FootballApiMapper.matchesByDate(envelope);
      });

  Future<List<MatchModel>> getUpcomingMatches({
    DateTime? date,
    int? competitionId,
  }) =>
      safe(() async {
        final route = ApiFootballRoutes.upcomingMatches(
          date: date,
          competitionId: competitionId,
          season: _season,
        );
        final envelope = await _get(route);
        return FootballApiMapper.matchesByDate(envelope);
      });

  Future<List<MatchModel>> getFinishedMatches({
    DateTime? date,
    int? competitionId,
  }) =>
      safe(() async {
        final route = ApiFootballRoutes.matchesByDate(
          date: date ?? DateTime.now(),
          competitionId: competitionId,
          status: MatchStatus.finished,
          season: _season,
        );
        final envelope = await _get(route);
        final matches = FootballApiMapper.matchesByDate(envelope);
        return matches
            .where((m) => m.status == MatchStatus.finished)
            .toList(growable: false);
      });

  Future<List<CompetitionModel>> getCompetitions() => safe(() async {
        final envelope = await _get(ApiFootballRoutes.competitions);
        return FootballApiMapper.competitions(envelope);
      });

  Future<List<StandingModel>> getStandings({
    required int leagueId,
  }) =>
      safe(() async {
        final route = ApiFootballRoutes.standings(
          leagueId: leagueId,
          season: _season,
        );
        final envelope = await _get(route);
        return FootballApiMapper.standings(envelope);
      });

  Future<List<TeamModel>> getTeams({int? competitionId}) => safe(() async {
        final route = ApiFootballRoutes.teams(
          competitionId: competitionId,
          season: _season,
        );
        final envelope = await _get(route);
        return FootballApiMapper.teams(envelope);
      });

  Future<List<PlayerModel>> searchPlayers(String query) => safe(() async {
        final trimmed = query.trim();
        if (trimmed.isEmpty) return const [];
        final route = ApiFootballRoutes.playersSearch(
          query: trimmed,
          season: _season,
        );
        final envelope = await _get(route);
        return FootballApiMapper.searchPlayers(envelope);
      });

  Future<MatchModel?> getMatchDetails(int matchId) => safe(() async {
        final envelope = await _get(ApiFootballRoutes.matchById(matchId));
        return FootballApiMapper.matchDetails(envelope);
      });

  Future<List<MatchEventModel>> getMatchEvents(int matchId) => safe(() async {
        final fixture = await getMatchDetails(matchId);
        final envelope = await _get(ApiFootballRoutes.matchEvents(matchId));
        return FootballApiMapper.matchEvents(
          envelope,
          homeTeamId: fixture?.homeTeam.id,
          awayTeamId: fixture?.awayTeam.id,
        );
      });

  Future<List<MatchStatisticModel>> getMatchStatistics(int matchId) =>
      safe(() async {
        final fixture = await getMatchDetails(matchId);
        final envelope =
            await _get(ApiFootballRoutes.matchStatistics(matchId));
        return FootballApiMapper.matchStatistics(
          envelope,
          homeTeamId: fixture?.homeTeam.id,
        );
      });

  Future<({LineupModel? home, LineupModel? away})> getLineups(int matchId) =>
      safe(() async {
        final fixture = await getMatchDetails(matchId);
        final envelope = await _get(ApiFootballRoutes.matchLineups(matchId));
        return FootballApiMapper.matchLineups(
          envelope,
          homeTeamId: fixture?.homeTeam.id,
          awayTeamId: fixture?.awayTeam.id,
        );
      });
}
