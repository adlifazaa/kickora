import '../../core/constants/api_constants.dart';
import '../../core/constants/api_mode_service.dart';
import '../models/match_model.dart';

/// Resolves HTTP path + query for [FootballApiService] based on effective [ApiMode].
///
/// Backend responses should mirror API-Football JSON (`response` array) so existing
/// parsers keep working until a dedicated DTO layer is added.
class FootballApiRoutes {
  FootballApiRoutes._();

  static ApiRouteRequest liveMatches({
    DateTime? date,
    int? competitionId,
    int? season,
  }) {
    if (ApiModeService.isBackendProxy) {
      return ApiRouteRequest(
        path: ApiConstants.backendMatchesLive,
        queryParameters: _backendMatchQuery(
          date: date,
          competitionId: competitionId,
          season: season,
        ),
      );
    }
    return ApiRouteRequest(
      path: ApiConstants.fixtures,
      queryParameters: {
        'live': 'all',
        if (competitionId != null) 'league': '$competitionId',
        if (competitionId != null && season != null) 'season': '$season',
      },
    );
  }

  static ApiRouteRequest matchesByDate({
    DateTime? date,
    int? competitionId,
    MatchStatus? status,
    int? season,
  }) {
    if (ApiModeService.isBackendProxy) {
      final path = switch (status) {
        MatchStatus.live => ApiConstants.backendMatchesLive,
        MatchStatus.upcoming => ApiConstants.backendMatchesUpcoming,
        MatchStatus.finished => ApiConstants.backendMatchesFinished,
        null => ApiConstants.backendMatchesToday,
      };
      return ApiRouteRequest(
        path: path,
        queryParameters: _backendMatchQuery(
          date: date,
          competitionId: competitionId,
          season: season,
        ),
      );
    }

    final query = <String, String>{
      if (date != null) 'date': ApiConstants.formatDate(date),
      if (competitionId != null) 'league': '$competitionId',
      if (competitionId != null && season != null) 'season': '$season',
    };

    return ApiRouteRequest(
      path: ApiConstants.fixtures,
      queryParameters: query.isEmpty ? {'next': '50'} : query,
    );
  }

  static ApiRouteRequest matchById(int id) {
    if (ApiModeService.isBackendProxy) {
      return ApiRouteRequest(path: ApiConstants.backendMatch(id));
    }
    return ApiRouteRequest(
      path: ApiConstants.fixtures,
      queryParameters: {'id': '$id'},
    );
  }

  static ApiRouteRequest matchEvents(int matchId) {
    if (ApiModeService.isBackendProxy) {
      return ApiRouteRequest(path: ApiConstants.backendMatchEvents(matchId));
    }
    return ApiRouteRequest(
      path: ApiConstants.fixtureEvents,
      queryParameters: {'fixture': '$matchId'},
    );
  }

  static ApiRouteRequest matchStatistics(int matchId) {
    if (ApiModeService.isBackendProxy) {
      return ApiRouteRequest(path: ApiConstants.backendMatchStatistics(matchId));
    }
    return ApiRouteRequest(
      path: ApiConstants.fixtureStatistics,
      queryParameters: {'fixture': '$matchId'},
    );
  }

  static ApiRouteRequest matchLineups(int matchId) {
    if (ApiModeService.isBackendProxy) {
      return ApiRouteRequest(path: ApiConstants.backendMatchLineups(matchId));
    }
    return ApiRouteRequest(
      path: ApiConstants.fixtureLineups,
      queryParameters: {'fixture': '$matchId'},
    );
  }

  static ApiRouteRequest competitions() {
    if (ApiModeService.isBackendProxy) {
      return const ApiRouteRequest(path: ApiConstants.backendCompetitions);
    }
    return const ApiRouteRequest(
      path: ApiConstants.leagues,
      queryParameters: {'current': 'true'},
    );
  }

  static ApiRouteRequest competitionById(int id, {int? season}) {
    if (ApiModeService.isBackendProxy) {
      return ApiRouteRequest(
        path: ApiConstants.backendCompetition(id),
        queryParameters:
            season != null ? {'season': '$season'} : null,
      );
    }
    return ApiRouteRequest(
      path: ApiConstants.leagues,
      queryParameters: {
        'id': '$id',
        if (season != null) 'season': '$season',
      },
    );
  }

  static ApiRouteRequest standings({
    required int leagueId,
    required int season,
  }) {
    if (ApiModeService.isBackendProxy) {
      return ApiRouteRequest(
        path: ApiConstants.backendStandings(leagueId),
        queryParameters: {'season': '$season'},
      );
    }
    return ApiRouteRequest(
      path: ApiConstants.standings,
      queryParameters: {'league': '$leagueId', 'season': '$season'},
    );
  }

  static bool get supportsExtendedPlayerRoutes => !ApiModeService.isMock;

  static ApiRouteRequest teams({
    int? competitionId,
    required int season,
  }) {
    if (ApiModeService.isBackendProxy && competitionId != null) {
      return ApiRouteRequest(
        path: ApiConstants.backendTeams(competitionId),
        queryParameters: {'season': '$season'},
      );
    }
    return ApiRouteRequest(
      path: ApiConstants.teams,
      queryParameters: {
        if (competitionId != null) 'league': '$competitionId',
        if (competitionId != null) 'season': '$season',
      },
    );
  }

  static ApiRouteRequest playersSearch({
    required String query,
    required int season,
  }) {
    if (ApiModeService.isBackendProxy) {
      return ApiRouteRequest(
        path: ApiConstants.backendPlayersSearch,
        queryParameters: {'q': query, 'season': '$season'},
      );
    }
    return ApiRouteRequest(
      path: ApiConstants.players,
      queryParameters: {'search': query, 'season': '$season'},
    );
  }

  static ApiRouteRequest topScorers({
    required int competitionId,
    required int season,
  }) {
    if (ApiModeService.isBackendProxy) {
      return ApiRouteRequest(
        path: ApiConstants.backendTopScorers(competitionId),
        queryParameters: {'season': '$season'},
      );
    }
    return ApiRouteRequest(
      path: ApiConstants.playersTopScorers,
      queryParameters: {'league': '$competitionId', 'season': '$season'},
    );
  }

  static ApiRouteRequest playerById({
    required int id,
    required int season,
  }) {
    if (ApiModeService.isBackendProxy) {
      return ApiRouteRequest(
        path: ApiConstants.backendPlayer(id),
        queryParameters: {'season': '$season'},
      );
    }
    return ApiRouteRequest(
      path: ApiConstants.players,
      queryParameters: {'id': '$id', 'season': '$season'},
    );
  }

  static Map<String, String>? _backendMatchQuery({
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

/// Path and optional query for a single GET request.
class ApiRouteRequest {
  const ApiRouteRequest({
    required this.path,
    this.queryParameters,
  });

  final String path;
  final Map<String, String>? queryParameters;
}
