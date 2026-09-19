import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/world_cup/world_cup_priority.dart';
import 'package:kickora/data/models/competition_model.dart';

void main() {
  test('normal navigation no longer routes World Cup to the dedicated hub', () {
    final routes = File('lib/app/routes.dart').readAsStringSync();
    expect(routes.contains('WorldCupHubScreen'), isFalse);
    expect(routes.contains('CompetitionDetailsScreen'), isTrue);
  });

  test('home no longer renders the dedicated World Cup banner', () {
    final home = File('lib/screens/home_screen.dart').readAsStringSync();
    expect(home.contains('_WorldCupShortcutCard'), isFalse);
    expect(home.contains('WorldCupConfig.fallbackCompetition'), isFalse);
    expect(home.contains('TopCompetitionsModule'), isTrue);
  });

  test('World Cup helper no longer pins competitions for callers', () {
    final ranked = WorldCupPriority.sortCompetitions([
      const CompetitionModel(
        id: 39,
        name: 'Premier League',
        region: 'England',
        logo: '',
      ),
      const CompetitionModel(
        id: 1,
        name: 'World Cup',
        region: 'World',
        logo: '',
      ),
    ]);
    expect(ranked.first.id, 39);
  });
}
