import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/match/featured_match_selector.dart';
import 'package:kickora/data/models/competition_model.dart';
import 'package:kickora/data/models/match_model.dart';
import 'package:kickora/data/models/team_model.dart';

CompetitionModel _comp(int id, String name) => CompetitionModel(
      id: id,
      name: name,
      region: '',
      logo: '',
    );

MatchModel _match({
  required int id,
  required int competitionId,
  required String competitionName,
  required MatchStatus status,
  required DateTime date,
  String home = 'Home',
  String away = 'Away',
  String logo = '',
  String stadium = '',
}) {
  return MatchModel(
    id: id,
    homeTeam: TeamModel(id: 1, name: home, shortName: 'H', logo: logo),
    awayTeam: TeamModel(id: 2, name: away, shortName: 'A', logo: logo),
    homeScore: 0,
    awayScore: 0,
    status: status,
    timeLabel: '20:00',
    competition: _comp(competitionId, competitionName),
    date: date,
    stadium: stadium,
  );
}

void main() {
  final now = DateTime(2026, 9, 19, 18);

  test('prefers a live major match over another live match', () {
    final majorLive = _match(
      id: 1,
      competitionId: 39,
      competitionName: 'Premier League',
      status: MatchStatus.live,
      date: now,
    );
    final otherLive = _match(
      id: 2,
      competitionId: 88,
      competitionName: 'Local Cup',
      status: MatchStatus.live,
      date: now,
    );
    expect(
      FeaturedMatchSelector.pick(
        liveMatches: [otherLive, majorLive],
        now: now,
      )?.id,
      1,
    );
  });

  test('falls back to any live match when no major live exists', () {
    final otherLive = _match(
      id: 2,
      competitionId: 88,
      competitionName: 'Local Cup',
      status: MatchStatus.live,
      date: now,
    );
    expect(
      FeaturedMatchSelector.pick(liveMatches: [otherLive], now: now)?.id,
      2,
    );
  });

  test('uses a major upcoming match within 48 hours', () {
    final upcomingMajor = _match(
      id: 3,
      competitionId: 140,
      competitionName: 'La Liga',
      status: MatchStatus.upcoming,
      date: now.add(const Duration(hours: 20)),
    );
    final obscureUpcoming = _match(
      id: 4,
      competitionId: 88,
      competitionName: 'Local Cup',
      status: MatchStatus.upcoming,
      date: now.add(const Duration(hours: 2)),
    );
    expect(
      FeaturedMatchSelector.pick(
        upcomingMatches: [obscureUpcoming, upcomingMajor],
        now: now,
      )?.id,
      3,
    );
  });

  test('ignores upcoming matches beyond 48 hours', () {
    final later = _match(
      id: 5,
      competitionId: 39,
      competitionName: 'Premier League',
      status: MatchStatus.upcoming,
      date: now.add(const Duration(hours: 60)),
    );
    expect(
      FeaturedMatchSelector.pick(upcomingMatches: [later], now: now),
      isNull,
    );
  });

  test('uses a recently finished major match before other finished matches', () {
    final majorFinished = _match(
      id: 6,
      competitionId: 2,
      competitionName: 'UEFA Champions League',
      status: MatchStatus.finished,
      date: now.subtract(const Duration(hours: 2)),
    );
    final otherFinished = _match(
      id: 7,
      competitionId: 88,
      competitionName: 'Local Cup',
      status: MatchStatus.finished,
      date: now.subtract(const Duration(minutes: 10)),
    );
    expect(
      FeaturedMatchSelector.pick(
        finishedMatches: [otherFinished, majorFinished],
        now: now,
      )?.id,
      6,
    );
  });

  test('handles missing league, logo and venue without crashing', () {
    final match = _match(
      id: 8,
      competitionId: 0,
      competitionName: '',
      status: MatchStatus.live,
      date: now,
      logo: '',
      stadium: '',
    );
    expect(
      FeaturedMatchSelector.pick(liveMatches: [match], now: now)?.id,
      8,
    );
  });

  test('skips matches that have no team names', () {
    final match = _match(
      id: 9,
      competitionId: 39,
      competitionName: 'Premier League',
      status: MatchStatus.live,
      date: now,
      home: '  ',
      away: '',
    );
    expect(
      FeaturedMatchSelector.pick(liveMatches: [match], now: now),
      isNull,
    );
  });

  test('does not fabricate a featured match from an empty list', () {
    expect(FeaturedMatchSelector.pick(), isNull);
  });
}
