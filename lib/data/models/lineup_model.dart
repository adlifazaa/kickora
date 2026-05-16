import '../../core/lineup/formation_lineup_layout.dart';
import 'formation_model.dart';
import 'player_model.dart';

class LineupModel {
  const LineupModel({
    required this.formation,
    required this.coach,
    required this.lines,
    required this.substitutes,
    this.injured = const [],
    this.missing = const [],
    this.formationDetail,
  });

  final String formation;
  final String coach;
  final List<List<PlayerModel>> lines;
  final List<PlayerModel> substitutes;
  final List<String> injured;
  final List<String> missing;
  final FormationModel? formationDetail;

  FormationModel get resolvedFormation =>
      formationDetail ?? FormationModel.fromName(formation);

  /// Rows normalized for pitch display (formation fallback when grid is weak).
  List<List<PlayerModel>> get pitchLines =>
      FormationLineupLayout.resolveLines(lines: lines, formation: formation);

  bool get hasPitchPlayers => pitchLines.isNotEmpty;

  LineupModel forPitchDisplay() {
    final resolved = pitchLines;
    if (_linesEqual(resolved, lines)) return this;
    return LineupModel(
      formation: formation,
      coach: coach,
      lines: resolved,
      substitutes: substitutes,
      injured: injured,
      missing: missing,
      formationDetail: formationDetail,
    );
  }

  bool _linesEqual(List<List<PlayerModel>> a, List<List<PlayerModel>> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].length != b[i].length) return false;
    }
    return true;
  }

  factory LineupModel.fromJson(Map<String, dynamic> json) {
    final formationName = (json['formation'] ?? '').toString();
    return LineupModel(
      formation: formationName,
      coach: (json['coach'] ?? '').toString(),
      lines: const [],
      substitutes: const [],
      formationDetail: json['formationDetail'] is Map<String, dynamic>
          ? FormationModel.fromJson(
              json['formationDetail'] as Map<String, dynamic>,
            )
          : FormationModel.fromName(formationName),
    );
  }
}
