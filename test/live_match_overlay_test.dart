import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/data/models/competition_model.dart';
import 'package:kickora/data/models/match_model.dart';
import 'package:kickora/data/models/team_model.dart';
import 'package:kickora/utils/live_match_overlay.dart';

MatchModel _match({
  required int id,
  required int homeScore,
  required int awayScore,
  required MatchStatus status,
  required String timeLabel,
}) {
  const team = TeamModel(id: 1, name: 'A', shortName: 'A', logo: '');
  const comp = CompetitionModel(id: 1, name: 'League', region: 'X', logo: '');
  return MatchModel(
    id: id,
    homeTeam: team,
    awayTeam: team,
    homeScore: homeScore,
    awayScore: awayScore,
    status: status,
    timeLabel: timeLabel,
    competition: comp,
    date: DateTime.utc(2026, 6, 21, 18),
  );
}

void main() {
  test('overlay replaces stale scores from live snapshot', () {
    final stale = _match(
      id: 100,
      homeScore: 0,
      awayScore: 0,
      status: MatchStatus.upcoming,
      timeLabel: '18:00',
    );
    final live = _match(
      id: 100,
      homeScore: 2,
      awayScore: 1,
      status: MatchStatus.live,
      timeLabel: "67'",
    );

    final merged = LiveMatchOverlay.overlay([stale], [live]);

    expect(merged.single.homeScore, 2);
    expect(merged.single.awayScore, 1);
    expect(merged.single.status, MatchStatus.live);
    expect(merged.single.timeLabel, "67'");
  });

  test('overlay leaves unrelated fixtures unchanged', () {
    final other = _match(
      id: 200,
      homeScore: 1,
      awayScore: 0,
      status: MatchStatus.finished,
      timeLabel: 'FT',
    );
    final live = _match(
      id: 100,
      homeScore: 1,
      awayScore: 1,
      status: MatchStatus.live,
      timeLabel: "55'",
    );

    final merged = LiveMatchOverlay.overlay([other], [live]);

    expect(merged.single.id, 200);
    expect(merged.single.homeScore, 1);
    expect(merged.single.status, MatchStatus.finished);
  });
}
