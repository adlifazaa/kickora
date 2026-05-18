import 'package:shared_preferences/shared_preferences.dart';

import '../services/favorites_service.dart';
import 'models/firebase_notification_payload.dart';
import 'models/notification_type.dart';
import 'notification_channels.dart';

/// Whether an incoming payload should be shown for the current user prefs/favorites.
class NotificationRelevance {
  NotificationRelevance._();

  static Future<bool> shouldDeliver(FirebaseNotificationPayload payload) async {
    final prefs = await SharedPreferences.getInstance();
    final teams = _readIds(prefs, FavoritesService.teamsKey);
    final competitions = _readIds(prefs, FavoritesService.competitionsKey);
    final matches = _readIds(prefs, FavoritesService.matchesKey);

    final type = payload.type.canonical;
    switch (type) {
      case NotificationType.favoriteTeamUpdate:
        if (payload.teamId != null) {
          return teams.contains(payload.teamId);
        }
        return teams.isNotEmpty;
      case NotificationType.favoriteCompetitionUpdate:
        if (payload.competitionId != null) {
          return competitions.contains(payload.competitionId);
        }
        return competitions.isNotEmpty;
      case NotificationType.favoriteMatchUpdate:
        if (payload.matchId != null) {
          return matches.contains(payload.matchId);
        }
        return matches.isNotEmpty;
      case NotificationType.goalScored:
      case NotificationType.matchStarted:
      case NotificationType.redCard:
      case NotificationType.matchFinished:
        return _matchEventRelevant(payload, teams, matches);
      default:
        return true;
    }
  }

  static bool _matchEventRelevant(
    FirebaseNotificationPayload payload,
    Set<int> teams,
    Set<int> matches,
  ) {
    final topic = payload.topic;
    if (topic != null) {
      if (topic.startsWith('match_')) {
        final id = int.tryParse(topic.replaceFirst('match_', ''));
        if (id != null) return matches.contains(id);
      }
      if (topic.startsWith('team_')) {
        final id = int.tryParse(topic.replaceFirst('team_', ''));
        if (id != null) return teams.contains(id);
      }
      if (topic.startsWith('competition_')) {
        return true;
      }
    }
    if (payload.matchId != null && matches.contains(payload.matchId)) {
      return true;
    }
    if (payload.teamId != null && teams.contains(payload.teamId)) {
      return true;
    }
    return teams.isEmpty && matches.isEmpty;
  }

  static Set<int> _readIds(SharedPreferences prefs, String key) {
    return (prefs.getStringList(key) ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  static String? topicForPayload(FirebaseNotificationPayload payload) {
    if (payload.topic != null && payload.topic!.isNotEmpty) {
      return payload.topic;
    }
    if (payload.teamId != null) {
      return NotificationTopics.team(payload.teamId!);
    }
    if (payload.matchId != null) {
      return NotificationTopics.match(payload.matchId!);
    }
    if (payload.competitionId != null) {
      return NotificationTopics.competition(payload.competitionId!);
    }
    return null;
  }
}
