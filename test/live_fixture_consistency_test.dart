import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/constants/api_cache_policy.dart';
import 'package:kickora/data/models/competition_model.dart';
import 'package:kickora/data/models/match_model.dart';
import 'package:kickora/data/models/team_model.dart';
import 'package:kickora/data/services/api_football_parser.dart';
import 'package:kickora/utils/api_datetime.dart';
import 'package:kickora/utils/live_match_overlay.dart';
import 'package:kickora/utils/world_cup_match_date_formatter.dart';

MatchModel _match({
  required int id,
  required int homeScore,
  required int awayScore,
  required MatchStatus status,
  required String timeLabel,
  DateTime? date,
}) {
  const team = TeamModel(id: 1, name: 'A', shortName: 'A', logo: '');
  const comp = CompetitionModel(id: 1, name: 'League', region: 'X', logo: '');
  return MatchModel(
    id: id,
    fixtureId: id,
    homeTeam: team,
    awayTeam: team,
    homeScore: homeScore,
    awayScore: awayScore,
    status: status,
    timeLabel: timeLabel,
    competition: comp,
    date: date ?? DateTime.utc(2026, 6, 21, 18),
  );
}

void main() {
  group('LiveMatchOverlay preferNewer', () {
    test('never downgrades live 3-1 to stale 0-0', () {
      final route = _match(
        id: 100,
        homeScore: 3,
        awayScore: 1,
        status: MatchStatus.live,
        timeLabel: "67'",
      );
      final stale = _match(
        id: 100,
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.upcoming,
        timeLabel: '19:00',
      );

      final result = LiveMatchOverlay.preferNewer(route, stale);

      expect(result.homeScore, 3);
      expect(result.awayScore, 1);
      expect(result.status, MatchStatus.live);
      expect(result.timeLabel, "67'");
    });

    test('isDowngrade detects stale cache regression', () {
      final live = _match(
        id: 1,
        homeScore: 2,
        awayScore: 1,
        status: MatchStatus.live,
        timeLabel: "55'",
      );
      final stale = _match(
        id: 1,
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.upcoming,
        timeLabel: '22:00',
      );

      expect(LiveMatchOverlay.isDowngrade(stale, live), isTrue);
      expect(LiveMatchOverlay.isDowngrade(live, stale), isFalse);
    });
  });

  group('LiveMatchOverlay overlay parity', () {
    test('home competition list and live feed show identical score', () {
      final competition = _match(
        id: 200,
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.upcoming,
        timeLabel: '19:00',
      );
      final live = _match(
        id: 200,
        homeScore: 1,
        awayScore: 0,
        status: MatchStatus.live,
        timeLabel: "23'",
      );

      final homeToday = LiveMatchOverlay.overlay([competition], [live]);
      final wcHub = LiveMatchOverlay.overlay([competition], [live]);

      expect(homeToday.single.homeScore, live.homeScore);
      expect(homeToday.single.awayScore, live.awayScore);
      expect(wcHub.single.homeScore, homeToday.single.homeScore);
      expect(wcHub.single.awayScore, homeToday.single.awayScore);
      expect(wcHub.single.status, MatchStatus.live);
    });

    test('details header matches live list after preferNewer', () {
      final listRow = _match(
        id: 300,
        homeScore: 0,
        awayScore: 1,
        status: MatchStatus.live,
        timeLabel: "41'",
      );
      final staleDetail = _match(
        id: 300,
        homeScore: 0,
        awayScore: 0,
        status: MatchStatus.upcoming,
        timeLabel: '19:00',
      );

      final header = LiveMatchOverlay.preferNewer(listRow, staleDetail);

      expect(header.homeScore, listRow.homeScore);
      expect(header.awayScore, listRow.awayScore);
      expect(header.status, listRow.status);
    });
  });

  group('Kickoff time consistency', () {
    test('parser and formatter show same local kickoff', () {
      const raw = '2026-06-11T19:00:00+00:00';
      final parsed = ApiFootballParser.parseFixture({
        'fixture': {
          'id': 1,
          'date': raw,
          'status': {'short': 'NS'},
          'venue': {'name': 'Stadium'},
        },
        'league': {
          'id': 1,
          'name': 'WC',
          'country': 'World',
          'round': 'Group',
        },
        'teams': {
          'home': {'id': 10, 'name': 'France', 'logo': ''},
          'away': {'id': 11, 'name': 'Norway', 'logo': ''},
        },
        'goals': {'home': null, 'away': null},
        'score': {'fulltime': {'home': null, 'away': null}},
      });

      final cardTime = WorldCupMatchDateFormatter.formatKickoffTime(
        MatchDateTimeInput(date: parsed.date, timeLabel: parsed.timeLabel),
      );
      final local = ApiDateTime.toLocalKickoff(DateTime.parse(raw));
      final expected =
          '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

      expect(parsed.timeLabel, expected);
      expect(cardTime, expected);
    });
  });

  group('ApiCachePolicy competition fixtures TTL', () {
    test('uses live TTL when any fixture is live', () {
      final list = [
        _match(
          id: 1,
          homeScore: 1,
          awayScore: 0,
          status: MatchStatus.live,
          timeLabel: "10'",
        ),
      ];
      expect(
        ApiCachePolicy.competitionFixturesTtlFor(list),
        ApiCachePolicy.liveMatches,
      );
    });

    test('uses default competition TTL when no live fixtures', () {
      final list = [
        _match(
          id: 1,
          homeScore: 0,
          awayScore: 0,
          status: MatchStatus.upcoming,
          timeLabel: '22:00',
        ),
      ];
      expect(
        ApiCachePolicy.competitionFixturesTtlFor(list),
        ApiCachePolicy.competitionFixtures,
      );
    });
  });
}
