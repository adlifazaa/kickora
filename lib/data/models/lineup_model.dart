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
