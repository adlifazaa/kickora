import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/data/models/competition_model.dart';
import 'package:kickora/data/models/match_model.dart';
import 'package:kickora/data/models/team_model.dart';
import 'package:kickora/utils/match_share_formatter.dart';

TeamModel _team(String name) => TeamModel(id: 1, name: name, shortName: 'T');

MatchModel _match({
  MatchStatus status = MatchStatus.upcoming,
  int homeScore = 0,
  int awayScore = 0,
  String timeLabel = '20:00',
  String stadium = '',
  String competitionName = 'FIFA World Cup',
  DateTime? date,
}) {
  return MatchModel(
    id: 1,
    homeTeam: _team('Saudi Arabia'),
    awayTeam: _team('Argentina'),
    homeScore: homeScore,
    awayScore: awayScore,
    status: status,
    timeLabel: timeLabel,
    competition: CompetitionModel(
      id: 1,
      name: competitionName,
      region: 'World',
      logo: '',
    ),
    date: date ?? DateTime(2026, 6, 15, 21, 0),
    stadium: stadium,
  );
}

void main() {
  test('upcoming match uses Arabic schedule line with kickoff time', () {
    final text = buildMatchShareText(_match());
    expect(text, contains('⚽'));
    expect(text, contains('Saudi Arabia'));
    expect(text, contains('ضد'));
    expect(text, contains('Argentina'));
    expect(text, contains('🕐 الموعد:'));
    expect(text, contains('15/06/2026'));
    expect(text, contains('20:00'));
    expect(text, contains('🏆 البطولة:'));
    expect(text, contains('FIFA World Cup'));
    expect(text, contains(matchShareFooter));
    expect(text, isNot(contains('0-0')));
  });

  test('live match uses compact score headline', () {
    final text = buildMatchShareText(_match(
      status: MatchStatus.live,
      homeScore: 2,
      awayScore: 1,
      timeLabel: "67'",
    ));
    expect(text, contains('⚽'));
    expect(text, contains('2-1'));
    expect(text, isNot(contains('2 - 1')));
  });

  test('finished match uses final score', () {
    final text = buildMatchShareText(_match(
      status: MatchStatus.finished,
      homeScore: 3,
      awayScore: 2,
      timeLabel: 'FT',
    ));
    expect(text, contains('3-2'));
  });

  test('omits optional lines when data is missing', () {
    final text = buildMatchShareText(_match(
      competitionName: '',
      stadium: '',
      timeLabel: '',
      date: DateTime(1999),
    ));
    expect(text, isNot(contains('🏆')));
    expect(text, isNot(contains('📅')));
    expect(text, isNot(contains('📍')));
    expect(text, isNot(contains('🕐')));
  });

  test('includes venue with Arabic label when available', () {
    final text = buildMatchShareText(_match(stadium: 'Lusail Stadium'));
    expect(text, contains('📍 الملعب:'));
    expect(text, contains('Lusail Stadium'));
  });

  test('footer mentions matches and competitions', () {
    expect(
      matchShareFooter,
      'تابع نتائج المباريات والبطولات عبر Kickora | كأس العالم 2026',
    );
  });

  test('includes shortened Play Store download link', () {
    final text = buildMatchShareText(_match());
    expect(text, contains(matchShareDownloadLine));
    expect(text, contains(matchSharePlayStoreUrl));
    expect(
      matchSharePlayStoreUrl,
      'play.google.com/store/apps/details?id=com.kickora.worldcup',
    );
  });
}
