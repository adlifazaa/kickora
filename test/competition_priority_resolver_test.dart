import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/competition/competition_name_normalizer.dart';
import 'package:kickora/core/competition/competition_priority_resolver.dart';
import 'package:kickora/core/competition/popular_competition_catalog.dart';
import 'package:kickora/data/models/competition_model.dart';
import 'package:kickora/data/models/match_model.dart';
import 'package:kickora/data/models/team_model.dart';

CompetitionModel _comp(int id, String name, {int matchesToday = 0}) =>
    CompetitionModel(
      id: id,
      name: name,
      region: 'World',
      logo: '',
      matchesToday: matchesToday,
    );

MatchModel _match({
  required int id,
  required CompetitionModel competition,
  required MatchStatus status,
  required DateTime date,
}) {
  return MatchModel(
    id: id,
    homeTeam: const TeamModel(id: 1, name: 'Home', shortName: 'H', logo: ''),
    awayTeam: const TeamModel(id: 2, name: 'Away', shortName: 'A', logo: ''),
    homeScore: 0,
    awayScore: 0,
    status: status,
    timeLabel: '18:00',
    competition: competition,
    date: date,
  );
}

void main() {
  test('normalizes Arabic diacritics and punctuation', () {
    expect(
      CompetitionNameNormalizer.normalize('دوري أبطال أوروبا!'),
      CompetitionNameNormalizer.normalize('دوري ابطال اوروبا'),
    );
    expect(
      CompetitionNameNormalizer.normalize('UEFA Champions League'),
      'uefa champions league',
    );
  });

  test('matches verified provider ids and aliases', () {
    expect(
      PopularCompetitionCatalog.matchCompetition(
        _comp(2, 'UEFA Champions League'),
      )?.rank,
      1,
    );
    expect(
      PopularCompetitionCatalog.matchCompetition(
        _comp(39, 'Premier League'),
      )?.rank,
      2,
    );
    expect(
      PopularCompetitionCatalog.matchNameAndId(
        name: 'الدوري الإنجليزي الممتاز',
        id: 99,
      )?.key,
      'premier_league',
    );
    expect(
      PopularCompetitionCatalog.matchNameAndId(
        name: 'Serie A',
        id: 0,
      )?.rank,
      5,
    );
  });

  test('name aliases win over colliding mock ids', () {
    final mockPremier = PopularCompetitionCatalog.matchCompetition(
      _comp(2, 'Premier League'),
    );
    expect(mockPremier?.key, 'premier_league');
  });

  test('ranks live popular competitions first and caps top module at 5', () {
    final now = DateTime(2026, 9, 19, 18);
    final ucl = _comp(2, 'UEFA Champions League');
    final pl = _comp(39, 'Premier League');
    final liga = _comp(140, 'La Liga');
    final serie = _comp(4, 'Serie A');
    final bund = _comp(5, 'Bundesliga');
    final ligue = _comp(8, 'Ligue 1');
    final worldCup = _comp(1, 'World Cup');
    final obscure = _comp(88, 'Local Cup');

    final top = CompetitionPriorityResolver.topCompetitions(
      competitions: [worldCup, obscure, ligue, bund, serie, liga, pl, ucl],
      liveMatches: [
        _match(
          id: 10,
          competition: pl,
          status: MatchStatus.live,
          date: now,
        ),
      ],
      todayMatches: [
        _match(
          id: 11,
          competition: liga,
          status: MatchStatus.upcoming,
          date: now.add(const Duration(hours: 2)),
        ),
      ],
      upcomingMatches: [
        _match(
          id: 12,
          competition: ucl,
          status: MatchStatus.upcoming,
          date: now.add(const Duration(days: 2)),
        ),
      ],
      now: now,
    );

    expect(top.length, 5);
    expect(top.first.id, 39);
    expect(top.map((c) => c.id), isNot(contains(1)));
    expect(top.map((c) => c.id), isNot(contains(88)));
  });

  test('boosts competitions with upcoming matches in the next 7 days', () {
    final now = DateTime(2026, 9, 19, 12);
    final europa = _comp(3, 'UEFA Europa League');
    final pl = _comp(39, 'Premier League');
    final ranked = CompetitionPriorityResolver.topCompetitions(
      competitions: [pl, europa],
      upcomingMatches: [
        _match(
          id: 1,
          competition: europa,
          status: MatchStatus.upcoming,
          date: now.add(const Duration(days: 3)),
        ),
      ],
      now: now,
    );
    expect(ranked.first.id, europa.id);
  });

  test('deduplicates translated names', () {
    final ranked = CompetitionPriorityResolver.topCompetitions(
      competitions: [
        _comp(39, 'Premier League'),
        _comp(390, 'الدوري الإنجليزي'),
      ],
    );
    expect(ranked.length, 1);
  });

  test('empty API competitions yield an empty top module', () {
    expect(
      CompetitionPriorityResolver.topCompetitions(competitions: const []),
      isEmpty,
    );
  });

  test('World Cup is not permanently pinned on the competitions screen', () {
    final ranked = CompetitionPriorityResolver.rankForCompetitionsScreen(
      competitions: [
        _comp(1, 'World Cup'),
        _comp(39, 'Premier League'),
        _comp(140, 'La Liga'),
      ],
    );
    expect(ranked.first.id, isNot(1));
    expect(ranked.first.id, 39);
    expect(ranked.last.id, 1);
  });
}
