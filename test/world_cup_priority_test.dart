import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/competition/competition_season_resolver.dart';
import 'package:kickora/core/constants/world_cup_config.dart';
import 'package:kickora/core/world_cup/world_cup_discovery.dart';
import 'package:kickora/core/world_cup/world_cup_priority.dart';
import 'package:kickora/data/models/competition_model.dart';
import 'package:kickora/data/models/match_model.dart';
import 'package:kickora/data/models/team_model.dart';

CompetitionModel _comp(int id, String name) => CompetitionModel(
      id: id,
      name: name,
      region: 'International',
      logo: '',
    );

extension on CompetitionModel {
  CompetitionModel copyWithSeason(int season) => CompetitionModel(
        id: id,
        name: name,
        region: region,
        logo: logo,
        season: season,
      );
}

MatchModel _match(int id, int compId, String compName) => MatchModel(
      id: id,
      homeTeam: const TeamModel(id: 1, name: 'A', shortName: 'A', logo: ''),
      awayTeam: const TeamModel(id: 2, name: 'B', shortName: 'B', logo: ''),
      homeScore: 0,
      awayScore: 0,
      status: MatchStatus.upcoming,
      timeLabel: '18:00',
      competition: _comp(compId, compName),
      date: DateTime(2026, 6, 10),
    );

void main() {
  setUp(() {
    CompetitionSeasonResolver.clear();
    WorldCupDiscovery.clear();
    WorldCupDiscovery.applyFromCompetition(
      _comp(1, 'World Cup').copyWithSeason(2026),
    );
  });

  test('WorldCupConfig still resolves API-Football league id 1', () {
    expect(WorldCupConfig.competitionId, 1);
    expect(WorldCupConfig.season, 2026);
  });

  test('sortCompetitions no longer pins World Cup first', () {
    final sorted = WorldCupPriority.sortCompetitions([
      _comp(39, 'Premier League'),
      _comp(WorldCupConfig.competitionId, 'World Cup'),
      _comp(140, 'La Liga'),
    ]);
    expect(sorted.first.id, isNot(WorldCupConfig.competitionId));
  });

  test('applyCompetitionPriority does not insert missing World Cup', () {
    final out = WorldCupPriority.applyCompetitionPriority(
      [_comp(39, 'Premier League')],
      fetchedWorldCup: _comp(WorldCupConfig.competitionId, 'World Cup'),
    );
    expect(out.map((c) => c.id), isNot(contains(WorldCupConfig.competitionId)));
    expect(out.length, 1);
  });

  test('sortMatches no longer pins World Cup fixtures first', () {
    final sorted = WorldCupPriority.sortMatches([
      _match(1, 39, 'Premier League'),
      _match(2, WorldCupConfig.competitionId, 'World Cup'),
      _match(3, 140, 'La Liga'),
    ]);
    expect(sorted.first.competition.id, isNot(WorldCupConfig.competitionId));
  });

  test('empty World Cup API response does not crash prioritizer', () {
    expect(
      WorldCupPriority.applyCompetitionPriority([]),
      isEmpty,
    );
    expect(
      WorldCupPriority.sortMatches([]),
      isEmpty,
    );
  });

  test('FIFA Club World Cup is not treated as main World Cup', () {
    expect(
      WorldCupPriority.isWorldCupBadge(
        competitionId: 15,
        competitionName: 'FIFA Club World Cup',
      ),
      isFalse,
    );
    expect(
      WorldCupPriority.isWorldCupBadge(
        competitionId: 1,
        competitionName: 'World Cup',
      ),
      isTrue,
    );
  });
}
