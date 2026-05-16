/// Match alert categories supported by Kickora (FCM data `type` field).
enum NotificationType {
  matchStarting,
  goal,
  halftime,
  fulltime,
  favoriteTeamReminder,
}

extension NotificationTypeX on NotificationType {
  String get wireValue {
    switch (this) {
      case NotificationType.matchStarting:
        return 'match_starting';
      case NotificationType.goal:
        return 'goal';
      case NotificationType.halftime:
        return 'halftime';
      case NotificationType.fulltime:
        return 'fulltime';
      case NotificationType.favoriteTeamReminder:
        return 'favorite_team_reminder';
    }
  }

  static NotificationType? fromWireValue(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'match_starting':
      case 'match_start':
        return NotificationType.matchStarting;
      case 'goal':
        return NotificationType.goal;
      case 'halftime':
      case 'ht':
        return NotificationType.halftime;
      case 'fulltime':
      case 'ft':
        return NotificationType.fulltime;
      case 'favorite_team_reminder':
      case 'favorite_team':
        return NotificationType.favoriteTeamReminder;
      default:
        return null;
    }
  }
}
