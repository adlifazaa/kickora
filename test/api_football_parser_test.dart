import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/data/models/match_event_model.dart';
import 'package:kickora/data/services/api_football_parser.dart';

void main() {
  group('ApiFootballParser.parseFixture teams', () {
    test('maps team.logo and league country flag', () {
      final match = ApiFootballParser.parseFixture({
        'fixture': {
          'id': 1,
          'date': '2026-05-16T15:00:00+00:00',
          'status': {'short': 'NS', 'elapsed': null},
          'venue': {'name': 'Stadium'},
        },
        'league': {
          'id': 39,
          'name': 'Premier League',
          'country': {
            'name': 'England',
            'code': 'GB',
            'flag': 'https://media.api-sports.io/flags/gb.svg',
          },
          'logo': 'https://media.api-sports.io/football/leagues/39.png',
        },
        'teams': {
          'home': {
            'id': 33,
            'name': 'Manchester United',
            'code': 'MUN',
            'logo': 'https://media.api-sports.io/football/teams/33.png',
          },
          'away': {
            'id': 34,
            'name': 'Newcastle',
            'logo': 'https://media.api-sports.io/football/teams/34.png',
          },
        },
        'goals': {'home': null, 'away': null},
        'score': {'fulltime': {'home': null, 'away': null}},
      });

      expect(match.homeTeam.logoUrl, contains('teams/33'));
      expect(match.awayTeam.logoUrl, contains('teams/34'));
      expect(match.homeTeam.flagUrl, contains('flags/gb'));
    });
  });

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
