import 'competition_model.dart';
import 'lineup_model.dart';
import 'standing_model.dart';
import 'team_model.dart';

enum MatchStatus { live, upcoming, finished }

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

MatchStatus parseMatchStatus(String raw) {
  switch (raw.toLowerCase()) {
    case 'live':
    case 'in_play':
    case 'inplay':
    case '1h':
    case '2h':
    case 'ht':
      return MatchStatus.live;
    case 'finished':
    case 'ft':
    case 'aet':
    case 'pen':
      return MatchStatus.finished;
    default:
      return MatchStatus.upcoming;
  }
}

class MatchEvent {
  const MatchEvent({
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
}

class MatchStat {
  const MatchStat({
    required this.title,
    required this.home,
    required this.away,
    required this.homeValue,
    required this.awayValue,
  });

  final String title;
  final double home;
  final double away;
  final String homeValue;
  final String awayValue;
}

class MatchModel {
  const MatchModel({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    required this.timeLabel,
    required this.competition,
    required this.date,
    this.stadium = '',
    this.events = const [],
    this.stats = const [],
    this.homeLineup,
    this.awayLineup,
    this.standings = const [],

    /// 0–1 momentum leaning toward home (0.5 = even).
    this.momentumHome = 0.52,
    this.liveCommentary = const [],
  });

  final int id;
  final TeamModel homeTeam;
  final TeamModel awayTeam;
  final int homeScore;
  final int awayScore;
  final MatchStatus status;
  final String timeLabel;
  final CompetitionModel competition;
  final DateTime date;
  final String stadium;
  final List<MatchEvent> events;
  final List<MatchStat> stats;
  final LineupModel? homeLineup;
  final LineupModel? awayLineup;
  final List<StandingModel> standings;
  final double momentumHome;
  final List<String> liveCommentary;

  /// Skeleton parser to make wiring up the real API less work later.
  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final homeTeam =
        TeamModel.fromJson(json['homeTeam'] as Map<String, dynamic>? ?? {});
    final awayTeam =
        TeamModel.fromJson(json['awayTeam'] as Map<String, dynamic>? ?? {});
    final competition = CompetitionModel.fromJson(
        json['competition'] as Map<String, dynamic>? ?? {});
    return MatchModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeScore: (json['homeScore'] ?? 0) as int,
      awayScore: (json['awayScore'] ?? 0) as int,
      status: parseMatchStatus(json['status']?.toString() ?? ''),
      timeLabel: (json['timeLabel'] ?? '').toString(),
      competition: competition,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      stadium: (json['stadium'] ?? '').toString(),
      momentumHome: ((json['momentumHome'] ?? 0.5) as num).toDouble(),
    );
  }
}
