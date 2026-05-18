import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/display/player_profile_display.dart';
import 'package:kickora/data/models/player_model.dart';

void main() {
  test('missing or zero profile stats render as dash', () {
    const player = PlayerModel(
      id: 1,
      name: 'Test',
      shortName: 'TST',
      number: 0,
      nationality: '',
      age: 0,
      height: 0,
      weight: 0,
      position: '',
      team: '',
      appearances: 0,
      minutesPlayed: 0,
      goals: 0,
      assists: 0,
      yellowCards: 0,
      redCards: 0,
    );

    expect(player.displayAge(), '—');
    expect(player.displayHeight(), '—');
    expect(player.displayWeight(), '—');
    expect(player.displayAppearances(), '—');
    expect(player.displayMinutes(), '—');
    expect(player.displayShirtNumber(), '—');
    expect(player.displayGoals(), '0');
    expect(player.displayAssists(), '0');
    expect(player.displayYellowCards(), '0');
    expect(player.displayNationality(), 'Unknown');
    expect(player.displayTeam(), 'Unknown');
  });

  test('valid mock-like profile stats still render numbers', () {
    const player = PlayerModel(
      id: 10,
      name: 'Messi',
      shortName: 'MES',
      number: 10,
      nationality: 'Argentina',
      age: 39,
      height: 170,
      weight: 72,
      position: 'RW',
      team: 'Argentina',
      appearances: 24,
      minutesPlayed: 2011,
      goals: 12,
      assists: 11,
      yellowCards: 2,
      redCards: 0,
    );

    expect(player.displayAge(), contains('39'));
    expect(player.displayHeight(), '170 cm');
    expect(player.displayAppearances(), '24');
    expect(player.displayMinutes(), '2011');
    expect(player.displayRedCards(), '0');
  });
}
