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

  test('WorldCupConfig resolves API-Football league id 1 season 2026', () {
    expect(WorldCupConfig.competitionId, 1);
    expect(WorldCupConfig.season, 2026);
  });

  test('sortCompetitions puts World Cup first', () {
    final sorted = WorldCupPriority.sortCompetitions([
      _comp(39, 'Premier League'),
      _comp(WorldCupConfig.competitionId, 'World Cup'),
      _comp(140, 'La Liga'),
    ]);
    expect(sorted.first.id, WorldCupConfig.competitionId);
  });

  test('applyCompetitionPriority inserts fetched World Cup when missing', () {
    final out = WorldCupPriority.applyCompetitionPriority(
      [_comp(39, 'Premier League')],
      fetchedWorldCup: _comp(WorldCupConfig.competitionId, 'World Cup'),
    );
    expect(out.first.id, WorldCupConfig.competitionId);
    expect(out.first.isFeatured, isTrue);
    expect(out.length, 2);
  });

  test('sortMatches puts World Cup fixtures first', () {
    final sorted = WorldCupPriority.sortMatches([
      _match(1, 39, 'Premier League'),
      _match(2, WorldCupConfig.competitionId, 'World Cup'),
      _match(3, 140, 'La Liga'),
    ]);
    expect(sorted.first.competition.id, WorldCupConfig.competitionId);
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
    expect(
      WorldCupPriority.applyCompetitionPriority(
        [_comp(39, 'Premier League')],
        fetchedWorldCup: null,
      ).length,
      1,
    );
  });

  test('FIFA Club World Cup is not treated as main World Cup', () {
    expect(
      WorldCupPriority.isWorldCupBadge(competitionId: 15, competitionName: 'FIFA Club World Cup'),
      isFalse,
    );
    expect(
      WorldCupPriority.isWorldCupBadge(competitionId: 1, competitionName: 'World Cup'),
      isTrue,
    );
  });

  test('pickFeaturedMatch prefers live World Cup over other live', () {
    final wcLive = _match(1, 1, 'World Cup').copyWith(
      status: MatchStatus.live,
    );
    final otherLive = _match(2, 39, 'Premier League').copyWith(
      status: MatchStatus.live,
    );
    final picked = WorldCupPriority.pickFeaturedMatch(
      liveMatches: [otherLive, wcLive],
      wcDayMatches: const [],
    );
    expect(picked?.id, wcLive.id);
  });

  test('pickFeaturedMatch uses upcoming WC today before other live', () {
    final today = DateTime.now();
    final wcUpcoming = _match(3, 1, 'World Cup').copyWith(
      date: DateTime(today.year, today.month, today.day, 20),
    );
    final otherLive = _match(4, 39, 'Premier League').copyWith(
      status: MatchStatus.live,
    );
    final picked = WorldCupPriority.pickFeaturedMatch(
      liveMatches: [otherLive],
      wcDayMatches: [wcUpcoming],
    );
    expect(picked?.id, wcUpcoming.id);
  });
}
