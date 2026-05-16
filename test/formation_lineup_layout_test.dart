import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/lineup/formation_lineup_layout.dart';
import 'package:kickora/data/models/player_model.dart';

void main() {
  group('FormationLineupLayout', () {
    test('resplits single-row XI by formation', () {
      final players = List.generate(
        11,
        (i) => PlayerModel(
          id: i,
          name: 'Player $i',
          shortName: 'P$i',
          number: i,
          nationality: '',
          age: 0,
          height: 0,
          position: 'MF',
          team: '',
          appearances: 0,
          goals: 0,
          assists: 0,
          yellowCards: 0,
          redCards: 0,
        ),
      );

      final resolved = FormationLineupLayout.resolveLines(
        lines: [players],
        formation: '4-3-3',
      );

      expect(resolved.length, greaterThanOrEqualTo(3));
      expect(
        resolved.fold<int>(0, (sum, row) => sum + row.length),
        11,
      );
    });
  });
}
