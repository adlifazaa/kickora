import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/constants/api_constants.dart';
import 'package:kickora/core/constants/api_mode.dart';
import 'package:kickora/data/repositories/football_repository.dart';
import 'package:kickora/data/sources/remote_football_source.dart';
import 'package:kickora/data/models/match_model.dart';

void main() {
  test('RemoteFootballSource is inactive in default mock mode', () {
    expect(ApiConstants.apiMode, ApiMode.mock);
    expect(RemoteFootballSource.isRemoteActive, isFalse);
  });

  test('FootballRepository getLiveMatches uses mock data by default', () async {
    final repo = FootballRepository();
    expect(repo.usesLiveApi, isFalse);

    final state = await repo.getLiveMatches();
    expect(state.hasError, isFalse);
    expect(state.fromMock, isTrue);
    expect(state.data, isNotNull);
    expect(
      state.data!.every((m) => m.status == MatchStatus.live),
      isTrue,
    );
    expect(state.data!.isNotEmpty, isTrue);
  });

  test('FootballRepository extended paths use mock by default', () async {
    final repo = FootballRepository();

    final scorers = await repo.getTopScorers(1);
    expect(scorers.fromMock, isTrue);
    expect(scorers.hasError, isFalse);

    final player = await repo.getPlayerById(1);
    expect(player.fromMock, isTrue);
    expect(player.hasError, isFalse);

    final competition = await repo.getCompetitionById(1);
    expect(competition.fromMock, isTrue);
    expect(competition.hasError, isFalse);
  });
}
