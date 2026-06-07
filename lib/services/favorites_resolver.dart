import '../data/mock_data.dart';
import '../data/models/competition_model.dart';
import '../data/models/match_model.dart';
import '../data/models/team_model.dart';
import '../data/repositories/football_repository.dart';

/// Resolved favorite entities for display (not just persisted ids).
class FavoritesSnapshot {
  const FavoritesSnapshot({
    this.teams = const [],
    this.competitions = const [],
    this.matches = const [],
  });

  final List<TeamModel> teams;
  final List<CompetitionModel> competitions;
  final List<MatchModel> matches;

  bool get isEmpty =>
      teams.isEmpty && competitions.isEmpty && matches.isEmpty;
}

/// Maps persisted favorite ids to [TeamModel]/[CompetitionModel]/[MatchModel].
class FavoritesResolver {
  FavoritesResolver(this._repository);

  final FootballRepository _repository;

  Future<FavoritesSnapshot> resolve({
    required Set<int> teamIds,
    required Set<int> competitionIds,
    required Set<int> matchIds,
  }) async {
    if (teamIds.isEmpty && competitionIds.isEmpty && matchIds.isEmpty) {
      return const FavoritesSnapshot();
    }

    if (!_repository.usesLiveApi) {
      return _resolveFromMock(
        teamIds: teamIds,
        competitionIds: competitionIds,
        matchIds: matchIds,
      );
    }

    return _resolveFromRemote(
      teamIds: teamIds,
      competitionIds: competitionIds,
      matchIds: matchIds,
    );
  }

  FavoritesSnapshot _resolveFromMock({
    required Set<int> teamIds,
    required Set<int> competitionIds,
    required Set<int> matchIds,
  }) {
    return FavoritesSnapshot(
      teams: MockData.teams
          .where((team) => teamIds.contains(team.id))
          .toList(),
      competitions: MockData.competitions
          .where((competition) => competitionIds.contains(competition.id))
          .toList(),
      matches: MockData.matches()
          .where((match) => matchIds.contains(match.id))
          .toList(),
    );
  }

  Future<FavoritesSnapshot> _resolveFromRemote({
    required Set<int> teamIds,
    required Set<int> competitionIds,
    required Set<int> matchIds,
  }) async {
    final matches = await _resolveMatches(matchIds);
    final competitions = await _resolveCompetitions(competitionIds);
    final teams = await _resolveTeams(
      teamIds: teamIds,
      matches: matches,
      competitionIds: competitionIds,
    );

    return FavoritesSnapshot(
      teams: teams,
      competitions: competitions,
      matches: matches,
    );
  }

  Future<List<MatchModel>> _resolveMatches(Set<int> matchIds) async {
    if (matchIds.isEmpty) return const [];

    final results = await Future.wait(
      matchIds.map((id) async {
        final state = await _repository.getMatchById(id);
        return state.data;
      }),
    );

    return results.whereType<MatchModel>().toList();
  }

  Future<List<CompetitionModel>> _resolveCompetitions(
    Set<int> competitionIds,
  ) async {
    if (competitionIds.isEmpty) return const [];

    final catalogState = await _repository.getCompetitions();
    final catalog = catalogState.data ?? const <CompetitionModel>[];
    final byId = {for (final c in catalog) c.id: c};

    final resolved = <CompetitionModel>[];
    for (final id in competitionIds) {
      final cached = byId[id];
      if (cached != null) {
        resolved.add(cached);
        continue;
      }
      final state = await _repository.getCompetitionById(id);
      final competition = state.data;
      if (competition != null) {
        resolved.add(competition);
      }
    }
    return resolved;
  }

  Future<List<TeamModel>> _resolveTeams({
    required Set<int> teamIds,
    required List<MatchModel> matches,
    required Set<int> competitionIds,
  }) async {
    if (teamIds.isEmpty) return const [];

    final resolved = <TeamModel>[];
    final foundIds = <int>{};

    void tryAdd(TeamModel team) {
      if (!teamIds.contains(team.id) || !foundIds.add(team.id)) return;
      resolved.add(team);
    }

    for (final match in matches) {
      tryAdd(match.homeTeam);
      tryAdd(match.awayTeam);
    }

    if (foundIds.length < teamIds.length) {
      for (final competitionId in competitionIds) {
        final state = await _repository.getCompetitionTeams(competitionId);
        for (final team in state.data ?? const <TeamModel>[]) {
          tryAdd(team);
        }
        if (foundIds.length == teamIds.length) break;
      }
    }

    return resolved;
  }
}
