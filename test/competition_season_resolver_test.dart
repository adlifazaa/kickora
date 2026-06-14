import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/competition/competition_season_resolver.dart';
import 'package:kickora/core/constants/world_cup_config.dart';
import 'package:kickora/core/world_cup/world_cup_discovery.dart';
import 'package:kickora/data/models/competition_model.dart';

void main() {
  setUp(() {
    CompetitionSeasonResolver.clear();
    WorldCupDiscovery.clear();
  });

  test('registers league season from competition metadata', () {
    CompetitionSeasonResolver.register(
      const CompetitionModel(
        id: 1,
        name: 'World Cup',
        region: 'World',
        logo: '',
        season: 2026,
      ),
    );
    expect(CompetitionSeasonResolver.seasonFor(1), 2026);
    expect(CompetitionSeasonResolver.seasonForOrDefault(1), 2026);
  });

  test('WorldCupDiscovery picks main World Cup with API season', () {
    WorldCupDiscovery.applyFromCompetitions([
      const CompetitionModel(id: 15, name: 'FIFA Club World Cup', region: '', logo: ''),
      const CompetitionModel(
        id: 1,
        name: 'World Cup',
        region: 'World',
        logo: '',
        season: 2026,
      ),
    ]);
    expect(WorldCupDiscovery.leagueId, 1);
    expect(WorldCupDiscovery.season, 2026);
    expect(WorldCupConfig.season, 2026);
  });
}
