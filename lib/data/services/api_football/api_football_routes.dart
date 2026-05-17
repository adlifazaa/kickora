import '../../../core/constants/api_constants.dart';
import '../../models/match_model.dart';
import '../football_api_routes.dart';

/// Direct API-Football v3 routes only (no backend proxy paths).
class ApiFootballRoutes {
  ApiFootballRoutes._();

  static ApiRouteRequest liveMatches({
    DateTime? date,
    int? competitionId,
    required int season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.fixtures,
        queryParameters: {
          'live': 'all',
          if (competitionId != null) 'league': '$competitionId',
          if (competitionId != null) 'season': '$season',
        },
      );

  static ApiRouteRequest matchesToday({
    DateTime? date,
    int? competitionId,
    required int season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.fixtures,
        queryParameters: {
          'date': ApiConstants.formatDate(date ?? DateTime.now()),
          if (competitionId != null) 'league': '$competitionId',
          if (competitionId != null) 'season': '$season',
        },
      );

  static ApiRouteRequest upcomingMatches({
    DateTime? date,
    int? competitionId,
    required int season,
  }) =>
      matchesByDate(
        date: date ?? DateTime.now(),
        competitionId: competitionId,
        status: MatchStatus.upcoming,
        season: season,
      );

  static ApiRouteRequest matchesByDate({
    DateTime? date,
    int? competitionId,
    MatchStatus? status,
    required int season,
  }) {
    final query = <String, String>{
      if (date != null) 'date': ApiConstants.formatDate(date),
      if (competitionId != null) 'league': '$competitionId',
      if (competitionId != null) 'season': '$season',
    };
    if (status == MatchStatus.upcoming && date == null) {
      query['next'] = '50';
    }
    return ApiRouteRequest(
      path: ApiConstants.fixtures,
      queryParameters: query,
    );
  }

  static ApiRouteRequest matchById(int id) => ApiRouteRequest(
        path: ApiConstants.fixtures,
        queryParameters: {'id': '$id'},
      );

  static ApiRouteRequest matchEvents(int matchId) => ApiRouteRequest(
        path: ApiConstants.fixtureEvents,
        queryParameters: {'fixture': '$matchId'},
      );

  static ApiRouteRequest matchStatistics(int matchId) => ApiRouteRequest(
        path: ApiConstants.fixtureStatistics,
        queryParameters: {'fixture': '$matchId'},
      );

  static ApiRouteRequest matchLineups(int matchId) => ApiRouteRequest(
        path: ApiConstants.fixtureLineups,
        queryParameters: {'fixture': '$matchId'},
      );

  static const ApiRouteRequest competitions = ApiRouteRequest(
    path: ApiConstants.leagues,
    queryParameters: {'current': 'true'},
  );

  static ApiRouteRequest standings({
    required int leagueId,
    required int season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.standings,
        queryParameters: {'league': '$leagueId', 'season': '$season'},
      );

  static ApiRouteRequest teams({
    int? competitionId,
    required int season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.teams,
        queryParameters: {
          if (competitionId != null) 'league': '$competitionId',
          if (competitionId != null) 'season': '$season',
        },
      );

  static ApiRouteRequest playersSearch({
    required String query,
    required int season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.players,
        queryParameters: {'search': query, 'season': '$season'},
      );

  static ApiRouteRequest competitionById({
    required int id,
    required int season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.leagues,
        queryParameters: {'id': '$id', 'season': '$season'},
      );

  static ApiRouteRequest topScorers({
    required int competitionId,
    required int season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.playersTopScorers,
        queryParameters: {'league': '$competitionId', 'season': '$season'},
      );

  static ApiRouteRequest playerById({
    required int id,
    required int season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.players,
        queryParameters: {'id': '$id', 'season': '$season'},
      );
}
