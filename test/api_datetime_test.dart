import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/data/services/api_football_parser.dart';
import 'package:kickora/utils/api_datetime.dart';

void main() {
  group('ApiDateTime', () {
    test('parseKickoffLocal converts UTC ISO to device local', () {
      const raw = '2026-06-11T17:00:00+00:00';
      final parsed = ApiDateTime.parseKickoffLocal(raw);
      final expected = DateTime.parse(raw).toLocal();

      expect(parsed, isNotNull);
      expect(parsed!.isUtc, isFalse);
      expect(parsed, expected);
      expect(ApiDateTime.formatClock(parsed), ApiDateTime.formatClock(expected));
    });

    test('parseKickoffLocal does not double-convert local cache values', () {
      final local = DateTime(2026, 6, 12, 2, 0);
      final raw = local.toIso8601String();
      final parsed = ApiDateTime.parseKickoffLocal(raw);

      expect(parsed, local);
      expect(ApiDateTime.formatClock(parsed!), '02:00');
    });

    test('midnight rollover: 23:00 UTC becomes next local day', () {
      const raw = '2026-06-11T23:00:00+00:00';
      final parsed = ApiDateTime.parseKickoffLocal(raw)!;
      final expected = DateTime.parse(raw).toLocal();

      expect(parsed.day, expected.day);
      expect(parsed.hour, expected.hour);
      expect(parsed.minute, expected.minute);
    });

    test('parseApiKickoff falls back when raw is invalid', () {
      final fallback = DateTime(2026, 6, 15, 12);
      expect(
        ApiDateTime.parseApiKickoff(null, fallback: fallback),
        fallback,
      );
      expect(
        ApiDateTime.parseApiKickoff('not-a-date', fallback: fallback),
        fallback,
      );
    });

    test('isSameLocalDay compares device-local calendar days', () {
      final utcLate = DateTime.utc(2026, 6, 11, 23, 0);
      final localLate = utcLate.toLocal();
      expect(ApiDateTime.isSameLocalDay(utcLate, localLate), isTrue);
      expect(
        ApiDateTime.isSameLocalDay(utcLate, localLate.add(const Duration(days: 1))),
        isFalse,
      );
    });

    test('localDateKey uses local calendar day', () {
      final utc = DateTime.utc(2026, 6, 11, 23, 0);
      final local = utc.toLocal();
      expect(
        ApiDateTime.localDateKey(utc),
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}',
      );
    });
  });

  group('ApiFootballParser kickoff timezone', () {
    Map<String, dynamic> fixtureJson(String date) => {
          'fixture': {
            'id': 1,
            'date': date,
            'status': {'short': 'NS', 'elapsed': null},
            'venue': {'name': 'Stadium'},
          },
          'league': {
            'id': 1,
            'name': 'World Cup',
            'country': 'FIFA',
          },
          'teams': {
            'home': {'id': 1, 'name': 'Portugal'},
            'away': {'id': 2, 'name': 'DR Congo'},
          },
          'goals': {'home': null, 'away': null},
          'score': {
            'fulltime': {'home': null, 'away': null},
          },
        };

    test('timeLabel uses local kickoff, not UTC', () {
      const raw = '2026-06-11T17:00:00+00:00';
      final match = ApiFootballParser.parseFixture(fixtureJson(raw));
      final expected = ApiDateTime.formatClock(DateTime.parse(raw));

      expect(match.timeLabel, expected);
      expect(match.date, DateTime.parse(raw).toLocal());
    });

    test('production examples match local offset from UTC', () {
      final cases = <String, String>{
        '2026-06-11T17:00:00+00:00': 'Portugal vs DR Congo',
        '2026-06-12T20:00:00+00:00': 'England vs Croatia',
        '2026-06-12T23:00:00+00:00': 'Ghana vs Panama',
      };

      for (final entry in cases.entries) {
        final match = ApiFootballParser.parseFixture(fixtureJson(entry.key));
        final local = DateTime.parse(entry.key).toLocal();
        expect(
          match.timeLabel,
          '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}',
          reason: entry.value,
        );
      }
    });
  });
}
