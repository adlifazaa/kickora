import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/world_cup/world_cup_hub_features.dart';
import 'package:kickora/core/world_cup/world_cup_hub_loader.dart';
import 'package:kickora/data/models/competition_model.dart';
import 'package:kickora/data/models/match_model.dart';
import 'package:kickora/data/models/news_article_model.dart';
import 'package:kickora/data/models/player_model.dart';
import 'package:kickora/data/models/team_model.dart';
import 'package:kickora/data/models/standing_group_model.dart';
import 'package:kickora/data/models/standing_model.dart';
import 'package:kickora/data/repositories/football_repository.dart';
import 'package:kickora/data/providers/mock_football_data_provider.dart';
import 'package:kickora/utils/match_share_formatter.dart';

CompetitionModel _comp() => CompetitionModel(
      id: 1,
      name: 'World Cup',
      region: 'World',
      logo: '',
    );

TeamModel _team(int id, String name, {String country = '', String code = ''}) {
  return TeamModel(
    id: id,
    name: name,
    shortName: name.substring(0, 3).toUpperCase(),
    countryName: country,
    countryCode: code,
  );
}

MatchModel _match({
  required int id,
  required TeamModel home,
  required TeamModel away,
  MatchStatus status = MatchStatus.upcoming,
  String stadium = 'MetLife Stadium',
}) {
  return MatchModel(
    id: id,
    homeTeam: home,
    awayTeam: away,
    homeScore: status == MatchStatus.upcoming ? 0 : 2,
    awayScore: status == MatchStatus.upcoming ? 0 : 1,
    status: status,
    timeLabel: '18:00',
    competition: _comp(),
    date: DateTime(2026, 6, 15),
    stadium: stadium,
    round: 'Group Stage - 1',
  );
}

WorldCupHubLoader _loaderWithData() {
  final loader = WorldCupHubLoader(
    FootballRepository(dataProvider: MockFootballDataProvider()),
  );
  final saudi = _team(1, 'Saudi Arabia', country: 'Saudi Arabia', code: 'SA');
  final arg = _team(2, 'Argentina', country: 'Argentina', code: 'AR');
  final morocco = _team(3, 'Morocco', country: 'Morocco', code: 'MA');
  loader.matches = [
    _match(id: 10, home: saudi, away: arg),
    _match(id: 11, home: morocco, away: arg, status: MatchStatus.finished),
  ];
  loader.groups = [
    StandingGroupModel(
      name: 'Group A',
      rows: [
        StandingModel(
          position: 1,
          team: saudi,
          played: 1,
          wins: 1,
          draws: 0,
          losses: 0,
          goalDifference: 1,
          points: 3,
        ),
        StandingModel(
          position: 2,
          team: morocco,
          played: 1,
          wins: 0,
          draws: 0,
          losses: 1,
          goalDifference: -1,
          points: 0,
        ),
      ],
    ),
  ];
  loader.teams = [saudi, arg, morocco];
  loader.scorers = [
    PlayerModel(
      id: 100,
      name: 'Salah',
      shortName: 'SAL',
      number: 10,
      nationality: 'Egypt',
      age: 30,
      height: 175,
      position: 'Forward',
      team: 'Egypt',
      appearances: 3,
      goals: 2,
      assists: 1,
      yellowCards: 0,
      redCards: 0,
    ),
  ];
  return loader;
}

void main() {
  test('WorldCupHubSearch finds teams, matches, stadiums, players', () {
    final loader = _loaderWithData();
    final results = WorldCupHubSearch.search(loader, 'saudi');
    expect(results.any((r) => r.kind == WorldCupSearchKind.team), isTrue);
    expect(results.any((r) => r.kind == WorldCupSearchKind.match), isTrue);

    final stadiumResults = WorldCupHubSearch.search(loader, 'metlife');
    expect(stadiumResults.any((r) => r.kind == WorldCupSearchKind.stadium),
        isTrue);

    final playerResults = WorldCupHubSearch.search(loader, 'salah');
    expect(playerResults.any((r) => r.kind == WorldCupSearchKind.player),
        isTrue);
  });

  test('WorldCupArabTeams only includes Arab teams present in data', () {
    final loader = _loaderWithData();
    final arab = WorldCupArabTeams.fromLoader(loader);
    expect(arab.length, 2);
    expect(arab.any((t) => t.name.contains('Saudi')), isTrue);
    expect(arab.any((t) => t.name.contains('Morocco')), isTrue);
    expect(arab.any((t) => t.name.contains('Argentina')), isFalse);
  });

  test('NewsArticleModel parses backend article payload', () {
    final article = NewsArticleModel.fromJson({
      'id': 'abc',
      'title': 'World Cup headline',
      'summary': 'Short summary',
      'source': 'BBC Sport',
      'imageUrl': 'https://example.com/img.jpg',
      'url': 'https://example.com/article',
      'publishedAt': '2026-06-11T12:00:00Z',
    });
    expect(article.title, 'World Cup headline');
    expect(article.source, 'BBC Sport');
    expect(article.publishedAt?.year, 2026);
  });

  test('WorldCupNewsResult notConfigured has empty articles', () {
    expect(WorldCupNewsResult.notConfigured.configured, isFalse);
    expect(WorldCupNewsResult.notConfigured.articles, isEmpty);
  });

  test('match share text includes Play Store link only once', () {
    final text = buildMatchShareText(_match(
      id: 1,
      home: _team(1, 'Saudi Arabia'),
      away: _team(2, 'Argentina'),
    ));
    expect(
      matchSharePlayStoreUrl.allMatches(text).length,
      1,
    );
  });
}
