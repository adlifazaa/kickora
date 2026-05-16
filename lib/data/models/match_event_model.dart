/// Scalable event types matched against most football data providers.
enum MatchEventType {
  goal,
  ownGoal,
  penalty,
  yellowCard,
  redCard,
  substitution,
  varDecision,
}

class MatchEventModel {
  const MatchEventModel({
    required this.minute,
    required this.type,
    required this.playerName,
    this.assistName,
    this.description = '',
    required this.isHome,
  });

  final String minute;
  final MatchEventType type;
  final String playerName;
  final String? assistName;
  final String description;
  final bool isHome;

  factory MatchEventModel.fromJson(Map<String, dynamic> json) {
    return MatchEventModel(
      minute: (json['minute'] ?? json['time'] ?? '').toString(),
      type: _parseType(json['type']?.toString() ?? ''),
      playerName: (json['playerName'] ?? json['player'] ?? '').toString(),
      assistName: json['assistName']?.toString(),
      description: (json['detail'] ?? json['description'] ?? '').toString(),
      isHome: json['isHome'] as bool? ?? json['team']?.toString() == 'home',
    );
  }

  static MatchEventType _parseType(String raw) {
    switch (raw.toLowerCase()) {
      case 'goal':
        return MatchEventType.goal;
      case 'owngoal':
      case 'own_goal':
        return MatchEventType.ownGoal;
      case 'penalty':
        return MatchEventType.penalty;
      case 'yellowcard':
      case 'yellow_card':
        return MatchEventType.yellowCard;
      case 'redcard':
      case 'red_card':
        return MatchEventType.redCard;
      case 'subst':
      case 'substitution':
        return MatchEventType.substitution;
      case 'var':
        return MatchEventType.varDecision;
      default:
        return MatchEventType.goal;
    }
  }
}

/// Backward-compatible alias used across the UI.
typedef MatchEvent = MatchEventModel;
