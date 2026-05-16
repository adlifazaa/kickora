import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/data/models/match_event_model.dart';
import 'package:kickora/data/services/api_football_parser.dart';

void main() {
  group('ApiFootballParser.parseEvents', () {
    test('maps goals, cards, and substitutions with home side', () {
      final events = ApiFootballParser.parseEvents(
        {
          'response': [
            {
              'time': {'elapsed': 12, 'extra': null},
              'team': {'id': 1, 'name': 'Home FC'},
              'player': {'name': 'Scorer'},
              'assist': {'name': 'Assist'},
              'type': 'Goal',
              'detail': 'Normal Goal',
            },
            {
              'time': {'elapsed': 55, 'extra': null},
              'team': {'id': 2, 'name': 'Away FC'},
              'player': {'name': 'Sub In'},
              'assist': {'name': 'Sub Out'},
              'type': 'subst',
              'detail': 'Substitution 1',
            },
            {
              'time': {'elapsed': 70, 'extra': null},
              'team': {'id': 1, 'name': 'Home FC'},
              'player': {'name': 'Booked'},
              'assist': null,
              'type': 'Card',
              'detail': 'Yellow Card',
            },
          ],
        },
        homeTeamId: 1,
        awayTeamId: 2,
      );

      expect(events, hasLength(3));
      expect(events[0].type, MatchEventType.goal);
      expect(events[0].isHome, isTrue);
      expect(events[0].assistName, 'Assist');
      expect(events[1].type, MatchEventType.substitution);
      expect(events[1].isHome, isFalse);
      expect(events[1].description, contains('Sub Out'));
      expect(events[2].type, MatchEventType.yellowCard);
    });
  });

  group('ApiFootballParser.parseStatistics', () {
    test('orders stats by home team id', () {
      final stats = ApiFootballParser.parseStatistics(
        {
          'response': [
            {
              'team': {'id': 99},
              'statistics': [
                {'type': 'Shots on Goal', 'value': 2},
              ],
            },
            {
              'team': {'id': 1},
              'statistics': [
                {'type': 'Shots on Goal', 'value': 5},
              ],
            },
          ],
        },
        homeTeamId: 1,
      );

      expect(stats, isNotEmpty);
      expect(stats.first.homeValue, '5');
      expect(stats.first.awayValue, '2');
    });
  });

  group('ApiFootballParser.parseLineups', () {
    test('assigns lineups using team ids', () {
      final result = ApiFootballParser.parseLineups(
        {
          'response': [
            {
              'team': {'id': 2, 'name': 'Away'},
              'formation': '4-4-2',
              'coach': {'name': 'Away Coach'},
              'startXI': [],
              'substitutes': [],
            },
            {
              'team': {'id': 1, 'name': 'Home'},
              'formation': '4-3-3',
              'coach': {'name': 'Home Coach'},
              'startXI': [],
              'substitutes': [],
            },
          ],
        },
        homeTeamId: 1,
        awayTeamId: 2,
      );

      expect(result.home?.formation, '4-3-3');
      expect(result.away?.formation, '4-4-2');
    });
  });
}
