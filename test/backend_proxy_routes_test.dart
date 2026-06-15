import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/constants/api_constants.dart';
import 'package:kickora/data/services/backend_proxy/backend_proxy_routes.dart';

void main() {
  test('backend proxy routes match production contract', () {
    const season = 2024;

    expect(
      BackendProxyRoutes.liveMatches(season: season).path,
      ApiConstants.backendMatchesLive,
    );
    expect(
      BackendProxyRoutes.matchesToday(season: season).path,
      ApiConstants.backendMatchesToday,
    );
    expect(
      BackendProxyRoutes.upcomingMatches(season: season).path,
      ApiConstants.backendMatchesUpcoming,
    );
    expect(
      BackendProxyRoutes.finishedMatches(season: season).path,
      ApiConstants.backendMatchesFinished,
    );
    expect(BackendProxyRoutes.competitions.path, ApiConstants.backendCompetitions);
    expect(
      BackendProxyRoutes.competitionById(id: 39, season: season).path,
      '/competitions/39',
    );
    expect(
      BackendProxyRoutes.standings(competitionId: 39, season: season).path,
      '/standings/39',
    );
    expect(
      BackendProxyRoutes.teams(competitionId: 39, season: season).path,
      '/teams/39',
    );
    expect(
      BackendProxyRoutes.playersSearch(query: 'salah', season: season).path,
      ApiConstants.backendPlayersSearch,
    );
    expect(
      BackendProxyRoutes.topScorers(competitionId: 39, season: season).path,
      '/competitions/39/top-scorers',
    );
    expect(
      BackendProxyRoutes.competitionMatches(competitionId: 1, season: season)
          .path,
      '/competitions/1/matches',
    );
    expect(
      BackendProxyRoutes.playerById(id: 276, season: season).path,
      '/players/276',
    );
    expect(BackendProxyRoutes.matchById(1001).path, '/matches/1001');
    expect(BackendProxyRoutes.matchEvents(1001).path, '/matches/1001/events');
    expect(
      BackendProxyRoutes.matchStatistics(1001).path,
      '/matches/1001/statistics',
    );
    expect(BackendProxyRoutes.matchLineups(1001).path, '/matches/1001/lineups');
  });
}
