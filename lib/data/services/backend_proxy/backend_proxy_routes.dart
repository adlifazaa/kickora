import '../../../core/constants/api_constants.dart';
import '../football_api_routes.dart';

/// Kickora backend proxy routes only (`KICKORA_BACKEND_URL`).
class BackendProxyRoutes {
  BackendProxyRoutes._();

  static ApiRouteRequest liveMatches({
    int? competitionId,
    int? season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.backendMatchesLive,
        queryParameters: _matchQuery(
          competitionId: competitionId,
          season: season,
        ),
      );

  static ApiRouteRequest matchesToday({
    DateTime? date,
    int? competitionId,
    int? season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.backendMatchesToday,
        queryParameters: _matchQuery(
          date: date,
          competitionId: competitionId,
          season: season,
        ),
      );

  static ApiRouteRequest upcomingMatches({
    DateTime? date,
    int? competitionId,
    int? season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.backendMatchesUpcoming,
        queryParameters: _matchQuery(
          date: date,
          competitionId: competitionId,
          season: season,
        ),
      );

  static ApiRouteRequest finishedMatches({
    DateTime? date,
    int? competitionId,
    int? season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.backendMatchesFinished,
        queryParameters: _matchQuery(
          date: date,
          competitionId: competitionId,
          season: season,
        ),
      );

  static const ApiRouteRequest competitions = ApiRouteRequest(
    path: ApiConstants.backendCompetitions,
  );

  static ApiRouteRequest standings({
    required int competitionId,
    required int season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.backendStandings(competitionId),
        queryParameters: {'season': '$season'},
      );

  static ApiRouteRequest teams({
    required int competitionId,
    required int season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.backendTeams(competitionId),
        queryParameters: {'season': '$season'},
      );

  static ApiRouteRequest playersSearch({
    required String query,
    required int season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.backendPlayersSearch,
        queryParameters: {'q': query, 'season': '$season'},
      );

  static ApiRouteRequest competitionById({
    required int id,
    int? season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.backendCompetition(id),
        queryParameters:
            season != null ? {'season': '$season'} : null,
      );

  static ApiRouteRequest topScorers({
    required int competitionId,
    required int season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.backendTopScorers(competitionId),
        queryParameters: {'season': '$season'},
      );

  static ApiRouteRequest competitionMatches({
    required int competitionId,
    required int season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.backendCompetitionMatches(competitionId),
        queryParameters: {'season': '$season'},
      );

  static ApiRouteRequest playerById({
    required int id,
    required int season,
  }) =>
      ApiRouteRequest(
        path: ApiConstants.backendPlayer(id),
        queryParameters: {'season': '$season'},
      );

  static const ApiRouteRequest worldCupNews = ApiRouteRequest(
    path: ApiConstants.backendWorldCupNews,
  );

  static ApiRouteRequest matchById(int id) => ApiRouteRequest(
        path: ApiConstants.backendMatch(id),
      );

  static ApiRouteRequest matchEvents(int id) => ApiRouteRequest(
        path: ApiConstants.backendMatchEvents(id),
      );

  static ApiRouteRequest matchStatistics(int id) => ApiRouteRequest(
        path: ApiConstants.backendMatchStatistics(id),
      );

  static ApiRouteRequest matchLineups(int id) => ApiRouteRequest(
        path: ApiConstants.backendMatchLineups(id),
      );

  static Map<String, String>? _matchQuery({
    DateTime? date,
    int? competitionId,
    int? season,
  }) {
    final query = <String, String>{
      if (date != null) 'date': ApiConstants.formatDate(date),
      if (competitionId != null) 'competitionId': '$competitionId',
      if (competitionId != null && season != null) 'season': '$season',
    };
    return query.isEmpty ? null : query;
  }
}
