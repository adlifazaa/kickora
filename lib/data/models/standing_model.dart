import 'team_model.dart';

class StandingModel {
  const StandingModel({
    required this.position,
    required this.team,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalDifference,
    required this.points,
  });

  final int position;
  final TeamModel team;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalDifference;
  final int points;

  factory StandingModel.fromJson(Map<String, dynamic> json) {
    final teamJson = json['team'] as Map<String, dynamic>? ?? {};
    return StandingModel(
      position: ((json['rank'] ?? json['position'] ?? 0) as num).toInt(),
      team: TeamModel.fromJson(teamJson),
      played: ((json['played'] ?? json['all']?['played'] ?? 0) as num).toInt(),
      wins: ((json['wins'] ?? json['all']?['win'] ?? 0) as num).toInt(),
      draws: ((json['draws'] ?? json['all']?['draw'] ?? 0) as num).toInt(),
      losses: ((json['losses'] ?? json['all']?['lose'] ?? 0) as num).toInt(),
      goalDifference:
          ((json['goalDifference'] ?? json['goalsDiff'] ?? 0) as num).toInt(),
      points: ((json['points'] ?? 0) as num).toInt(),
    );
  }
}
