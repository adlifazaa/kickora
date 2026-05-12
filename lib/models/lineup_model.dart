import 'player_model.dart';

class LineupModel {
  const LineupModel({
    required this.formation,
    required this.coach,
    required this.lines,
    required this.substitutes,
    this.injured = const [],
    this.missing = const [],
  });

  final String formation;
  final String coach;
  final List<List<PlayerModel>> lines;
  final List<PlayerModel> substitutes;
  final List<String> injured;
  final List<String> missing;
}
