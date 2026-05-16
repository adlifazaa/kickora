import 'notification_type.dart';

/// In-app / local notification payload (provider-agnostic).
class KickoraNotification {
  const KickoraNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.matchId,
    this.teamId,
    this.competitionId,
    this.payload = const {},
    this.scheduledAt,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final int? matchId;
  final int? teamId;
  final int? competitionId;
  final Map<String, String> payload;
  final DateTime? scheduledAt;

  Map<String, String> toDataMap() => {
        'id': id,
        'type': type.wireValue,
        if (matchId != null) 'matchId': '$matchId',
        if (teamId != null) 'teamId': '$teamId',
        if (competitionId != null) 'competitionId': '$competitionId',
        ...payload,
      };
}
