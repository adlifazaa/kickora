import '../mock_data.dart';
import 'competition_model.dart';
import 'lineup_model.dart';
import 'match_event_model.dart';
import 'match_statistic_model.dart';
import 'standing_model.dart';
import 'team_model.dart';

export 'match_event_model.dart';
export 'match_statistic_model.dart';

enum MatchStatus { live, upcoming, finished }

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

class MatchModel {
  const MatchModel({
    required this.id,
    this.fixtureId,
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
    this.momentumHome = 0.52,
    this.liveCommentary = const [],
  });

  final int id;

  /// API-Football fixture id. Null for demo/mock-only matches.
  final int? fixtureId;

  /// Id used for `/fixtures?id=` and related endpoints.
  int get resolvedFixtureId => (fixtureId != null && fixtureId! > 0)
      ? fixtureId!
      : id;

  /// True when this row should load remote fixture detail (not demo fallback).
  bool get isApiFixture =>
      resolvedFixtureId > 0 && !MockData.isMockMatchId(resolvedFixtureId);

  final TeamModel homeTeam;
  final TeamModel awayTeam;
  final int homeScore;
  final int awayScore;
  final MatchStatus status;
  final String timeLabel;
  final CompetitionModel competition;
  final DateTime date;
  final String stadium;
  final List<MatchEventModel> events;
  final List<MatchStatisticModel> stats;
  final LineupModel? homeLineup;
  final LineupModel? awayLineup;
  final List<StandingModel> standings;
  final double momentumHome;
  final List<String> liveCommentary;

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final homeTeam =
        TeamModel.fromJson(json['homeTeam'] as Map<String, dynamic>? ?? {});
    final awayTeam =
        TeamModel.fromJson(json['awayTeam'] as Map<String, dynamic>? ?? {});
    final competition = CompetitionModel.fromJson(
      json['competition'] as Map<String, dynamic>? ?? {},
    );
    final eventsJson = json['events'] as List? ?? const [];
    final statsJson = json['stats'] as List? ?? const [];

    final id = (json['id'] as num?)?.toInt() ?? 0;
    final fixtureRaw = json['fixtureId'];
    final fixtureId = fixtureRaw == null
        ? null
        : (fixtureRaw as num).toInt();

    return MatchModel(
      id: id,
      fixtureId: fixtureId,
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
      events: eventsJson
          .map((e) => MatchEventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      stats: statsJson
          .map((e) => MatchStatisticModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  MatchModel copyWith({
    int? id,
    int? fixtureId,
    TeamModel? homeTeam,
    TeamModel? awayTeam,
    int? homeScore,
    int? awayScore,
    MatchStatus? status,
    String? timeLabel,
    CompetitionModel? competition,
    DateTime? date,
    String? stadium,
    List<MatchEventModel>? events,
    List<MatchStatisticModel>? stats,
    LineupModel? homeLineup,
    LineupModel? awayLineup,
    List<StandingModel>? standings,
    double? momentumHome,
    List<String>? liveCommentary,
  }) {
    return MatchModel(
      id: id ?? this.id,
      fixtureId: fixtureId ?? this.fixtureId,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      status: status ?? this.status,
      timeLabel: timeLabel ?? this.timeLabel,
      competition: competition ?? this.competition,
      date: date ?? this.date,
      stadium: stadium ?? this.stadium,
      events: events ?? this.events,
      stats: stats ?? this.stats,
      homeLineup: homeLineup ?? this.homeLineup,
      awayLineup: awayLineup ?? this.awayLineup,
      standings: standings ?? this.standings,
      momentumHome: momentumHome ?? this.momentumHome,
      liveCommentary: liveCommentary ?? this.liveCommentary,
    );
  }
}
