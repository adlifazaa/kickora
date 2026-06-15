import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/world_cup/world_cup_round_classifier.dart';
import 'package:kickora/core/world_cup/world_cup_schedule_view.dart';
import 'package:kickora/core/world_cup/world_cup_stadiums.dart';
import 'package:kickora/data/models/competition_model.dart';
import 'package:kickora/data/models/match_model.dart';
import 'package:kickora/data/models/team_model.dart';
import 'package:kickora/utils/world_cup_match_date_formatter.dart';
import 'package:kickora/widgets/world_cup_match_card.dart';
import 'package:kickora/widgets/world_cup_stadium_thumb.dart';

CompetitionModel _comp() => CompetitionModel(
      id: 1,
      name: 'World Cup',
      region: 'World',
      logo: '',
    );

MatchModel _match({
  required int id,
  required DateTime date,
  MatchStatus status = MatchStatus.upcoming,
  String round = 'Group Stage - 1',
  int homeScore = 0,
  int awayScore = 0,
}) {
  return MatchModel(
    id: id,
    homeTeam: TeamModel(id: 10 + id, name: 'Home $id', shortName: 'H'),
    awayTeam: TeamModel(id: 20 + id, name: 'Away $id', shortName: 'A'),
    homeScore: homeScore,
    awayScore: awayScore,
    status: status,
    timeLabel: '18:00',
    competition: _comp(),
    date: date,
    stadium: 'MetLife Stadium',
    round: round,
  );
}

void main() {
  test('English group headers use readable full words', () {
    final headers = WorldCupGroupTableLabels.headers(isArabic: false);
    expect(headers, contains('Played'));
    expect(headers, contains('Won'));
    expect(headers, contains('Drawn'));
    expect(headers, contains('Lost'));
    expect(headers, contains('GD'));
    expect(headers, contains('Points'));
    expect(headers, isNot(contains('P')));
  });

  test('WorldCupScheduleView groups matches chronologically by date', () {
    final d1 = DateTime(2026, 6, 11, 20);
    final d2 = DateTime(2026, 6, 12, 18);
    final matches = [
      _match(id: 2, date: d2),
      _match(id: 1, date: d1),
    ];
    final groups = WorldCupScheduleView.groupByDate(matches);
    expect(groups.length, 2);
    expect(groups.first.date.day, 11);
    expect(groups.last.date.day, 12);
    expect(groups.first.matches.first.id, 1);
  });

  test('WorldCupScheduleView filter live and group stage', () {
    final matches = [
      _match(id: 1, date: DateTime(2026, 6, 11), status: MatchStatus.live),
      _match(
        id: 2,
        date: DateTime(2026, 7, 5),
        status: MatchStatus.upcoming,
        round: 'Round of 16',
      ),
      _match(id: 3, date: DateTime(2026, 6, 13), round: 'Group Stage - 2'),
    ];
    final live = WorldCupScheduleView.filterMatches(
      matches,
      WorldCupScheduleFilter.live,
    );
    expect(live.length, 1);
    expect(live.first.status, MatchStatus.live);

    final groups = WorldCupScheduleView.filterMatches(
      matches,
      WorldCupScheduleFilter.groupStage,
    );
    expect(groups.length, 2);
    expect(groups.map((m) => m.id), containsAll([1, 3]));
  });

  test('group stage filter matches Regular Season and empty round in window', () {
    final matches = [
      _match(
        id: 1,
        date: DateTime(2026, 6, 15),
        round: 'Regular Season - 1',
      ),
      _match(id: 2, date: DateTime(2026, 6, 16), round: ''),
      _match(
        id: 3,
        date: DateTime(2026, 7, 4),
        round: 'Round of 16',
      ),
    ];
    final filtered = WorldCupScheduleView.filterMatches(
      matches,
      WorldCupScheduleFilter.groupStage,
    );
    expect(filtered.length, 2);
    expect(filtered.map((m) => m.id), containsAll([1, 2]));
  });

  test('WorldCupRoundClassifier recognizes API Group Stage round strings', () {
    expect(
      WorldCupRoundClassifier.isGroupStageRound('Group Stage - 1'),
      isTrue,
    );
    expect(
      WorldCupRoundClassifier.isGroupStageRound('Group Stage - 3'),
      isTrue,
    );
    expect(
      WorldCupRoundClassifier.isGroupStageRound('Regular Season - 2'),
      isTrue,
    );
    expect(
      WorldCupRoundClassifier.isGroupStageRound('Round of 16'),
      isFalse,
    );
  });

  test('formatMatchDate supports Arabic and English', () {
    final date = DateTime(2026, 6, 13, 20);
    final ar = WorldCupMatchDateFormatter.formatMatchDate(date, isArabic: true);
    final en = WorldCupMatchDateFormatter.formatMatchDate(date, isArabic: false);
    expect(ar, contains('13'));
    expect(ar, contains('يونيو'));
    expect(en, contains('Jun'));
    expect(en, contains('13'));
  });

  test('stadium uses premium fallback when no verified bundled photo', () {
    const stadium = WorldCupStadium(
      id: 'metlife',
      name: 'MetLife Stadium',
      city: 'East Rutherford',
      country: 'USA',
      capacity: 82500,
    );
    expect(stadium.assetPath, isNull);
    expect(stadium.hasVerifiedBundledPhoto, isFalse);
    expect(worldCupStadiumAssetExists(stadium), isFalse);
  });

  testWidgets('WorldCupMatchCard includes date label in widget tree', (tester) async {
    final match = _match(id: 1, date: DateTime(2026, 6, 13, 20));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorldCupMatchCard(
            match: match,
            isArabic: false,
          ),
        ),
      ),
    );
    expect(find.textContaining('Jun'), findsOneWidget);
    expect(find.text('Home 1'), findsOneWidget);
    expect(find.text('Away 1'), findsOneWidget);
  });
}
