import 'firebase_notification_payload.dart';
import 'notification_type.dart';

/// Future-ready deep link target when the user taps a push notification.
class NotificationTapIntent {
  const NotificationTapIntent({
    required this.type,
    this.matchId,
    this.teamId,
    this.competitionId,
    this.topic,
  });

  final NotificationType type;
  final int? matchId;
  final int? teamId;
  final int? competitionId;
  final String? topic;

  bool get hasMatchTarget => matchId != null && matchId! > 0;

  bool get hasTeamTarget => teamId != null && teamId! > 0;

  bool get hasCompetitionTarget =>
      competitionId != null && competitionId! > 0;

  factory NotificationTapIntent.fromPayload(FirebaseNotificationPayload payload) {
    return NotificationTapIntent(
      type: payload.type.canonical,
      matchId: payload.matchId,
      teamId: payload.teamId,
      competitionId: payload.competitionId,
      topic: payload.topic,
    );
  }
}
