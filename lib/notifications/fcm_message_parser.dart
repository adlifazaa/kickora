import 'package:firebase_messaging/firebase_messaging.dart';

import 'models/firebase_notification_payload.dart';
import 'notification_channels.dart';

/// Parses FCM [RemoteMessage] into [FirebaseNotificationPayload] (no secrets logged).
class FcmMessageParser {
  FcmMessageParser._();

  static FirebaseNotificationPayload parse(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    final notification = message.notification;
    if (notification?.title != null && !data.containsKey('title')) {
      data['title'] = notification!.title;
    }
    if (notification?.body != null && !data.containsKey('body')) {
      data['body'] = notification!.body;
    }
    final topic = resolveTopic(message);
    if (topic != null) {
      data['topic'] = topic;
    }
    return FirebaseNotificationPayload.fromData(data);
  }

  /// Resolves topic from data or FCM `from` (`/topics/team_7`).
  static String? resolveTopic(RemoteMessage message) {
    final explicit = message.data['topic']?.toString();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final from = message.from;
    if (from != null && from.contains('/topics/')) {
      final segment = from.split('/topics/').last;
      if (segment.isNotEmpty) return segment;
    }

    final matchId = _intOrNull(message.data['matchId'] ?? message.data['fixture_id']);
    final teamId = _intOrNull(message.data['teamId'] ?? message.data['team_id']);
    final competitionId =
        _intOrNull(message.data['competitionId'] ?? message.data['league_id']);
    if (teamId != null) return NotificationTopics.team(teamId);
    if (matchId != null) return NotificationTopics.match(matchId);
    if (competitionId != null) {
      return NotificationTopics.competition(competitionId);
    }
    return null;
  }

  static int? _intOrNull(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
