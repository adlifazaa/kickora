import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/mock/mock_competition_key.dart';
import 'package:kickora/core/mock/mock_flag_key.dart';
import 'package:kickora/core/mock/mock_visual_resolver.dart';

void main() {
  group('MockVisualResolver', () {
    test('resolves mock team flags by short code', () {
      expect(
        MockVisualResolver.flagKeyForTeam(shortName: 'ARG'),
        MockFlagKey.argentina,
      );
      expect(
        MockVisualResolver.flagKeyForTeam(shortName: 'GER'),
        MockFlagKey.germany,
      );
    });

    test('resolves mock competition badges', () {
      expect(
        MockVisualResolver.competitionKey('WC'),
        MockCompetitionKey.worldCup,
      );
      expect(
        MockVisualResolver.competitionKey('PL'),
        MockCompetitionKey.premierLeague,
      );
    });

    test('resolves mock competition by name and id', () {
      expect(
        MockVisualResolver.competitionKeyFor(
          logo: 'XX',
          name: 'Premier League',
          id: 99,
        ),
        MockCompetitionKey.premierLeague,
      );
      expect(
        MockVisualResolver.competitionKeyFor(
          logo: 'WC',
          name: 'World Cup 2026',
        ),
        MockCompetitionKey.worldCup,
      );
      expect(
        MockVisualResolver.competitionKeyFor(
          logo: 'PL',
          id: 2,
        ),
        MockCompetitionKey.premierLeague,
      );
    });
  });
}
